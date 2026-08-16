import Foundation
import CryptoKit
import Security

/// Validates software update packages for structural integrity, SHA-256 checksums,
/// semantic version progression, and optional Apple code signatures.
public enum UpdateValidator {

    public enum ValidationError: Error, LocalizedError, Equatable {
        case fileNotFound
        case unsupportedFormat(String)
        case checksumMismatch(expected: String, actual: String)
        case invalidVersionString(String)
        case downgradeAttempt(current: String, target: String)
        case invalidCodeSignature(String)
        case malformedPackage(String)

        public var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "The update package file does not exist."
            case .unsupportedFormat(let ext):
                return "The update package format '.\(ext)' is unsupported."
            case .checksumMismatch(let expected, let actual):
                return "Checksum mismatch. Expected SHA-256: \(expected), got: \(actual)."
            case .invalidVersionString(let ver):
                return "The version string '\(ver)' is not a valid semantic version."
            case .downgradeAttempt(let current, let target):
                return "Downgrade rejected. Current version '\(current)' is newer than target '\(target)'."
            case .invalidCodeSignature(let reason):
                return "Code signature validation failed: \(reason)."
            case .malformedPackage(let reason):
                return "Malformed package: \(reason)."
            }
        }
    }

    public static let supportedExtensions: Set<String> = ["dmg", "app", "zip", "pkg"]

    /// Validates file existence and supported extension.
    public static func validatePackageFormat(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.fileNotFound
        }
        let ext = url.pathExtension.lowercased()
        guard supportedExtensions.contains(ext) else {
            throw ValidationError.unsupportedFormat(ext)
        }
    }

    /// Computes the SHA-256 checksum of a file at the given URL.
    public static func computeSHA256(for url: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.fileNotFound
        }
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { try? fileHandle.close() }

        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = fileHandle.readData(ofLength: 64 * 1024)
            guard !chunk.isEmpty else { return false }
            hasher.update(data: chunk)
            return true
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Validates that the package's SHA-256 checksum matches the expected checksum.
    public static func validateChecksum(for url: URL, expectedSHA256: String) throws {
        let actual = try computeSHA256(for: url)
        let normalizedExpected = expectedSHA256.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard actual.lowercased() == normalizedExpected else {
            throw ValidationError.checksumMismatch(expected: normalizedExpected, actual: actual)
        }
    }

    /// Parses a semantic version string (e.g. "1.2.3", "v2.0.0-beta.1") into comparable numeric components.
    public static func parseSemanticVersion(_ version: String) -> [Int]? {
        var clean = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.lowercased().hasPrefix("v") {
            clean.removeFirst()
        }
        // Strip build metadata or prerelease tags for numeric version comparison
        if let prereleaseIndex = clean.firstIndex(of: "-") {
            clean = String(clean[..<prereleaseIndex])
        }
        if let buildIndex = clean.firstIndex(of: "+") {
            clean = String(clean[..<buildIndex])
        }

        let parts = clean.split(separator: ".")
        guard !parts.isEmpty else { return nil }
        var ints: [Int] = []
        for part in parts {
            guard let val = Int(part), val >= 0 else { return nil }
            ints.append(val)
        }
        return ints
    }

    /// Compares two semantic version strings.
    /// Returns .orderedAscending if v1 < v2, .orderedSame if v1 == v2, .orderedDescending if v1 > v2.
    public static func compareVersions(_ v1: String, _ v2: String) throws -> ComparisonResult {
        guard let p1 = parseSemanticVersion(v1) else {
            throw ValidationError.invalidVersionString(v1)
        }
        guard let p2 = parseSemanticVersion(v2) else {
            throw ValidationError.invalidVersionString(v2)
        }

        let maxLen = max(p1.count, p2.count)
        for idx in 0..<maxLen {
            let val1 = idx < p1.count ? p1[idx] : 0
            let val2 = idx < p2.count ? p2[idx] : 0
            if val1 < val2 {
                return .orderedAscending
            } else if val1 > val2 {
                return .orderedDescending
            }
        }
        return .orderedSame
    }

    /// Validates that targetVersion is strictly newer than (or equal if allowSameVersion is true) currentVersion.
    public static func validateVersionProgression(
        currentVersion: String,
        targetVersion: String,
        allowSameVersion: Bool = false
    ) throws {
        let comparison = try compareVersions(currentVersion, targetVersion)
        if comparison == .orderedDescending {
            throw ValidationError.downgradeAttempt(current: currentVersion, target: targetVersion)
        }
        if comparison == .orderedSame && !allowSameVersion {
            throw ValidationError.downgradeAttempt(current: currentVersion, target: targetVersion)
        }
    }

    /// Validates an Apple code signature on an executable / .app bundle.
    /// Uses real Security.framework SecStaticCode APIs.
    public static func validateAppleCodeSignature(at url: URL) throws -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ValidationError.fileNotFound
        }

        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else {
            throw ValidationError.invalidCodeSignature("Failed to create static code object (OSStatus \(status)).")
        }

        let checkStatus = SecStaticCodeCheckValidity(code, SecCSFlags(), nil)
        guard checkStatus == errSecSuccess else {
            throw ValidationError.invalidCodeSignature("Code signature check failed (OSStatus \(checkStatus)).")
        }

        return true
    }

    /// Combined pipeline validation method.
    public static func validateUpdatePackage(
        at url: URL,
        targetVersion: String,
        currentVersion: String? = nil,
        expectedSHA256: String? = nil,
        requireCodeSignature: Bool = false
    ) -> Bool {
        do {
            try validatePackageFormat(at: url)
            if let expectedSHA = expectedSHA256 {
                try validateChecksum(for: url, expectedSHA256: expectedSHA)
            }
            if let currentVer = currentVersion {
                try validateVersionProgression(currentVersion: currentVer, targetVersion: targetVersion)
            } else {
                guard parseSemanticVersion(targetVersion) != nil else { return false }
            }
            if requireCodeSignature {
                _ = try validateAppleCodeSignature(at: url)
            }
            return true
        } catch {
            return false
        }
    }
}
