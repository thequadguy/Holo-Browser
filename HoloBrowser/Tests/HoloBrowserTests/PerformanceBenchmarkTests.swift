import XCTest
@testable import HoloBrowser

final class PerformanceBenchmarkTests: XCTestCase {
    
    func testSmartTabClassificationPerformance() {
        let dummyURL = URL(string: "https://github.com/apple/swift")!
        let title = "Apple Swift GitHub Repository"
        
        measure {
            for _ in 0..<1000 {
                _ = TabClassifier.classify(url: dummyURL, title: title)
            }
        }
    }
    
    func testAIPrivacyContextSanitizationPerformance() {
        let privacyManager = AIPrivacyManager()
        let sampleContext = "User Bearer secrettoken123 sk-1234567890abcdef12345678 password=Secret123 4532012345678901"
        
        measure {
            for _ in 0..<500 {
                _ = privacyManager.sanitizeContextForAI(sampleContext)
            }
        }
    }
    
    @MainActor
    func testSemanticSearchPerformance() {
        let snippets = (0..<500).map { "Research snippet #\($0) covering Swift 6 strict concurrency and WebKit performance." }
        
        measure {
            _ = SemanticSearchEngine.search(query: "Swift 6", snippets: snippets)
        }
    }
}
