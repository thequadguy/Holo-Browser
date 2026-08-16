import Foundation
import WebKit

/// Phase 10: ContentBlockingManager
/// Uses WKContentRuleListStore to compile, cache, and apply JSON ad/tracker blocking rules.
@MainActor
public final class ContentBlockingManager: ObservableObject {
    public static let shared = ContentBlockingManager()

    @Published public private(set) var isEnabled: Bool = true
    @Published public private(set) var isRulesCompiled: Bool = false

    private var cachedRuleList: WKContentRuleList?
    private var compilationTask: Task<WKContentRuleList?, Never>?

    private static let ruleIdentifier = "HoloContentBlocker"

    public static let defaultRulesJSON = """
    [
        {
            "trigger": { "url-filter": ".*analytics.*" },
            "action": { "type": "block" }
        },
        {
            "trigger": { "url-filter": ".*tracker.*" },
            "action": { "type": "block" }
        },
        {
            "trigger": { "url-filter": ".*telemetry.*" },
            "action": { "type": "block" }
        },
        {
            "trigger": { "url-filter": ".*doubleclick\\.net/.*" },
            "action": { "type": "block" }
        },
        {
            "trigger": { "url-filter": ".*googletagservices\\.com/.*" },
            "action": { "type": "block" }
        }
    ]
    """

    private init() {
        // Asynchronously pre-compile rules on initialization
        preloadRules()
    }

    /// Pre-compiles the rule list and stores the compiled instance in memory.
    public func preloadRules() {
        guard cachedRuleList == nil, compilationTask == nil else { return }

        compilationTask = Task { @MainActor [weak self] in
            guard let self = self else { return nil }
            let list = await self.compileRules(json: Self.defaultRulesJSON)
            self.cachedRuleList = list
            self.isRulesCompiled = list != nil
            self.compilationTask = nil
            return list
        }
    }

    /// Applies cached content blocking rules to the given WKWebViewConfiguration.
    /// If rules are already compiled, they are attached immediately.
    public func applyRules(to configuration: WKWebViewConfiguration) {
        guard isEnabled else { return }

        if let ruleList = cachedRuleList {
            configuration.userContentController.add(ruleList)
            return
        }

        // If compilation is in progress, attach when ready
        Task { @MainActor [weak self] in
            guard let self = self, self.isEnabled else { return }
            if let ruleList = self.cachedRuleList {
                configuration.userContentController.add(ruleList)
            } else if let task = self.compilationTask, let ruleList = await task.value {
                configuration.userContentController.add(ruleList)
            }
        }
    }

    /// Toggles content blocking on or off.
    public func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
    }

    private func compileRules(json: String) async -> WKContentRuleList? {
        await withCheckedContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: Self.ruleIdentifier,
                encodedContentRuleList: json
            ) { ruleList, error in
                if error != nil {
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: ruleList)
                }
            }
        }
    }
}
