import Foundation

public enum HAssistantState: String, Codable {
    case idle = "Ready to Assist"
    case analyzing = "Analyzing Browser Context"
    case planning = "Formulating Plan"
    case awaitingApproval = "Awaiting Your Approval"
    case executing = "Executing Approved Action"
}

/// Persona system enforcing H's calm, executive assistant tone, structured briefings, and non-invasive recommendation style.
public enum HPersonalitySystem {
    
    public static func formatExecutiveBriefing(headline: String, points: [String], recommendation: String? = nil) -> String {
        var output = "### Executive Briefing\n**\(headline)**\n\n"
        for point in points {
            output += "• \(point)\n"
        }
        if let rec = recommendation {
            output += "\n> **Recommended Action:** \(rec)"
        }
        return output
    }
    
    public static func formatApprovalRequest(actionTitle: String, details: String, riskLevel: String = "Low") -> String {
        return """
        ⚠️ **Action Approval Required**
        **Action:** \(actionTitle)
        **Details:** \(details)
        **Risk Rating:** \(riskLevel)
        
        *H will not proceed without your explicit confirmation.*
        """
    }
}
