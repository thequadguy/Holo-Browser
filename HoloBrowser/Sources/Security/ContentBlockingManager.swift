import Foundation
import WebKit

/// Phase 10: ContentBlockingManager
/// Uses WKContentRuleListStore to compile and apply JSON ad/tracker blocking rules.
@MainActor
public final class ContentBlockingManager: ObservableObject {
    public static let shared = ContentBlockingManager()
    
    @Published public private(set) var isEnabled: Bool = true
    
    private init() {}
    
    /// Applies content blocking rules to the given WKWebViewConfiguration.
    public func applyRules(to configuration: WKWebViewConfiguration) {
        guard isEnabled else { return }
        
        let jsonString = """
        [{
            "trigger": { "url-filter": ".*analytics.*" },
            "action": { "type": "block" }
        },
        {
            "trigger": { "url-filter": ".*tracker.*" },
            "action": { "type": "block" }
        }]
        """
        
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "HoloContentBlocker",
            encodedContentRuleList: jsonString
        ) { ruleList, error in
            if error != nil {
                // Silently drop log in production
                return
            }
            if let ruleList = ruleList {
                configuration.userContentController.add(ruleList)
            }
        }
    }
}
