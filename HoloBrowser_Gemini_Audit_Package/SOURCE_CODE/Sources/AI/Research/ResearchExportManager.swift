import Foundation

/// Handles Markdown and plain-text export formatting for research projects.
public enum ResearchExportManager {
    
    public static func exportToMarkdown(_ project: ResearchProject) -> String {
        var md = "# Research Report: \(project.title)\n"
        md += "**Topic**: \(project.topic)\n"
        md += "**Created**: \(ISO8601DateFormatter().string(from: project.createdAt))\n\n"
        
        md += "## Collected Sources (\(project.sources.count))\n"
        for (idx, src) in project.sources.enumerated() {
            md += "\(idx + 1). [\(src.title)](\(src.urlString))\n"
            md += "   - Summary: \(src.summary)\n"
        }
        
        if !project.notes.isEmpty {
            md += "\n## Notes & Syntheses\n"
            for note in project.notes {
                md += "- \(note)\n"
            }
        }
        
        return md
    }
}
