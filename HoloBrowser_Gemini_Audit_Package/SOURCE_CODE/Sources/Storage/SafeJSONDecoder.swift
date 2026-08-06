import Foundation

/// Robust JSON decoding utility with automatic corrupted file backup and safe default fallback.
public enum SafeJSONDecoder {
    
    public static func decodeWithFallback<T: Decodable>(_ type: T.Type, from fileURL: URL, fallback: T) -> T {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return fallback }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Corrupted JSON detected at \(fileURL.lastPathComponent): \(error.localizedDescription)")
            
            // Backup corrupted file for inspection
            let corruptedURL = fileURL.deletingPathExtension().appendingPathExtension("corrupted_\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: fileURL, to: corruptedURL)
            
            return fallback
        }
    }
}
