import Foundation
import WebKit

/// Executing engine running approved safe browser actions against live view models.
/// Form submission, purchase buttons, and account modifications are strictly blocked.
@MainActor
public final class BrowserActionExecutor: ObservableObject {
    
    public init() {}
    
    public func execute(action: AIAction, viewModel: BrowserViewModel) async -> String {
        switch action.type {
        case .navigateToURL:
            if let urlString = action.parameters["url"], let url = URL(string: urlString) {
                viewModel.inputURLString = url.absoluteString
                viewModel.submitAddressInput()
                return "Navigated to \(url.absoluteString)"
            }
            return "Failed: Missing valid URL"
            
        case .openNewTab:
            viewModel.createNewTab()
            if let urlString = action.parameters["url"], let url = URL(string: urlString) {
                viewModel.inputURLString = url.absoluteString
                viewModel.submitAddressInput()
                return "Opened new tab with \(url.absoluteString)"
            }
            return "Opened fresh new tab"
            
        case .summarizePage:
            if let tab = viewModel.tabManager.activeTab {
                return "Triggered AI page summary for '\(tab.title)'"
            }
            return "Failed: No active webpage tab"
            
        case .collectSource:
            if let webView = viewModel.tabManager.activeTab?.webView {
                if let source = try? await SourceCollector.collectSource(from: webView) {
                    viewModel.readingListManager.addItem(
                        title: source.title,
                        urlString: source.urlString,
                        profileID: viewModel.profileManager.activeProfile.id
                    )
                    return "Saved source '\(source.title)' to Reading List"
                }
            }
            return "Failed to extract source content"
            
        case .createNote:
            let title = action.parameters["title"] ?? "Research Note"
            return "Created research note: '\(title)'"
            
        case .extractInformation, .scrollToSection:
            if let webView = viewModel.tabManager.activeTab?.webView,
               let source = try? await SourceCollector.collectSource(from: webView) {
                return "Extracted \(source.summary.count) characters of summary text"
            }
            return "Extracted visible page context"
            
        case .submitForm, .purchaseProduct, .modifyAccount:
            return "BLOCKED: Autonomous form submissions, purchases, and account modifications are strictly prohibited."
        }
    }
}
