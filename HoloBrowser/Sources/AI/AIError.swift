import Foundation

/// Typed errors for Holo Browser AI pipeline.
public enum AIError: LocalizedError, Equatable {
    case missingAPIKey(String)
    case invalidResponse(String)
    case networkError(String)
    case privacyBlocked(String)
    case privacyConfirmationRequired(String)
    case tokenLimitExceeded(Int)
    case providerUnavailable(String)
    case httpError(Int)
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "API key for \(provider) is missing. Please configure your key in Preferences."
        case .invalidResponse(let message):
            return "Invalid AI response: \(message)"
        case .networkError(let message):
            return "AI Network Error: \(message)"
        case .privacyBlocked(let reason):
            return "AI Privacy Shield: \(reason)"
        case .privacyConfirmationRequired(let reason):
            return "Confirmation Required: \(reason)"
        case .tokenLimitExceeded(let maxTokens):
            return "Page text exceeds maximum context window of \(maxTokens) tokens."
        case .providerUnavailable(let provider):
            return "The AI provider '\(provider)' is currently unavailable."
        case .httpError(let code):
            return "AI provider returned HTTP error \(code). Check your API key and network connection."
        }
    }
}
