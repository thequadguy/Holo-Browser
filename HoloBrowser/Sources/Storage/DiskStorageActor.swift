import Foundation

/// Thread-safe serial actor providing a single async persistence layer for Holo Browser data stores.
/// Enforces FIFO write ordering, atomic file operations, safe reads, and JSON corruption detection.
public actor DiskStorageActor {
    public static let shared = DiskStorageActor()
    
    private init() {}
    
    /// Encodes encodable value and writes data atomically to target URL with retry logic.
    public func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try writeRaw(data, to: url)
    }
    
    /// Writes raw data atomically with a 3-attempt retry mechanism and backup rotation.
    public func writeRaw(_ data: Data, to url: URL) throws {
        var attempts = 0
        var lastError: Error?
        
        let backupURL = url.appendingPathExtension("backup")
        let tmpURL = url.appendingPathExtension("tmp")
        
        while attempts < 3 {
            do {
                // 1. Write to temporary file
                try data.write(to: tmpURL, options: .atomic)
                
                // 2. Rotate current file to backup (if it exists)
                if FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: backupURL)
                    try FileManager.default.copyItem(at: url, to: backupURL)
                }
                
                // 3. Atomically replace original with tmp
                let _ = try FileManager.default.replaceItemAt(url, withItemAt: tmpURL)
                
                return
            } catch {
                lastError = error
                attempts += 1
                if attempts < 3 {
                    Thread.sleep(forTimeInterval: 0.1) // 100ms delay before retry
                }
            }
        }
        // Telemetry on filewrite failure could be dispatched here without raw console printing
        throw lastError ?? CocoaError(.fileWriteUnknown)
    }
    
    /// Safely reads and decodes JSON from URL with corruption detection.
    public func read<T: Decodable>(from url: URL, type: T.Type) throws -> T {
        let data = try readRaw(from: url)
        return try JSONDecoder().decode(type, from: data)
    }
    
    public func readRaw(from url: URL) throws -> Data {
        let backupURL = url.appendingPathExtension("backup")
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                return try Data(contentsOf: url)
            }
        } catch {
            // Main file corrupted or unreadable.
        }
        
        // Attempt backup recovery
        if FileManager.default.fileExists(atPath: backupURL.path) {
            return try Data(contentsOf: backupURL)
        }
        
        throw CocoaError(.fileReadNoSuchFile)
    }
    
    /// Deletes a file at the given URL, serialized through the actor to prevent race conditions.
    public func delete(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
