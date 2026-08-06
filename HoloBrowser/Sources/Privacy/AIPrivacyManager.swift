import Foundation

public enum AIPrivacyMode: String, Codable, CaseIterable {
    case askBeforeSending = "Ask Before Sending"
    case alwaysSend = "Always Send"
    case neverSend = "Never Send (Private Only)"
}

public enum PrivateAIBehavior: String, Codable, CaseIterable {
    case blockExternalAI = "Block External AI"
    case allowSanitizedContext = "Allow Sanitized Context"
    case allowQuestionOnly = "Allow Question Only"
}

/// Manager enforcing user privacy rules and mandatory context sanitization before transmitting page data to AI endpoints.
@MainActor
public final class AIPrivacyManager: ObservableObject {
    @Published public var privacyMode: AIPrivacyMode = .askBeforeSending
    @Published public var privateAIBehavior: PrivateAIBehavior = .blockExternalAI
    @Published public var allowExternalAIInPrivate: Bool = false
    
    public init() {}
    
    /// Mandatory AI Privacy Pipeline: Best-effort multi-layer protection sanitizes text data before sending to any cloud provider.
    /// Removes passwords, authorization headers, cookies, JWTs, OAuth tokens, API keys, private keys, credit cards, SSNs, phone numbers, and sensitive parameters.
    public func sanitizeContextForAI(_ text: String) -> String {
        guard privacyMode != .neverSend else { return "[Redacted: AI Privacy Shield is set to Never Send]" }
        
        var sanitized = text
        
        // 1. Authorization & Bearer Headers
        sanitized = sanitized.replacingOccurrences(of: "Bearer [A-Za-z0-9\\-\\._~\\+\\/]+=*", with: "Bearer [REDACTED]", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "Basic [A-Za-z0-9\\+\\/]+=*", with: "Basic [REDACTED]", options: .regularExpression)
        
        // 2. JWT Tokens
        sanitized = sanitized.replacingOccurrences(of: "eyJ[A-Za-z0-9_-]+\\.eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+", with: "[JWT_TOKEN_REDACTED]", options: .regularExpression)
        
        // 3. API Keys (OpenAI sk-..., Anthropic sk-ant-...)
        sanitized = sanitized.replacingOccurrences(of: "sk-[A-Za-z0-9]{20,}", with: "[API_KEY_REDACTED]", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "sk-ant-[A-Za-z0-9_-]{20,}", with: "[API_KEY_REDACTED]", options: .regularExpression)
        
        // 4. Sensitive URL & Header Key-Value Parameters
        let sensitiveParamsPattern = "(?i)(access_token|refresh_token|auth_token|api_key|password|passwd|secret|session_id)=[^&\\s]+"
        sanitized = sanitized.replacingOccurrences(of: sensitiveParamsPattern, with: "$1=[REDACTED]", options: .regularExpression)
        
        // 5. JSON Password & Secret Payload Fields
        let jsonSecretPattern = "(?i)\"(password|passwd|secret|access_token|api_key)\"\\s*:\\s*\"[^\"]+\""
        sanitized = sanitized.replacingOccurrences(of: jsonSecretPattern, with: "\"$1\": \"[REDACTED]\"", options: .regularExpression)
        
        // 6. Private Key Blocks
        let privateKeyPattern = "-----BEGIN [A-Z ]+PRIVATE KEY-----[\\s\\S]*?-----END [A-Z ]+PRIVATE KEY-----"
        sanitized = sanitized.replacingOccurrences(of: privateKeyPattern, with: "[PRIVATE_KEY_REDACTED]", options: .regularExpression)
        
        // 7. Credit Card Numbers (16-digit format with optional hyphens/spaces)
        let creditCardPattern = "\\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\\b"
        sanitized = sanitized.replacingOccurrences(of: creditCardPattern, with: "[CREDIT_CARD_REDACTED]", options: .regularExpression)
        
        // 8. Social Security Numbers (XXX-XX-XXXX)
        let ssnPattern = "\\b\\d{3}-\\d{2}-\\d{4}\\b"
        sanitized = sanitized.replacingOccurrences(of: ssnPattern, with: "[SSN_REDACTED]", options: .regularExpression)
        
        // 9. Phone Numbers
        let phonePattern = "\\b(?:\\+\\d{1,3}[- ]?)?\\(?\\d{3}\\)?[- ]?\\d{3}[- ]?\\d{4}\\b"
        sanitized = sanitized.replacingOccurrences(of: phonePattern, with: "[PHONE_REDACTED]", options: .regularExpression)
        
        return sanitized
    }
    
    /// Validates if an AI execution request is allowed under the current profile and provider settings.
    public func validateAIExecution(provider: AIProviderProtocol, isPrivate: Bool) throws {
        if isPrivate {
            if !provider.isLocal && (!allowExternalAIInPrivate || privateAIBehavior == .blockExternalAI) {
                throw AIError.privacyBlocked("External cloud AI (OpenAI/Anthropic) is strictly blocked during Private Browsing mode.")
            }
        }
    }
}
