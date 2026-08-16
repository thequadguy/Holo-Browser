import Foundation

/// Single authoritative source of truth for high-risk domain blocking.
///
/// Both ScreenshotManager and AIContextGatekeeper delegate to this checker.
/// Having one implementation prevents the two lists from diverging silently.
///
/// Domain matching rules:
/// - Exact match:       host == "chase.com"              → blocked
/// - Subdomain match:   host == "accounts.chase.com"     → blocked
/// - First-component:   "bank.example.com"               → blocked  (first label is "bank")
/// - Keyword substrings in the middle of a label are NOT matched
///   (avoids false positives like "foodbank.org" or "myloginpage.app")
public enum HighRiskDomainChecker {

    // MARK: - Known High-Risk Registrable Domains

    /// Exact registrable-domain allowlist. Matching is performed on the registrable
    /// domain only (host itself OR `host` that ends with ".<domain>`").
    /// Subdomains of these roots are also blocked.
    private static let highRiskRoots: Set<String> = [
        // Banking
        "chase.com",
        "bankofamerica.com",
        "wellsfargo.com",
        "citibank.com",
        "capitalone.com",
        "usbank.com",
        "tdbank.com",
        "pnc.com",
        // Payments
        "paypal.com",
        "stripe.com",
        "square.com",
        "venmo.com",
        "cashapp.com",
        // Investment / Brokerage
        "schwab.com",
        "fidelity.com",
        "vanguard.com",
        "robinhood.com",
        "etrade.com",
        "merrilledge.com"
    ]

    /// First-label keyword matching. Blocks `bank.example.com`, `login.example.com`, etc.
    /// Deliberately conservative — only the leftmost hostname label is checked so
    /// "foodbank.org" is NOT blocked, but "bank.myservice.com" IS blocked.
    private static let highRiskFirstLabels: Set<String> = [
        "bank", "banking", "secure", "login", "signin", "auth",
        "account", "accounts", "gov", "medical", "health", "identity",
        "payment", "pay", "checkout"
    ]

    // MARK: - Public API

    /// Returns true if the given hostname is high-risk and AI screenshot/context actions
    /// should be blocked.
    ///
    /// - Parameter host: The lowercased hostname (e.g. `"accounts.chase.com"`).
    public static func isHighRisk(_ host: String) -> Bool {
        let normalised = host.lowercased()

        // 1. Exact or subdomain match against known high-risk roots.
        if highRiskRoots.contains(where: { normalised == $0 || normalised.hasSuffix(".\($0)") }) {
            return true
        }

        // 2. First-label keyword match.
        // Split "accounts.chase.com" → ["accounts", "chase", "com"]; check "accounts".
        if let firstLabel = normalised.split(separator: ".").first {
            return highRiskFirstLabels.contains(String(firstLabel))
        }

        return false
    }
}
