import Foundation
import WebKit
import Combine

/// Main-actor manager managing installed extensions, execution states, and WebKit UserScript sync.
@MainActor
public final class ExtensionManager: ObservableObject {
    @Published public private(set) var extensions: [Extension] = []
    @Published public var pendingInstallExtension: Extension? = nil
    
    public let storage = ExtensionStorage()
    private let registry = ExtensionRegistry()
    
    public init() {
        self.extensions = registry.loadExtensions()
    }
    
    /// Requests installation approval for a new extension.
    public func requestInstall(_ ext: Extension) {
        pendingInstallExtension = ext
    }
    
    /// Confirms installation of a pending extension.
    public func confirmInstall() {
        guard let ext = pendingInstallExtension else { return }
        extensions.append(ext)
        registry.saveExtensions(extensions)
        pendingInstallExtension = nil
    }
    
    /// Cancels installation.
    public func cancelInstall() {
        pendingInstallExtension = nil
    }
    
    /// Toggles an extension enabled/disabled.
    public func toggleExtension(id: UUID) {
        guard let idx = extensions.firstIndex(where: { $0.id == id }) else { return }
        extensions[idx].enabled.toggle()
        registry.saveExtensions(extensions)
    }
    
    /// Removes an installed extension and clears its isolated storage.
    public func removeExtension(id: UUID) {
        guard let idx = extensions.firstIndex(where: { $0.id == id }) else { return }
        let target = extensions[idx]
        extensions.remove(at: idx)
        registry.saveExtensions(extensions)
        storage.removeStorage(for: target.id)
    }
    
    /// Generates active WKUserScript array for enabled script extensions.
    public func activeUserScripts() -> [WKUserScript] {
        return extensions.compactMap { ext in
            guard ext.enabled, ext.permissions.contains(.scriptInjection), let source = ext.userScriptSource else {
                return nil
            }
            return WKUserScript(
                source: source,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        }
    }
}
