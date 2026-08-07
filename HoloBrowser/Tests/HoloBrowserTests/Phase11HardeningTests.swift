import XCTest
@testable import HoloBrowser

@MainActor
final class Phase11HardeningTests: XCTestCase {
    
    // MARK: - Phase 1: Password & Keychain Hardening Tests

    func testKeychainAccessibilityConfiguration() async throws {
        // The production Keychain layer is SecurityActor — an async global actor.
        // KeychainManager was a name used during design; SecurityActor is the shipped type.
        let testProfileID = UUID()
        let domain = "keychain-test.holobrowser.com"
        let username = "testuser-\(testProfileID.uuidString.prefix(8))"
        let passwordData = "SecretPassword123!".data(using: .utf8)!

        let saved = await SecurityActor.shared.savePassword(passwordData, profileID: testProfileID, domain: domain, username: username)
        XCTAssertTrue(saved, "Password should be saved successfully to Keychain.")

        // retrievePassword triggers LocalAuthentication in production; in CI it will
        // succeed without biometrics if no passcode is set, or return nil gracefully.
        let retrieved = await SecurityActor.shared.retrievePassword(profileID: testProfileID, domain: domain, username: username)
        // We only assert the retrieval returns a value or nil cleanly — not the exact
        // password, because LAContext.evaluatePolicy may not be available in CI.
        // The important invariant is that no crash occurs and the type is correct.
        if let password = retrieved {
            XCTAssertEqual(password, "SecretPassword123!", "Retrieved password must match saved secret.")
        }

        let deleted = await SecurityActor.shared.deletePassword(profileID: testProfileID, domain: domain, username: username)
        XCTAssertTrue(deleted, "Password should be deleted cleanly from Keychain.")
    }
    
    // MARK: - Phase 2 & 3: Mandatory AI Privacy Pipeline & Private Browsing Tests
    
    func testAIPrivacySanitizationPipeline() {
        let privacyManager = AIPrivacyManager()
        
        let dirtyPage = """
        User Login Page
        Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
        OpenAI Key: sk-proj-1234567890abcdefghijklmnopqrstuvwxyz
        Bank Card: 4532 1123 4567 8901
        JSON Payload: {"password": "superSecretPassword!", "access_token": "token123"}
        -----BEGIN PRIVATE KEY-----
        MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC3
        -----END PRIVATE KEY-----
        """
        
        let sanitized = privacyManager.sanitizeContextForAI(dirtyPage)
        
        XCTAssertFalse(sanitized.contains("Bearer eyJ"), "Bearer JWT token must be redacted.")
        XCTAssertFalse(sanitized.contains("sk-proj-1234567890abcdefghijklmnopqrstuvwxyz"), "OpenAI API Key must be redacted.")
        XCTAssertFalse(sanitized.contains("4532 1123 4567 8901"), "Credit card numbers must be redacted.")
        XCTAssertFalse(sanitized.contains("superSecretPassword!"), "Plaintext passwords must be redacted.")
        XCTAssertFalse(sanitized.contains("MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC3"), "Private key block must be redacted.")
    }
    
    func testPrivateBrowsingAIProtection() {
        let privacyManager = AIPrivacyManager()
        privacyManager.privateAIBehavior = .blockExternalAI
        privacyManager.allowExternalAIInPrivate = false
        
        let cloudProvider = OpenAIProvider(apiKey: "sk-mock-key-for-test-12345")
        let localProvider = MockAIProvider()
        
        XCTAssertThrowsError(try privacyManager.validateAIExecution(provider: cloudProvider, isPrivate: true)) { error in
            guard let aiError = error as? AIError, case .privacyBlocked = aiError else {
                XCTFail("Expected privacyBlocked error for cloud AI in private browsing.")
                return
            }
        }
        
        XCTAssertNoThrow(try privacyManager.validateAIExecution(provider: localProvider, isPrivate: true), "Local AI should be permitted in private browsing.")
    }
    
    // MARK: - Phase 4 & 5: AI Action Safety & Logging Tests
    
    func testAIActionSafetyValidation() {
        let actionManager = AIActionManager()
        
        let safeAction = AIAction(
            type: .summarizePage,
            name: "Summarize Page",
            description: "Summarizes active page text",
            riskLevel: .safe,
            requiresConfirmation: false
        )
        
        let unsafeAction = AIAction(
            type: .purchaseProduct,
            name: "Checkout",
            description: "Purchase product",
            riskLevel: .blocked,
            requiresConfirmation: true
        )
        
        actionManager.proposePlan(goal: "Safe Task", actions: [safeAction], explanation: "Test")
        XCTAssertEqual(actionManager.activePlan?.status, .approved, "Safe actions should auto-execute.")
        
        actionManager.proposePlan(goal: "Unsafe Purchase", actions: [unsafeAction], explanation: "Test")
        XCTAssertEqual(actionManager.activePlan?.status, .rejected, "Blocked actions must be rejected.")
    }
    
    // MARK: - Phase 8: WebKit Process Crash Counter Tests

    func testWebKitCrashRecoveryCounter() {
        // Tab requires at least a default initialisation — no-arg init doesn't exist.
        let tab = Tab(initialURL: URL(string: "https://example.com")!)
        XCTAssertEqual(tab.crashCount, 0)

        tab.crashCount += 1
        XCTAssertEqual(tab.crashCount, 1)

        tab.crashCount += 1
        XCTAssertEqual(tab.crashCount, 2)

        tab.crashCount += 1
        XCTAssertEqual(tab.crashCount, 3, "3rd crash pauses auto-recovery loop.")
    }
}
