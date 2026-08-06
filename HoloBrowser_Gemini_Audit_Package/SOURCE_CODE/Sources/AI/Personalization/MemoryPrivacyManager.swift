import Foundation

/// Privacy gate preventing passwords, authentication tokens, and private profile data from being written to personal AI memory.
public enum MemoryPrivacyManager {
    
    public static func isSafeToStore(content: String, isPrivate: Bool) -> Bool {
        guard !isPrivate else { return false }
        
        let sensitivePattern = "(?i)(password|secret|bearer|auth_token|creditcard|cvv|ssn)[:=]\\s*[^\\s]+"
        let regex = try? NSRegularExpression(pattern: sensitivePattern)
        let range = NSRange(location: 0, length: content.utf16.count)
        
        return regex?.firstMatch(in: content, options: [], range: range) == nil
    }
}
