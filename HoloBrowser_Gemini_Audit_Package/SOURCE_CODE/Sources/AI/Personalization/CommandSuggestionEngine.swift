import Foundation

/// Dynamic contextual command suggestion provider evaluating current active page state.
public enum CommandSuggestionEngine {
    
    public static func suggestCommands(for pageTitle: String, urlString: String) -> [String] {
        let lower = pageTitle.lowercased() + " " + urlString.lowercased()
        
        if lower.contains("article") || lower.contains("blog") || lower.contains("news") || lower.contains("wikipedia") {
            return ["Summarize Page", "Add Current Page To Research", "Explain Selection", "Create Notes"]
        } else if lower.contains("shop") || lower.contains("amazon") || lower.contains("store") {
            return ["Find Products", "Add Current Page To Research", "Compare Open Tabs"]
        } else {
            return ["Summarize Page", "Start AI Workflow", "Create Research From Page", "Search My Knowledge & History"]
        }
    }
}
