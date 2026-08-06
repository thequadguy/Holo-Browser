import Foundation
import Combine

/// Mandatory Security Gateway for all AI requests in Holo Browser.
/// Guarantees NO raw webpage content reaches OpenAI, Anthropic, or external providers without passing through sanitization and policy validation.
@MainActor
public final class AIContextGatekeeper: ObservableObject {
    public static let shared = AIContextGatekeeper()
    
    private let privacyManager = AIPrivacyManager()
    
    private init() {}
    
    /// Mandatory gatekeeper evaluation before dispatching any prompt or context to an AI provider.
    public func processAndValidateRequest(
        prompt: String,
        context: String,
        provider: AIProviderProtocol,
        isPrivateBrowsing: Bool,
        domainHost: String? = nil
    ) throws -> (sanitizedPrompt: String, sanitizedContext: String) {
        
        // 1. Private Mode Validation
        try privacyManager.validateAIExecution(provider: provider, isPrivate: isPrivateBrowsing)
        
        // 2. High-Risk Domain Validation
        if let host = domainHost?.lowercased() {
            if isHighRiskSensitiveDomain(host) {
                throw AIError.privacyBlocked("AI actions blocked on sensitive domains.")
            }
        }
        
        // 3. Mandatory Regex Context Sanitization
        let sanitizedPrompt = privacyManager.sanitizeContextForAI(prompt)
        let sanitizedContext = privacyManager.sanitizeContextForAI(context)
        
        // 4. Log Telemetry Metrics
        PrivacyDashboardManager.shared.recordAISanitization()
        
        return (sanitizedPrompt, sanitizedContext)
    }
    
    private func isHighRiskSensitiveDomain(_ host: String) -> Bool {
        let sensitiveDomains = ["bank", "chase.com", "bankofamerica.com", "wellsfargo.com", "paypal.com", "stripe.com"]
        return sensitiveDomains.contains { host.contains($0) }
    }
}
