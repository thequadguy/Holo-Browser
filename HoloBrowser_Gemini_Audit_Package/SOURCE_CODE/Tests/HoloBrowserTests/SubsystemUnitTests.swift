import XCTest
@testable import HoloBrowser

final class SubsystemUnitTests: XCTestCase {
    
    @MainActor
    func testAIContextGatekeeperValidation() throws {
        let gatekeeper = AIContextGatekeeper.shared
        let provider = MockAIProvider()
        
        let (prompt, context) = try gatekeeper.processAndValidateRequest(
            prompt: "Help me sk-1234567890abcdef12345678",
            context: "Authorization: Bearer secrettoken123",
            provider: provider,
            isPrivateBrowsing: false
        )
        
        XCTAssertFalse(prompt.contains("sk-1234567890abcdef12345678"))
        XCTAssertFalse(context.contains("secrettoken123"))
    }
    
    @MainActor
    func testSmartTabManagerGroupingAndUndo() {
        let manager = SmartTabManager.shared
        let tab1 = Tab(url: URL(string: "https://github.com/swift")!, title: "Swift GitHub")
        let tab2 = Tab(url: URL(string: "https://apple.com")!, title: "Apple Developer")
        
        manager.analyzeTabs([tab1, tab2])
        XCTAssertFalse(manager.suggestions.isEmpty)
        
        manager.undoGrouping()
        XCTAssertTrue(manager.previousGroupsState.isEmpty)
    }
    
    @MainActor
    func testRecoveryManagerSafeMode() {
        let recovery = RecoveryManager.shared
        recovery.registerAppLaunch()
        recovery.registerStableExecution()
        XCTAssertEqual(recovery.consecutiveCrashCount, 0)
    }
    
    @MainActor
    func testMigrationManagerVersionTracking() {
        let migration = MigrationManager.shared
        migration.performPendingMigrations()
        XCTAssertGreaterThanOrEqual(migration.currentSchemaVersion, 1)
    }
    
    func testUpdateValidator() {
        let dummyURL = URL(fileURLWithPath: "/tmp/HoloBrowser_v1.1.dmg")
        let result = UpdateValidator.validateUpdatePackage(at: dummyURL, targetVersion: "1.1.0")
        XCTAssertFalse(result) // File doesn't exist on disk
    }
    
    @MainActor
    func testProfileManagerIsolation() {
        let manager = ProfileManager.shared
        let profile = manager.createProfile(name: "Test Profile", colorHex: "#FF0000")
        XCTAssertEqual(profile.name, "Test Profile")
    }
}
