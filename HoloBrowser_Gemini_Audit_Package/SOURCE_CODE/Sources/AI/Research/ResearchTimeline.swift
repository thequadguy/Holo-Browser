import Foundation

/// Manages chronological research session history.
@MainActor
public final class ResearchTimeline: ObservableObject {
    public static let shared = ResearchTimeline()
    
    @Published public private(set) var projects: [ResearchProject] = []
    
    private init() {}
    
    public func addProject(_ project: ResearchProject) {
        projects.append(project)
    }
}
