import XCTest
@testable import HoloBrowser

@MainActor
final class OmniboxViewModelTests: XCTestCase {
    
    var viewModel: OmniboxViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = OmniboxViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State
    
    func testInitialState() {
        XCTAssertEqual(viewModel.query, "")
        XCTAssertEqual(viewModel.selectedIndex, -1)
        XCTAssertEqual(viewModel.suggestions.count, 4) // Search, Navigation, HoloMind, Mission default items
        
        guard let first = viewModel.suggestions.first else {
            XCTFail("Missing suggestions")
            return
        }
        
        if case .search(_) = first.type {
            XCTAssertEqual(first.title, "Search the web")
        } else {
            XCTFail("Expected first item to be search default")
        }
    }
    
    // MARK: - URL and Search Intents
    
    func testURLIntent() {
        viewModel.updateSuggestions(for: "github.com")
        
        guard let first = viewModel.suggestions.first else {
            XCTFail("Missing suggestions")
            return
        }
        
        if case .navigation(let url) = first.type {
            XCTAssertEqual(url.absoluteString, "https://github.com")
        } else {
            XCTFail("Expected navigation intent, got \(first.type)")
        }
    }
    
    func testSearchIntent() {
        viewModel.updateSuggestions(for: "best mechanical keyboard")
        
        guard let first = viewModel.suggestions.first else {
            XCTFail("Missing suggestions")
            return
        }
        
        if case .search(let q) = first.type {
            XCTAssertEqual(q, "best mechanical keyboard")
            XCTAssertEqual(first.title, "Search the web for \"best mechanical keyboard\"")
        } else {
            XCTFail("Expected search intent")
        }
    }
    
    // MARK: - HoloMind and Mission Intents
    
    func testHoloMindIntent() {
        viewModel.updateSuggestions(for: "h summarize this page")
        
        guard let first = viewModel.suggestions.first else {
            XCTFail("Missing suggestions")
            return
        }
        
        if case .holomind(let prompt) = first.type {
            XCTAssertEqual(prompt, "summarize this page")
            XCTAssertEqual(first.title, "Ask HoloMind")
        } else {
            XCTFail("Expected HoloMind intent")
        }
    }
    
    func testMissionIntent() {
        viewModel.updateSuggestions(for: "m track pokemon prices")
        
        guard let first = viewModel.suggestions.first else {
            XCTFail("Missing suggestions")
            return
        }
        
        if case .mission(let goal) = first.type {
            XCTAssertEqual(goal, "track pokemon prices")
            XCTAssertEqual(first.title, "Start Mission")
        } else {
            XCTFail("Expected Mission intent")
        }
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCases() {
        viewModel.updateSuggestions(for: "   ")
        XCTAssertEqual(viewModel.suggestions.count, 4) // Empty state
        
        viewModel.updateSuggestions(for: "h ")
        if case .holomind(let prompt) = viewModel.suggestions.first!.type {
            XCTAssertEqual(prompt, "")
        } else {
            XCTFail("Expected empty holomind intent")
        }
        
        viewModel.updateSuggestions(for: "m ")
        if case .mission(let goal) = viewModel.suggestions.first!.type {
            XCTAssertEqual(goal, "")
        } else {
            XCTFail("Expected empty mission intent")
        }
    }
    
    // MARK: - Keyboard Traversal
    
    func testKeyboardNavigation() {
        viewModel.updateSuggestions(for: "test")
        let total = viewModel.suggestions.count
        XCTAssertGreaterThan(total, 0)
        
        // Initial selectedIndex should be -1
        XCTAssertEqual(viewModel.selectedIndex, -1)
        
        viewModel.moveSelectionDown()
        XCTAssertEqual(viewModel.selectedIndex, 0)
        
        for _ in 1..<total {
            viewModel.moveSelectionDown()
        }
        XCTAssertEqual(viewModel.selectedIndex, total - 1)
        
        // Loop back to top
        viewModel.moveSelectionDown()
        XCTAssertEqual(viewModel.selectedIndex, -1)
        
        // From -1, move up should loop to bottom
        viewModel.moveSelectionUp()
        XCTAssertEqual(viewModel.selectedIndex, total - 1)
        
        viewModel.moveSelectionUp()
        XCTAssertEqual(viewModel.selectedIndex, total - 2)
    }
}
