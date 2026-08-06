import Foundation

public enum PrivacyRiskLevel: String, Codable {
    case low = "Low Risk"
    case high = "High Risk"
}

public struct PrivacyScanResult {
    public let riskLevel: PrivacyRiskLevel
    public let detectedReasons: [String]
}

public final class AIPrivacyScanner {
    public static let shared = AIPrivacyScanner()
    
    // 50KB limit to prevent dumping massive local files directly to AI
    private let maxContextSize: Int = 50 * 1024
    
    private init() {}
    
    public func scan(text: String, isDocument: Bool = false, filename: String? = nil) -> PrivacyScanResult {
        var reasons: [String] = []
        var isHighRisk = false
        
        // 1. Context Size Limit
        if text.utf8.count > maxContextSize {
            isHighRisk = true
            reasons.append("Context exceeds maximum allowed size (50KB)")
        }
        
        // 2. Base64 Dumping Detection (basic heuristic)
        let base64Pattern = "(?i)(?:[A-Za-z0-9+/]{4}){100,}(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?"
        if text.range(of: base64Pattern, options: .regularExpression) != nil {
            isHighRisk = true
            reasons.append("Large Base64 encoding detected")
        }
        
        // 3. Document Name Detection
        if let name = filename?.lowercased() {
            let sensitiveFiles = [".env", "credentials.json", "config.yml", "secrets.json", "id_rsa", "id_ed25519"]
            if sensitiveFiles.contains(where: { name.contains($0) }) {
                isHighRisk = true
                reasons.append("Sensitive file type detected: \(name)")
            }
        }
        
        // 4. Credentials & Tokens
        let credentialPatterns: [String: String] = [
            "OpenAI Key": "sk-[A-Za-z0-9]{20,}",
            "Anthropic Key": "sk-ant-[A-Za-z0-9_-]{20,}",
            "AWS Key": "(?i)AKIA[0-9A-Z]{16}",
            "GitHub Token": "gh[puso]_[A-Za-z0-9_]{36}",
            "Stripe Key": "sk_(test|live)_[0-9a-zA-Z]{24}",
            "Slack Token": "xox[baprs]-[0-9]{12}-[0-9]{12}-[a-zA-Z0-9]{24}",
            "JWT Token": "eyJ[A-Za-z0-9_-]+\\.eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+",
            "Private Key Block": "-----BEGIN [A-Z ]+PRIVATE KEY-----"
        ]
        
        for (name, pattern) in credentialPatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                isHighRisk = true
                reasons.append("\(name) detected")
            }
        }
        
        // 5. Sensitive Data
        let sensitivePatterns: [String: String] = [
            "Credit Card": "\\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\\b",
            "SSN": "\\b\\d{3}-\\d{2}-\\d{4}\\b",
            "Email": "\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\b",
            "Phone Number": "\\b(?:\\+\\d{1,3}[- ]?)?\\(?\\d{3}\\)?[- ]?\\d{3}[- ]?\\d{4}\\b"
        ]
        
        for (name, pattern) in sensitivePatterns {
            if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                isHighRisk = true
                reasons.append("\(name) detected")
            }
        }
        
        return PrivacyScanResult(
            riskLevel: isHighRisk ? .high : .low,
            detectedReasons: reasons
        )
    }
}
