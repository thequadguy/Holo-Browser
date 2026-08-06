import Foundation

public struct DailyBriefing: Identifiable, Equatable {
    public let id: UUID
    public let date: Date
    public let greeting: String
    public let openResearchCount: Int
    public let unreadReadingCount: Int
    public let topTopics: [String]
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        greeting: String,
        openResearchCount: Int,
        unreadReadingCount: Int,
        topTopics: [String]
    ) {
        self.id = id
        self.date = date
        self.greeting = greeting
        self.openResearchCount = openResearchCount
        self.unreadReadingCount = unreadReadingCount
        self.topTopics = topTopics
    }
}

/// Opt-in morning daily briefing summary generator.
@MainActor
public final class DailyBriefingManager: ObservableObject {
    @Published public private(set) var briefing: DailyBriefing?
    @Published public var isOptedIn: Bool = true
    
    public init() {}
    
    public func generateBriefing(researchSessionsCount: Int, readingListCount: Int, isPrivate: Bool) {
        guard isOptedIn, !isPrivate else {
            self.briefing = nil
            return
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        
        self.briefing = DailyBriefing(
            greeting: "\(timeOfDay)! Here is your Holo AI daily summary:",
            openResearchCount: researchSessionsCount,
            unreadReadingCount: readingListCount,
            topTopics: ["Technology", "macOS Development", "AI Engineering"]
        )
    }
}
