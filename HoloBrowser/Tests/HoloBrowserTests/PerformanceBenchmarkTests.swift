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
        let snippets = [
            "Swift 6 introduces strict concurrency checking by default for all actor boundaries.",
            "WebKit on macOS enables hardware accelerated rendering and native WebGL context.",
            "Python 3.12 improves interpreter startup latency and specialized bytecodes.",
            "HoloBrowser features native split view and HoloMind AI assistant context.",
            "Swift Concurrency model uses Sendable protocol to ensure data-race safety.",
            "Rust compiler guarantees memory safety through ownership and borrow checking."
        ]

        // 1. Functional correctness: Exact full query match tops the rank
        let swiftResults = SemanticSearchEngine.search(query: "Swift 6 Concurrency", snippets: snippets)
        XCTAssertFalse(swiftResults.isEmpty)
        XCTAssertEqual(swiftResults.first, snippets[0])

        // 2. Functional correctness: Empty query returns all snippets
        XCTAssertEqual(SemanticSearchEngine.search(query: "", snippets: snippets).count, snippets.count)

        // 3. Functional correctness: No match returns empty
        XCTAssertTrue(SemanticSearchEngine.search(query: "QuantumComputingX999", snippets: snippets).isEmpty)

        // 4. Performance benchmark
        measure {
            for _ in 0..<500 {
                _ = SemanticSearchEngine.search(query: "Swift 6 strict concurrency", snippets: snippets)
            }
        }
    }
}
