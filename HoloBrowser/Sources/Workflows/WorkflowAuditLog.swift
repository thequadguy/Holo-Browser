import Foundation

/// Audit log record capturing workflow requests, approvals, and outcomes.
public struct WorkflowAuditRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let workflowID: UUID
    public let goal: String
    public let timestamp: Date
    public let wasApproved: Bool
    public let outcome: String
    
    public init(
        id: UUID = UUID(),
        workflowID: UUID,
        goal: String,
        timestamp: Date = Date(),
        wasApproved: Bool,
        outcome: String
    ) {
        self.id = id
        self.workflowID = workflowID
        self.goal = goal
        self.timestamp = timestamp
        self.wasApproved = wasApproved
        self.outcome = outcome
    }
}

/// Audit logger tracking workflow history (`workflow_audit.json`).
@MainActor
public final class WorkflowAuditLog: ObservableObject {
    @Published public private(set) var auditRecords: [WorkflowAuditRecord] = []
    
    private let fileURL: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let holoFolder = appSupport.appendingPathComponent("HoloBrowser", isDirectory: true)
        try? FileManager.default.createDirectory(at: holoFolder, withIntermediateDirectories: true)
        self.fileURL = holoFolder.appendingPathComponent("workflow_audit.json")
        load()
    }
    
    public func log(workflowID: UUID, goal: String, wasApproved: Bool, outcome: String, isPrivate: Bool) {
        guard !isPrivate else { return }
        let record = WorkflowAuditRecord(workflowID: workflowID, goal: goal, wasApproved: wasApproved, outcome: outcome)
        auditRecords.insert(record, at: 0)
        save()
    }
    
    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([WorkflowAuditRecord].self, from: data)
            self.auditRecords = items
        } catch {
            self.auditRecords = []
        }
    }
    
    private func save() {
        let copy = auditRecords
        let url = fileURL
        Task.detached(priority: .utility) {
            do {
                let data = try JSONEncoder().encode(copy)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Failed to save workflow audit log off-main-thread: \(error.localizedDescription)")
            }
        }
    }
}
