import Foundation
import Combine

public enum InternalRoute: Equatable {
    case startPage
    case settings
    case history
    case downloads
    case external(URL)
}

/// Internal URL router intercepting holo:// schemes before WKWebView navigation.
@MainActor
public final class InternalURLRouter: ObservableObject {
    public static let shared = InternalURLRouter()
    
    private init() {}
    
    /// Resolves whether a URL represents an internal holo:// route or external web page.
    public static func route(for url: URL) -> InternalRoute {
        guard url.scheme?.lowercased() == "holo" else {
            return .external(url)
        }
        
        let host = url.host?.lowercased() ?? ""
        switch host {
        case "start", "newtab", "home":
            return .startPage
        case "settings", "preferences":
            return .settings
        case "history":
            return .history
        case "downloads":
            return .downloads
        default:
            return .startPage
        }
    }
    
    /// Determines if a URL string is an internal holo:// scheme.
    public static func isInternalURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme?.lowercased() == "holo"
    }
}
