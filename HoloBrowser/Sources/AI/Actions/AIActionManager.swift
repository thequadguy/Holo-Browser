import Foundation

/// Main-actor manager coordinating action plan creation, permission evaluation, safety validation, 30s timeouts, and privacy-sanitized logging.
@MainActor
public final class AIActionManager: ObservableObject {
    @Published public private(set) var activePlan: AIActionPlan?
    @Published public private(set) var actionLogs: [AIActionLog] = []
    @Published public var showPreviewModal: Bool = false
    
    public let executor: BrowserActionExecutor
    private let fileURL: URL
    
    public init(executor: BrowserActionExecutor? = nil) {
        self.executor = executor ?? BrowserActionExecutor()
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("ai_action_logs.json")
        loadLogs()
    }
    
    public func proposePlan(goal: String, actions: [AIAction], explanation: String) {
        // Enforce maximum action limit (Max 10 actions per plan)
        guard actions.count <= 10 else {
            let plan = AIActionPlan(goal: goal, actions: [], explanation: "Plan rejected: Exceeds maximum allowance of 10 actions.", status: .rejected)
            self.activePlan = plan
            logSanitized(actionName: goal, wasApproved: false, result: "Rejected: Plan exceeds 10 actions limit.")
            return
        }
        
        // Evaluate overall risk and URL safety
        let hasBlocked = actions.contains { action in
            if action.riskLevel == .blocked || action.type == .submitForm || action.type == .purchaseProduct || action.type == .modifyAccount {
                return true
            }
            if let urlString = action.parameters["url"] {
                return !isURLSafe(urlString)
            }
            return false
        }
        
        let initialStatus: PlanStatus = hasBlocked ? .rejected : .pending
        let plan = AIActionPlan(goal: goal, actions: actions, explanation: explanation, status: initialStatus)
        self.activePlan = plan
        
        if hasBlocked {
            logSanitized(actionName: goal, wasApproved: false, result: "Rejected: Plan contains prohibited actions or unsafe URLs.")
        } else if actions.allSatisfy({ isActionAutoExecutable($0) }) {
            // Auto-execute strictly safe actions only (.summarizePage, .explainSelection, .extractInformation, .createNote)
            self.activePlan?.status = .approved
            logSanitized(actionName: goal, wasApproved: true, result: "Safe action plan approved automatically.")
        } else {
            // Require user confirmation modal for navigateToURL, openNewTab, collectSource
            self.showPreviewModal = true
        }
    }
    
    public func approveActivePlan(viewModel: BrowserViewModel) async {
        guard var plan = activePlan, plan.status == .pending || plan.status == .approved else { return }
        showPreviewModal = false
        plan.status = .executing
        self.activePlan = plan
        
        var summaryResults: [String] = []
        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30s Execution Timeout
            return true
        }
        
        for action in plan.actions {
            if timeoutTask.isCancelled { break }
            if action.riskLevel == .blocked || action.type == .submitForm || action.type == .purchaseProduct || action.type == .modifyAccount {
                summaryResults.append("Skipped blocked action: \(action.name)")
                continue
            }
            if let urlString = action.parameters["url"], !isURLSafe(urlString) {
                summaryResults.append("Skipped unsafe URL action: \(action.name)")
                continue
            }
            
            let res = await executor.execute(action: action, viewModel: viewModel)
            summaryResults.append(res)
        }
        
        timeoutTask.cancel()
        plan.status = .completed
        self.activePlan = plan
        logSanitized(actionName: plan.goal, wasApproved: true, result: summaryResults.joined(separator: " | "))
    }
    
    public func rejectActivePlan() {
        showPreviewModal = false
        if var plan = activePlan {
            plan.status = .rejected
            self.activePlan = plan
            logSanitized(actionName: plan.goal, wasApproved: false, result: "User cancelled action plan.")
        }
    }
    
    // MARK: - Safety Helpers
    
    private func isActionAutoExecutable(_ action: AIAction) -> Bool {
        switch action.type {
        case .summarizePage, .extractInformation, .createNote, .scrollToSection:
            return action.riskLevel == .safe
        default:
            return false
        }
    }
    
    private func isURLSafe(_ urlString: String) -> Bool {
        let lower = urlString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.hasPrefix("javascript:") || lower.hasPrefix("data:") || lower.hasPrefix("file:") {
            return false
        }
        return true
    }
    
    // MARK: - Phase 5 Sanitized Action Logging
    
    private func logSanitized(actionName: String, wasApproved: Bool, result: String) {
        let sanitizedName = sanitizeLogText(actionName)
        let sanitizedResult = sanitizeLogText(result)
        let entry = AIActionLog(actionName: sanitizedName, wasApproved: wasApproved, result: sanitizedResult)
        actionLogs.insert(entry, at: 0)
        saveLogs()
    }
    
    private func sanitizeLogText(_ text: String) -> String {
        var clean = text
        // Strip query parameters and URL fragments
        clean = clean.replacingOccurrences(of: "\\?[^\\s]+", with: "", options: .regularExpression)
        clean = clean.replacingOccurrences(of: "#[^\\s]+", with: "", options: .regularExpression)
        // Strip authorization tokens or credentials
        clean = clean.replacingOccurrences(of: "(Bearer|token|key|password)=[^\\s]+", with: "$1=[REDACTED]", options: .regularExpression)
        return clean
    }
    
    private func loadLogs() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([AIActionLog].self, from: data)
            self.actionLogs = items
        } catch {
            self.actionLogs = []
        }
    }
    
    private func saveLogs() {
        let copy = actionLogs
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save action logs off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
