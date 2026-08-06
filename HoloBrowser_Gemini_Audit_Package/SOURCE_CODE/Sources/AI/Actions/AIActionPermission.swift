import Foundation

/// Safety levels for AI action permission evaluation.
public enum AIActionPermission: String, Codable, CaseIterable, Equatable {
    case safe = "Safe (Read-Only)"
    case confirm = "Requires User Approval"
    case blocked = "Blocked (Prohibited)"
}
