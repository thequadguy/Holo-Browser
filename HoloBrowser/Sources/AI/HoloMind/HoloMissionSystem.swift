import Foundation

public enum HoloMissionCategory: String, Codable, CaseIterable, Identifiable {
    case research = "Research & Synthesis"
    case shopping = "Price & Product Comparison"
    case monitoring = "Content & Status Watcher"
    case workflow = "Multi-Tab Workflow"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .research: return "magnifyingglass.circle.fill"
        case .shopping: return "cart.fill"
        case .monitoring: return "eye.fill"
        case .workflow: return "flowchart.fill"
        }
    }
}

public enum MissionStepStatus: String, Codable {
    case pending = "Pending"
    case awaitingApproval = "Needs Approval"
    case completed = "Completed"
    case failed = "Failed"
}

public struct HoloMissionStep: Identifiable, Codable, Equatable {
    public let id: UUID
    public let stepNumber: Int
    public let title: String
    public let detail: String
    public var status: MissionStepStatus
    public var requiresHumanApproval: Bool
    
    public init(
        id: UUID = UUID(),
        stepNumber: Int,
        title: String,
        detail: String,
        status: MissionStepStatus = .pending,
        requiresHumanApproval: Bool = true
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.title = title
        self.detail = detail
        self.status = status
        self.requiresHumanApproval = requiresHumanApproval
    }
}

public struct HoloMission: Identifiable, Codable, Equatable {
    public let id: UUID
    public let goalTitle: String
    public let category: HoloMissionCategory
    public var steps: [HoloMissionStep]
    public var isCompleted: Bool
    public var progressFraction: Double
    public let creationDate: Date
    
    public init(
        id: UUID = UUID(),
        goalTitle: String,
        category: HoloMissionCategory,
        steps: [HoloMissionStep] = [],
        isCompleted: Bool = false,
        progressFraction: Double = 0.0,
        creationDate: Date = Date()
    ) {
        self.id = id
        self.goalTitle = goalTitle
        self.category = category
        self.steps = steps
        self.isCompleted = isCompleted
        self.progressFraction = progressFraction
        self.creationDate = creationDate
    }
}

/// Mission orchestrator breaking goals into multi-step action plans, enforcing human approval before action execution.
@MainActor
public final class HoloMissionSystem: ObservableObject {
    @Published public private(set) var activeMissions: [HoloMission] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("holomind_missions.json")
        load()
    }
    
    /// Generates a structured multi-step mission plan for a user-assigned goal.
    @discardableResult
    public func createMission(title: String, category: HoloMissionCategory) -> HoloMission {
        let steps = generateSteps(for: title, category: category)
        let mission = HoloMission(goalTitle: title, category: category, steps: steps)
        activeMissions.insert(mission, at: 0)
        saveAsync()
        return mission
    }
    
    public func approveStep(missionID: UUID, stepID: UUID) {
        guard let mIdx = activeMissions.firstIndex(where: { $0.id == missionID }) else { return }
        guard let sIdx = activeMissions[mIdx].steps.firstIndex(where: { $0.id == stepID }) else { return }
        
        activeMissions[mIdx].steps[sIdx].status = .completed
        updateMissionProgress(mIdx)
        saveAsync()
    }
    
    public func deleteMission(id: UUID) {
        activeMissions.removeAll(where: { $0.id == id })
        saveAsync()
    }
    
    private func updateMissionProgress(_ mIdx: Int) {
        let steps = activeMissions[mIdx].steps
        guard !steps.isEmpty else { return }
        let completed = steps.filter { $0.status == .completed }.count
        let fraction = Double(completed) / Double(steps.count)
        activeMissions[mIdx].progressFraction = fraction
        if completed == steps.count {
            activeMissions[mIdx].isCompleted = true
        }
    }
    
    private func generateSteps(for title: String, category: HoloMissionCategory) -> [HoloMissionStep] {
        switch category {
        case .research:
            return [
                HoloMissionStep(stepNumber: 1, title: "Gather Web Sources", detail: "Scan open tabs and search web for '\(title)'", status: .completed, requiresHumanApproval: false),
                HoloMissionStep(stepNumber: 2, title: "Synthesize Findings", detail: "Extract key arguments and citations into Research Note", status: .awaitingApproval, requiresHumanApproval: true),
                HoloMissionStep(stepNumber: 3, title: "Archive Reference Tabs", detail: "Bookmark reference sources and organize tabs", status: .pending, requiresHumanApproval: true)
            ]
        case .shopping:
            return [
                HoloMissionStep(stepNumber: 1, title: "Extract Product Specs", detail: "Parse price and availability across open store tabs", status: .completed, requiresHumanApproval: false),
                HoloMissionStep(stepNumber: 2, title: "Compare Deals", detail: "Build price comparison matrix for '\(title)'", status: .awaitingApproval, requiresHumanApproval: true),
                HoloMissionStep(stepNumber: 3, title: "Track Price Drop", detail: "Set background watcher for target discount", status: .pending, requiresHumanApproval: true)
            ]
        case .monitoring:
            return [
                HoloMissionStep(stepNumber: 1, title: "Establish Watcher", detail: "Monitor web page changes for '\(title)'", status: .completed, requiresHumanApproval: false),
                HoloMissionStep(stepNumber: 2, title: "Notify On Delta", detail: "Emit insight notification when page updates", status: .awaitingApproval, requiresHumanApproval: true)
            ]
        case .workflow:
            return [
                HoloMissionStep(stepNumber: 1, title: "Identify Workspace Tabs", detail: "Group relevant tabs into project container", status: .completed, requiresHumanApproval: false),
                HoloMissionStep(stepNumber: 2, title: "Execute Action Sequence", detail: "Run automated action plan for '\(title)'", status: .awaitingApproval, requiresHumanApproval: true)
            ]
        }
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([HoloMission].self, from: data)
            self.activeMissions = items
        } catch {
            self.activeMissions = []
        }
    }
    
    private func saveAsync() {
        let copy = activeMissions
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save HoloMissions: \(error.localizedDescription)")
            }
        }
    }
}
