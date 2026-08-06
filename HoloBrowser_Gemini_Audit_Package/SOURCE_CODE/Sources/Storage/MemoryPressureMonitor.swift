import Foundation
import AppKit
import Combine

/// System memory pressure monitor reacting to system warnings by purging background WKWebView instances.
@MainActor
public final class MemoryPressureMonitor: ObservableObject {
    @Published public private(set) var isUnderPressure: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(tabManager: TabManager? = nil) {
        NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isUnderPressure = true
                tabManager?.suspendInactiveTabs(maxActiveBackground: 2)
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isUnderPressure = false
            }
            .store(in: &cancellables)
    }
}
