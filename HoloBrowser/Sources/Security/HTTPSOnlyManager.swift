import Foundation
import WebKit

/// Phase 10: HTTPSOnlyManager
/// Ensures that insecure HTTP navigations are seamlessly upgraded to HTTPS.
@MainActor
public final class HTTPSOnlyManager {
    public static let shared = HTTPSOnlyManager()
    
    public var isEnabled: Bool = true
    
    private init() {}
    
    /// Upgrades HTTP URLs to HTTPS if enabled.
    public func upgradeURLIfNeeded(_ url: URL) -> URL {
        guard isEnabled, url.scheme == "http" else { return url }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.scheme = "https"
        return components?.url ?? url
    }
}
