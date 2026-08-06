import Foundation

/// Minimal URL resolver for Holo Browser.
public enum URLSanitizer {
    private static let searchBase = "https://www.google.com/search?q="
    
    /// Resolves raw user input string to a valid URL.
    /// - Parameter input: Raw user input from address bar.
    /// - Returns: A valid URL object.
    public static func sanitize(_ input: String) -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return URL(string: "about:blank")!
        }
        
        // 1. Check if input has explicit supported schemes (http, https, file, about)
        if let components = URLComponents(string: trimmed), let scheme = components.scheme?.lowercased() {
            if ["http", "https", "file", "about"].contains(scheme) {
                if let url = components.url {
                    return url
                }
            }
        }
        
        // 2. Check if input looks like a web domain (contains '.' and no spaces)
        if !trimmed.contains(" ") && trimmed.contains(".") {
            let prefixed = "https://" + trimmed
            if let components = URLComponents(string: prefixed), let url = components.url {
                return url
            }
        }
        
        // 3. Fallback: Search engine query
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return URL(string: searchBase + encoded) ?? URL(string: "https://www.google.com")!
    }
}
