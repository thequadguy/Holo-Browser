import WebKit
import AppKit

/// Native WKWebView subclass configured for Holo Browser performance, security, and WebInspector.
public final class HoloWebView: WKWebView {
    
    public static let loginDetectionJS = """
    document.addEventListener('submit', function(e) {
        var form = e.target;
        var passInput = form.querySelector('input[type="password"]');
        var userInput = form.querySelector('input[type="text"], input[type="email"]');
        if (passInput && passInput.value) {
            var username = userInput ? userInput.value : '';
            var password = passInput.value;
            window.webkit.messageHandlers.holoPasswordDetector.postMessage({
                domain: window.location.hostname,
                username: username,
                password: password
            });
        }
    }, true);
    """
    
    public static var loginDetectionScript: WKUserScript {
        return WKUserScript(
            source: loginDetectionJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }
    
    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // Inject login form detection script safely
        configuration.userContentController.addUserScript(HoloWebView.loginDetectionScript)
        
        super.init(frame: frame, configuration: configuration)
        
        self.allowsBackForwardNavigationGestures = true
        self.allowsMagnification = true
        self.autoresizingMask = [.width, .height]
        
        if #available(macOS 13.3, *) {
            self.isInspectable = true
        }
    }
    
    public override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        
        menu.addItem(NSMenuItem.separator())
        
        let summarizeItem = NSMenuItem(title: "H: Summarize Selection", action: #selector(holoSummarizeSelection), keyEquivalent: "")
        summarizeItem.target = self
        menu.addItem(summarizeItem)
        
        let saveMemoryItem = NSMenuItem(title: "H: Save to Memory", action: #selector(holoSaveToMemory), keyEquivalent: "")
        saveMemoryItem.target = self
        menu.addItem(saveMemoryItem)
    }
    
    @objc private func holoSummarizeSelection() {
        HoloEventBus.shared.post(.quickActionSummarize)
    }
    
    @objc private func holoSaveToMemory() {
        HoloEventBus.shared.post(.quickActionSaveMemory)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
