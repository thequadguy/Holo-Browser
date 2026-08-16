import XCTest
@testable import HoloBrowser

@MainActor
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
        // AIPrivacyManager.init() and sanitizeContextForAI are @MainActor-isolated.
        // The class-level @MainActor annotation ensures this test runs on the main actor.
        let privacyManager = AIPrivacyManager()
        let sampleContext = "User Bearer secrettoken123 sk-1234567890abcdef12345678 password=Secret123 4532012345678901"

        measure {
            for _ in 0..<500 {
                _ = privacyManager.sanitizeContextForAI(sampleContext)
            }
        }
    }

    func testSemanticSearchPerformance() throws {
        // SemanticSearchEngine is not yet available in the production Sources tree.
        // This test is skipped until the implementation is added.
        throw XCTSkip("SemanticSearchEngine not yet implemented — pending future stage.")
    }
}
