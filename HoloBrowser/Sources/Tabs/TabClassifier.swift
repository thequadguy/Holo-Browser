import Foundation

/// Fast on-device domain and URL classifier for Smart Tab Intelligence.
public struct TabClassifier {
    
    public static func classify(url: URL?, title: String) -> String {
        let lowerTitle = title.lowercased()
        let lowerHost = (url?.host ?? "").lowercased()
        let lowerPath = (url?.path ?? "").lowercased()
        
        if lowerHost.contains("github") || lowerHost.contains("stackoverflow") || lowerHost.contains("apple") || lowerTitle.contains("swift") || lowerTitle.contains("code") {
            return "Development"
        } else if lowerHost.contains("wikipedia") || lowerHost.contains("arxiv") || lowerPath.contains("pdf") || lowerTitle.contains("research") {
            return "Research & Docs"
        } else if lowerHost.contains("amazon") || lowerHost.contains("ebay") || lowerHost.contains("shopify") || lowerTitle.contains("cart") {
            return "Shopping"
        } else if lowerHost.contains("youtube") || lowerHost.contains("netflix") || lowerHost.contains("spotify") || lowerTitle.contains("video") {
            return "Media & Streaming"
        } else if lowerHost.contains("news") || lowerHost.contains("reddit") || lowerHost.contains("medium") || lowerHost.contains("twitter") {
            return "News & Social"
        } else {
            return "General"
        }
    }
}
