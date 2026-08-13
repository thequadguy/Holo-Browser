import XCTest
@testable import HoloBrowser

@MainActor
final class HoloSpaceTests: XCTestCase {
    var tabManager: TabManager!
    var smartTabEngine: SmartTabEngine!
    let profileID = UUID()

    override func setUp() {
        super.setUp()
        tabManager = TabManager()
        smartTabEngine = SmartTabEngine.shared
    }

    override func tearDown() {
        tabManager = nil
        smartTabEngine = nil
        super.tearDown()
    }

    func testHoloSpaceCreationAndRename() {
        let space = tabManager.createSpace(name: "Research", icon: "book.fill", colorHex: "38BDF8", profileID: profileID)
        XCTAssertEqual(space.name, "Research")
        XCTAssertEqual(space.profileID, profileID)
        XCTAssertEqual(tabManager.spaces(for: profileID).count, 1)

        tabManager.renameSpace(id: space.id, newName: "Academic Research")
        XCTAssertEqual(tabManager.spaces(for: profileID).first?.name, "Academic Research")
    }

    func testHoloSpaceDeletionPreservesTabs() {
        let space = tabManager.createSpace(name: "Shopping", profileID: profileID)
        let tab1 = tabManager.createNewTab(url: URL(string: "https://apple.com")!, profileID: profileID)
        tabManager.assignTabToSpace(tabID: tab1.id, spaceID: space.id)

        XCTAssertEqual(tabManager.tabs(for: profileID, spaceID: space.id).count, 1)

        // Delete space -> tabs should remain open in the unassigned pool
        tabManager.deleteSpace(id: space.id)
        XCTAssertEqual(tabManager.spaces(for: profileID).count, 0)
        XCTAssertEqual(tabManager.tabs.count, 1)
        XCTAssertEqual(tabManager.tabs.first?.id, tab1.id)
    }

    func testSpaceTabMembershipAndDuplicatePrevention() {
        let space1 = tabManager.createSpace(name: "Work", profileID: profileID)
        let space2 = tabManager.createSpace(name: "Dev", profileID: profileID)

        let tab = tabManager.createNewTab(url: URL(string: "https://github.com")!, profileID: profileID)

        tabManager.assignTabToSpace(tabID: tab.id, spaceID: space1.id)
        XCTAssertTrue(tabManager.spaces.first(where: { $0.id == space1.id })?.containsTab(id: tab.id) ?? false)

        // Reassign to space2 -> must be removed from space1 to prevent duplicate membership
        tabManager.assignTabToSpace(tabID: tab.id, spaceID: space2.id)
        XCTAssertFalse(tabManager.spaces.first(where: { $0.id == space1.id })?.containsTab(id: tab.id) ?? true)
        XCTAssertTrue(tabManager.spaces.first(where: { $0.id == space2.id })?.containsTab(id: tab.id) ?? false)
    }

    func testProfileIsolation() {
        let profileA = UUID()
        let profileB = UUID()

        let spaceA = tabManager.createSpace(name: "Profile A Space", profileID: profileA)
        _ = tabManager.createSpace(name: "Profile B Space", profileID: profileB)

        let spacesForA = tabManager.spaces(for: profileA)
        let spacesForB = tabManager.spaces(for: profileB)

        XCTAssertEqual(spacesForA.count, 1)
        XCTAssertEqual(spacesForA.first?.id, spaceA.id)
        XCTAssertEqual(spacesForB.count, 1)
        XCTAssertNotEqual(spacesForB.first?.id, spaceA.id)
    }

    func testDuplicateURLDetectionNormalization() {
        let url1 = URL(string: "https://example.com/page?utm_source=twitter&gclid=123#section")
        let url2 = URL(string: "https://EXAMPLE.com/page/")

        let norm1 = smartTabEngine.normalizeURL(url1)
        let norm2 = smartTabEngine.normalizeURL(url2)

        XCTAssertEqual(norm1, norm2)
        XCTAssertEqual(norm1, "https://example.com/page")
    }
}
