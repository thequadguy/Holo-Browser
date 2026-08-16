import Foundation

/// Defines recognized AI intent categories parsed from user input.
public enum AIIntentType: String, Codable {
    case summarize
    case compare
    case explain
    case missionTrack
    case generalPrompt
}

/// Represents the routed destination for a given omnibox query string.
public enum HoloSearchRoute {
    /// Navigate directly to a web URL or search engine query URL.
    case web(URL)
    /// Direct query to HoloMind AI assistant with classified intent.
    case ai(query: String, intent: AIIntentType)
    /// Direct query to HoloMission autonomous system.
    case mission(query: String)
}

/// Omega Mode: Intelligent search router that intercepts 'h ' and 'm ' prefixes
/// to direct traffic to HoloMind or HoloMissionSystem. Defaults to Brave Search.
public struct HoloSmartSearchRouter {
    private static let searchBase = "https://search.brave.com/search?q="

    /// Routes raw omnibox input to web navigation, HoloMind, or Mission system.
    public static func route(for input: String) -> HoloSearchRoute {
        let trimmedLeading = input.trimmingCharacters(in: .newlines)
        if trimmedLeading.trimmingCharacters(in: .whitespaces).isEmpty {
            return .web(URL(string: "holo://start")!)
        }

        // 1. AI Assistant Routing ('h ' or 'H ')
        if trimmedLeading.hasPrefix("h ") || trimmedLeading.hasPrefix("H ") {
            let rawQuery = String(trimmedLeading.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            let intent = resolveAIIntent(for: rawQuery)
            return .ai(query: rawQuery, intent: intent)
        }

        // 2. Mission System Routing ('m ' or 'M ' or 'mission ')
        if trimmedLeading.hasPrefix("m ") || trimmedLeading.hasPrefix("M ") {
            let query = String(trimmedLeading.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            return .mission(query: query)
        }
        if trimmedLeading.lowercased().hasPrefix("mission ") {
            let query = String(trimmedLeading.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            return .mission(query: query)
        }

        let trimmed = trimmedLeading.trimmingCharacters(in: .whitespacesAndNewlines)

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

    private static func resolveAIIntent(for query: String) -> AIIntentType {
        let lower = query.lowercased()
        if lower.hasPrefix("summarize") || lower.hasPrefix("summary") {
            return .summarize
        } else if lower.hasPrefix("compare") || lower.hasPrefix("versus") || lower.hasPrefix("vs") {
            return .compare
        } else if lower.hasPrefix("explain") || lower.hasPrefix("why") || lower.hasPrefix("how") {
            return .explain
        }
        return .generalPrompt
    }
}
