import Foundation

/// Built-in AI Workflow task templates for fast launch.
public struct WorkflowTemplate: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let goal: String
    public let iconName: String
    
    public init(id: String, title: String, goal: String, iconName: String) {
        self.id = id
        self.title = title
        self.goal = goal
        self.iconName = iconName
    }
    
    public static let defaultTemplates: [WorkflowTemplate] = [
        WorkflowTemplate(id: "product_research", title: "Product Research & Shopping", goal: "Find best prices and specs for a product topic", iconName: "cart"),
        WorkflowTemplate(id: "deep_research", title: "Topic Deep Dive", goal: "Synthesize multi-source research notes and key takeaways", iconName: "doc.text.magnifyingglass"),
        WorkflowTemplate(id: "writing_revision", title: "Tone & Writing Revision", goal: "Rewrite selected text for professional clarity", iconName: "pencil.line"),
        WorkflowTemplate(id: "tab_synthesis", title: "Compare Open Tabs", goal: "Analyze differences across active browsing tabs", iconName: "arrow.left.and.right")
    ]
}
