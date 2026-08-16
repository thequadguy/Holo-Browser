import Foundation

/// Fast, deterministic, on-device search and ranking engine over local text snippets and research notes.
public enum SemanticSearchEngine {

    private static let stopWords: Set<String> = [
        "a", "an", "and", "are", "as", "at", "be", "by", "for", "from",
        "has", "he", "in", "is", "it", "its", "of", "on", "that", "the",
        "to", "was", "were", "will", "with"
    ]

    /// Tokenizes a query or document into normalized lowercase alphanumeric terms.
    public static func tokenize(_ text: String) -> [String] {
        let lower = text.lowercased()
        let tokens = lower.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return tokens
    }

    /// Computes a deterministic relevance score for a snippet against query tokens.
    public static func computeRelevance(query: String, queryTokens: [String], snippet: String) -> Double {
        let lowerSnippet = snippet.lowercased()
        let lowerQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lowerSnippet.isEmpty, !lowerQuery.isEmpty else { return 0.0 }

        var score = 0.0

        // 1. Exact full-query substring match (highest priority)
        if lowerSnippet.contains(lowerQuery) {
            score += 100.0
            if lowerSnippet.hasPrefix(lowerQuery) {
                score += 25.0
            }
        }

        // 2. Token-level matching
        let snippetTokens = tokenize(snippet)
        guard !snippetTokens.isEmpty else { return score }

        let meaningfulQueryTokens = queryTokens.filter { !stopWords.contains($0) }
        let effectiveQueryTokens = meaningfulQueryTokens.isEmpty ? queryTokens : meaningfulQueryTokens

        var matchedTokensCount = 0
        for qToken in effectiveQueryTokens {
            var tokenOccurrences = 0
            for sToken in snippetTokens {
                if sToken == qToken {
                    tokenOccurrences += 1
                } else if sToken.hasPrefix(qToken) {
                    tokenOccurrences += 1
                    score += 5.0
                } else if sToken.contains(qToken) && qToken.count >= 3 {
                    tokenOccurrences += 1
                    score += 2.0
                }
            }
            if tokenOccurrences > 0 {
                matchedTokensCount += 1
                score += Double(min(tokenOccurrences, 5)) * 10.0
            }
        }

        // Coverage bonus: reward matching all query terms
        if !effectiveQueryTokens.isEmpty && matchedTokensCount == effectiveQueryTokens.count {
            score += 50.0
        }

        return score
    }

    /// Searches and ranks an array of text snippets by semantic relevance to the query.
    public static func search(query: String, snippets: [String]) -> [String] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return snippets }

        let queryTokens = tokenize(trimmedQuery)
        guard !queryTokens.isEmpty else { return snippets }

        var scoredSnippets: [(snippet: String, score: Double, originalIndex: Int)] = []

        for (idx, snippet) in snippets.enumerated() {
            let score = computeRelevance(query: trimmedQuery, queryTokens: queryTokens, snippet: snippet)
            if score > 0.0 {
                scoredSnippets.append((snippet: snippet, score: score, originalIndex: idx))
            }
        }

        // Sort by score descending; break ties by original document order for determinism
        scoredSnippets.sort { lhs, rhs in
            if abs(lhs.score - rhs.score) > 0.001 {
                return lhs.score > rhs.score
            }
            return lhs.originalIndex < rhs.originalIndex
        }

        return scoredSnippets.map { $0.snippet }
    }
}
