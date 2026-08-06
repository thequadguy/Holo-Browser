import Foundation

/// Utility for building structured system and user prompts.
public enum PromptBuilder {
    
    public static func buildSummarizeRequest(pageTitle: String, pageText: String) -> AIRequest {
        let systemPrompt = "You are Holo AI, a high-performance executive web summary assistant. Provide concise, bulleted summaries of articles."
        let userPrompt = "Summarize the webpage titled '\(pageTitle)'. Give 3 key takeaways and a 2-sentence executive summary."
        
        let message = AIMessage(role: .user, content: userPrompt)
        return AIRequest(
            messages: [message],
            pageContextText: pageText,
            systemInstruction: systemPrompt
        )
    }
    
    public static func buildAskPageRequest(question: String, pageText: String) -> AIRequest {
        let systemPrompt = "You are Holo AI. Answer questions strictly based on the provided webpage context."
        let message = AIMessage(role: .user, content: question)
        return AIRequest(
            messages: [message],
            pageContextText: pageText,
            systemInstruction: systemPrompt
        )
    }
    
    public static func buildExplainSelectionRequest(selection: String) -> AIRequest {
        let systemPrompt = "You are Holo AI. Explain the user's selected text clearly and concisely."
        let userPrompt = "Explain the following text:\n\n\"\(selection)\""
        let message = AIMessage(role: .user, content: userPrompt)
        return AIRequest(
            messages: [message],
            systemInstruction: systemPrompt
        )
    }
    
    public static func buildRewriteSelectionRequest(selection: String, style: String = "professional") -> AIRequest {
        let systemPrompt = "You are Holo AI. Rewrite the selected text to be clear and \(style)."
        let userPrompt = "Rewrite the following text:\n\n\"\(selection)\""
        let message = AIMessage(role: .user, content: userPrompt)
        return AIRequest(
            messages: [message],
            systemInstruction: systemPrompt
        )
    }
}
