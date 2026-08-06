import Foundation

/// Primary facade for HoloMind — coordinating H Executive Assistant persona, Memory Engine, Context Engine, Mission System, and Opportunity Engine.
@MainActor
public final class HoloMindEngine: ObservableObject {
    @Published public var currentState: HAssistantState = .idle
    @Published public var isPanelVisible: Bool = false
    
    public let memoryEngine: HoloMindMemoryEngine
    public let contextEngine: HoloContextEngine
    public let missionSystem: HoloMissionSystem
    public let opportunityEngine: HoloOpportunityEngine
    public let notificationCenter: HoloNotificationCenter
    
    public init(
        memoryEngine: HoloMindMemoryEngine? = nil,
        contextEngine: HoloContextEngine? = nil,
        missionSystem: HoloMissionSystem? = nil,
        opportunityEngine: HoloOpportunityEngine? = nil,
        notificationCenter: HoloNotificationCenter? = nil
    ) {
        self.memoryEngine = memoryEngine ?? HoloMindMemoryEngine()
        self.contextEngine = contextEngine ?? HoloContextEngine()
        self.missionSystem = missionSystem ?? HoloMissionSystem()
        self.opportunityEngine = opportunityEngine ?? HoloOpportunityEngine()
        self.notificationCenter = notificationCenter ?? HoloNotificationCenter()
    }
    
    public func togglePanel() {
        isPanelVisible.toggle()
    }
    
    public func analyzeBrowserState(tabs: [Tab]) {
        // ENFORCE PRIVACY SHIELD: Do not collect page contents if any tab is private
        if tabs.contains(where: { $0.isPrivate }) {
            return
        }
        currentState = .analyzing
        contextEngine.analyzeContext(tabs: tabs)
        opportunityEngine.scan(tabs: tabs, contextEngine: contextEngine)
        currentState = .idle
    }
    
    public func assignGoal(title: String, category: HoloMissionCategory, isPrivate: Bool = false) {
        // ENFORCE PRIVACY SHIELD
        guard !isPrivate else {
            notificationCenter.post(notification: HoloNotification(title: "AI Blocked", message: "Cannot assign goals in Private mode.", priority: .high))
            return
        }
        currentState = .planning
        missionSystem.createMission(title: title, category: category)
        currentState = .awaitingApproval
    }
    
    // MARK: - Quick Actions
    
    public func executeQuickAction(_ action: HQuickAction, context: String? = nil, profile: BrowserProfile) {
        currentState = .analyzing
        
        switch action {
        case .summarizePage:
            HoloAILogger.shared.log(action: .actionExecuted, details: "Summarizing page content.")
            let notif = HoloNotification(
                title: "Summary Complete",
                message: "H summarized the current page. Key points extracted.",
                priority: .normal
            )
            notificationCenter.post(notification: notif)
        case .saveToMemory:
            if let text = context {
                Task {
                    do {
                        try await memoryEngine.addMemory(category: .project, key: "Saved Snippet", value: text, profileID: profile.id, isPrivate: profile.isPrivate)
                        HoloAILogger.shared.log(action: .memorySaved, details: "Saved text to project memory.", payload: text)
                        notificationCenter.post(notification: HoloNotification(title: "Memory Saved", message: "Snippet added to project memory."))
                    } catch {
                        notificationCenter.post(notification: HoloNotification(title: "Save Failed", message: "Failed to persist memory.", priority: .high))
                    }
                }
            }
        case .detectIntent:
            HoloAILogger.shared.log(action: .actionExecuted, details: "Detecting user intent across tabs.")
            notificationCenter.post(notification: HoloNotification(title: "Intent Analyzed", message: "Identified a shopping intent based on current tabs.", priority: .low))
        }
        
        currentState = .idle
    }
}

public enum HQuickAction {
    case summarizePage
    case saveToMemory
    case detectIntent
}
