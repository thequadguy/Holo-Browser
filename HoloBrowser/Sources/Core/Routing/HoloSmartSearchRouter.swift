import Foundation

public enum AIIntentType: String, Codable {
    case summarize
    case compare
    case explain
    case missionTrack
    case generalPrompt
}

public enum HoloSearchRoute {
    case web(URL)
    case ai(query: String, intent: AIIntentType)
    case mission(query: String)
}

/// Omega Mode: Intelligent search router that intercepts 'h ' and 'm ' prefixes 
/// to direct traffic to HoloMind or HoloMissionSystem. Defaults to Brave Search.
public struct HoloSmartSearchRouter {
    private static let searchBase = "https://search.brave.com/search?q="
    
    public static func route(for input: String) -> HoloSearchRoute {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .web(URL(string: "holo://start")!) }
        
        // 1. AI Assistant Routing ('h ' or 'H ')
        if trimmed.hasPrefix("h ") || trimmed.hasPrefix("H ") {
            let rawQuery = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            let lower = rawQuery.lowercased()
            
            let intent: AIIntentType
            if lower.hasPrefix("summarize") || lower.hasPrefix("summary") {
                intent = .summarize
            } else if lower.hasPrefix("compare") || lower.hasPrefix("versus") || lower.hasPrefix("vs") {
                intent = .compare
            } else if lower.hasPrefix("explain") || lower.hasPrefix("why") || lower.hasPrefix("how") {
                intent = .explain
            } else {
                intent = .generalPrompt
            }
            
            return .ai(query: rawQuery, intent: intent)
        }
        
        // 2. Mission System Routing ('m ' or 'M ' or 'mission ')
        if trimmed.hasPrefix("m ") || trimmed.hasPrefix("M ") {
            let query = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            return .mission(query: query)
        }
        if trimmed.lowercased().hasPrefix("mission ") {
            let query = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            return .mission(query: query)
        }
        
        // 3. Explicit Scheme (http, https, holo)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") || trimmed.hasPrefix("holo://") {
            if let url = URL(string: trimmed) {
                return .web(url)
            }
        }
        
        // 4. Domain inference (e.g. apple.com)
        if !trimmed.contains(" ") && trimmed.contains(".") {
            let prefixed = "https://" + trimmed
            if let url = URL(string: prefixed) {
                return .web(url)
            }
        }
        
        // 5. Fallback: Brave Search
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return .web(URL(string: searchBase + encoded) ?? URL(string: "https://search.brave.com")!)
    }
}
