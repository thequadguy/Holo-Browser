import Foundation

public enum HoloNotificationPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    public static func < (lhs: HoloNotificationPriority, rhs: HoloNotificationPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public struct HoloNotification: Identifiable {
    public let id: UUID
    public let title: String
    public let message: String
    public let priority: HoloNotificationPriority
    public let timestamp: Date
    public let actionTitle: String?
    public let action: (() -> Void)?
    
    public init(
        id: UUID = UUID(),
        title: String,
        message: String,
        priority: HoloNotificationPriority = .normal,
        timestamp: Date = Date(),
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.priority = priority
        self.timestamp = timestamp
        self.actionTitle = actionTitle
        self.action = action
    }
}

@MainActor
public final class HoloNotificationCenter: ObservableObject {
    @Published public private(set) var activeNotifications: [HoloNotification] = []
    
    public init() {}
    
    public func post(notification: HoloNotification) {
        // High priority notifications can trigger UI immediately if needed.
        activeNotifications.append(notification)
        
        // Keep only top 10 most recent
        if activeNotifications.count > 10 {
            activeNotifications.removeFirst(activeNotifications.count - 10)
        }
        
        // Sort by priority then timestamp (descending)
        activeNotifications.sort {
            if $0.priority == $1.priority {
                return $0.timestamp > $1.timestamp
            }
            return $0.priority > $1.priority
        }
    }
    
    public func dismiss(id: UUID) {
        activeNotifications.removeAll { $0.id == id }
    }
    
    public func clearAll() {
        activeNotifications.removeAll()
    }
}
