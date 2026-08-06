import Foundation

/// Robust JSON decoding utility with automatic corrupted file backup and safe default fallback.
public enum SafeJSONDecoder {
    
    public static func decodeWithFallbackSync<T: Decodable>(_ type: T.Type, from fileURL: URL, fallback: T) -> T {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return fallback }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Corrupted JSON detected at \(fileURL.lastPathComponent): \(error.localizedDescription)")
            backupCorrupted(fileURL: fileURL)
            return fallback
        }
    }
    
    public static func decodeWithFallbackAsync<T: Decodable>(_ type: T.Type, from fileURL: URL, fallback: T) async -> T {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return fallback }
        
        do {
            let data = try await DiskStorageActor.shared.readRaw(from: fileURL)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Corrupted JSON detected at \(fileURL.lastPathComponent): \(error.localizedDescription)")
            backupCorrupted(fileURL: fileURL)
            return fallback
        }
    }
    
    private static func backupCorrupted(fileURL: URL) {
        let corruptedURL = fileURL.deletingPathExtension().appendingPathExtension("corrupted_\(Int(Date().timeIntervalSince1970)).json")
        do {
            try FileManager.default.moveItem(at: fileURL, to: corruptedURL)
            print("Successfully backed up corrupted JSON to \(corruptedURL.lastPathComponent)")
        } catch let backupError {
            print("FATAL: Failed to backup corrupted JSON file: \(backupError.localizedDescription)")
        }
    }
}
