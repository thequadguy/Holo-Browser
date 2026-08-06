import Foundation

/// Fast, zero-dependency token count estimator.
public enum TokenCounter {
    
    /// Estimates token count of a given string (approx. 4 characters per token).
    public static func estimateTokenCount(for text: String) -> Int {
        let charCount = text.count
        guard charCount > 0 else { return 0 }
        return Int(ceil(Double(charCount) / 4.0))
    }
    
    /// Truncates text to fit within maximum token budget.
    public static func truncateToTokenBudget(_ text: String, maxTokens: Int = 8000) -> String {
        let maxChars = maxTokens * 4
        guard text.count > maxChars else { return text }
        let index = text.index(text.startIndex, offsetBy: maxChars)
        return String(text[..<index]) + "\n\n[Context truncated due to length...]"
    }
}
