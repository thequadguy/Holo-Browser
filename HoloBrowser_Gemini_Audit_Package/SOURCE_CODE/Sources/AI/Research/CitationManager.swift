import Foundation

/// Formats citations in MLA, APA, or Simple URL formats locally with zero external network requests.
public enum CitationManager {
    
    public enum CitationStyle: String, CaseIterable {
        case mla = "MLA"
        case apa = "APA"
        case simple = "URL Only"
    }
    
    public static func formatCitation(for source: ResearchSource, style: CitationStyle) -> String {
        let dateStr = source.dateCollected.formatted(date: .numeric, time: .omitted)
        let domain = URL(string: source.urlString)?.host ?? "Website"
        
        switch style {
        case .mla:
            return "\"\(source.title).\" \(domain), \(dateStr). Web. <\(source.urlString)>."
        case .apa:
            return "\(domain). (\(dateStr)). \(source.title). Retrieved from \(source.urlString)"
        case .simple:
            return "\(source.title): \(source.urlString)"
        }
    }
}
