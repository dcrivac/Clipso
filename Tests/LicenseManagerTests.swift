//
//  LicenseManagerTests.swift
//  ClipboardManager Tests
//
//  Unit tests for LicenseManager
//

import XCTest
@testable import ClipboardManager

class LicenseManagerTests: XCTestCase {

    var licenseManager: LicenseManager!

    override func setUp() {
        super.setUp()
        // Note: LicenseManager is a singleton, so we'll test with the shared instance
        // In a production app, you might want to make it injectable for testing
        licenseManager = LicenseManager.shared

        // Clear any existing license for testing
        licenseManager.deactivateLicense()
    }

    override func tearDown() {
        // Clean up after tests
        licenseManager.deactivateLicense()
        super.tearDown()
    }

    // MARK: - Pro Access Tests

    func testHasProAccess_WhenFree_ReturnsFalse() {
        XCTAssertFalse(licenseManager.hasProAccess(), "Free user should not have Pro access")
    }

    func testHasProAccess_WhenLifetime_ReturnsTrue() {
        // Manually set license state for testing
        licenseManager.isProUser = true
        licenseManager.licenseType = .lifetime

        XCTAssertTrue(licenseManager.hasProAccess(), "Lifetime user should have Pro access")
    }

    func testHasProAccess_WhenAnnual_ReturnsTrue() {
        licenseManager.isProUser = true
        licenseManager.licenseType = .annual

        XCTAssertTrue(licenseManager.hasProAccess(), "Annual user should have Pro access")
    }

    #if DEBUG
    func testDevelopmentMode_EnablesProAccess() {
        // Start with free user
        XCTAssertFalse(licenseManager.hasProAccess())

        // Enable development mode
        licenseManager.enableDevelopmentMode()

        // Should now have Pro access
        XCTAssertTrue(licenseManager.hasProAccess(), "Development mode should grant Pro access")

        // Disable development mode
        licenseManager.disableDevelopmentMode()

        // Should no longer have Pro access
        XCTAssertFalse(licenseManager.hasProAccess(), "Disabling development mode should revoke Pro access")
    }
    #endif

    // MARK: - Feature Gating Tests

    func testCanUseSemanticSearch_WhenFree_ReturnsFalse() {
        XCTAssertFalse(licenseManager.canUseSemanticSearch(), "Free user should not have semantic search")
    }

    func testCanUseSemanticSearch_WhenPro_ReturnsTrue() {
        licenseManager.isProUser = true
        licenseManager.licenseType = .lifetime

        XCTAssertTrue(licenseManager.canUseSemanticSearch(), "Pro user should have semantic search")
    }

    func testCanUseContextDetection_WhenFree_ReturnsFalse() {
        XCTAssertFalse(licenseManager.canUseContextDetection(), "Free user should not have context detection")
    }

    func testCanUseContextDetection_WhenPro_ReturnsTrue() {
        licenseManager.isProUser = true
        licenseManager.licenseType = .lifetime

        XCTAssertTrue(licenseManager.canUseContextDetection(), "Pro user should have context detection")
    }

    func testGetMaxItems_WhenFree_Returns250() {
        let maxItems = licenseManager.getMaxItems()
        XCTAssertEqual(maxItems, 250, "Free user should have limit of 250 items")
    }

    func testGetMaxItems_WhenPro_ReturnsUnlimited() {
        licenseManager.isProUser = true
        licenseManager.licenseType = .lifetime

        let maxItems = licenseManager.getMaxItems()
        XCTAssertEqual(maxItems, Int.max, "Pro user should have unlimited items")
    }

    func testGetMaxRetentionDays_WhenFree_Returns30() {
        let maxDays = licenseManager.getMaxRetentionDays()
        XCTAssertEqual(maxDays, 30, "Free user should have 30-day retention")
    }

    func testGetMaxRetentionDays_WhenPro_ReturnsUnlimited() {
        licenseManager.isProUser = true
        licenseManager.licenseType = .lifetime

        let maxDays = licenseManager.getMaxRetentionDays()
        XCTAssertEqual(maxDays, Int.max, "Pro user should have unlimited retention")
    }

    // MARK: - License Type Tests

    func testLicenseType_DefaultsToFree() {
        XCTAssertEqual(licenseManager.licenseType, .free, "Default license type should be free")
    }

    func testLicenseType_CanBeSet() {
        licenseManager.licenseType = .lifetime
        XCTAssertEqual(licenseManager.licenseType, .lifetime)

        licenseManager.licenseType = .annual
        XCTAssertEqual(licenseManager.licenseType, .annual)

        licenseManager.licenseType = .monthly
        XCTAssertEqual(licenseManager.licenseType, .monthly)
    }

    // MARK: - Deactivation Tests

    func testDeactivateLicense_ResetsState() {
        // Set up a Pro user
        licenseManager.isProUser = true
        licenseManager.licenseType = .lifetime
        licenseManager.licenseEmail = "test@example.com"

        // Deactivate
        licenseManager.deactivateLicense()

        // Verify state is reset
        XCTAssertFalse(licenseManager.isProUser, "isProUser should be false after deactivation")
        XCTAssertEqual(licenseManager.licenseType, .free, "License type should be free after deactivation")
        XCTAssertNil(licenseManager.licenseEmail, "License email should be nil after deactivation")
    }

    // MARK: - Configuration Tests

    func testPaddleConfig_LoadsSuccessfully() {
        // Test that Paddle configuration loads without crashing
        let config = PaddleConfig.loadConfig()

        XCTAssertFalse(config.vendorID.isEmpty, "Vendor ID should not be empty")
        XCTAssertFalse(config.lifetimePriceID.isEmpty, "Lifetime price ID should not be empty")
        XCTAssertFalse(config.annualPriceID.isEmpty, "Annual price ID should not be empty")
    }

    func testPaddleConfig_Sandbox_HasCorrectURLs() {
        let config = PaddleConfig.sandbox

        XCTAssertTrue(config.useSandbox, "Sandbox config should use sandbox")
        XCTAssertTrue(config.baseURL.contains("sandbox"), "Sandbox base URL should contain 'sandbox'")
        XCTAssertTrue(config.checkoutBaseURL.contains("sandbox"), "Sandbox checkout URL should contain 'sandbox'")
    }

    func testPaddleConfig_Production_HasCorrectURLs() {
        let config = PaddleConfig.production

        XCTAssertFalse(config.useSandbox, "Production config should not use sandbox")
        XCTAssertFalse(config.baseURL.contains("sandbox"), "Production base URL should not contain 'sandbox'")
        XCTAssertFalse(config.checkoutBaseURL.contains("sandbox"), "Production checkout URL should not contain 'sandbox'")
    }

    // MARK: - Device ID Tests

    func testDeviceInstanceID_IsPersistent() {
        // Get device ID twice
        let deviceID1 = licenseManager.getDeviceInstanceID()
        let deviceID2 = licenseManager.getDeviceInstanceID()

        // Should be the same
        XCTAssertEqual(deviceID1, deviceID2, "Device ID should be persistent across calls")
        XCTAssertFalse(deviceID1.isEmpty, "Device ID should not be empty")
    }

    // MARK: - Integration Tests (require backend)

    func testActivateLicense_WithInvalidKey_ThrowsError() async {
        // This test requires the backend server to be running
        // Skip if SKIP_INTEGRATION_TESTS environment variable is set
        guard ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == nil else {
            return
        }

        do {
            try await licenseManager.activateLicense(key: "INVALID-KEY-1234-5678", email: "test@example.com")
            XCTFail("Should throw error for invalid license key")
        } catch {
            // Expected error
            XCTAssertTrue(true, "Correctly threw error for invalid key")
        }
    }

    // MARK: - Performance Tests

    func testPerformance_HasProAccess() {
        measure {
            for _ in 0..<1000 {
                _ = licenseManager.hasProAccess()
            }
        }
    }

    func testPerformance_GetMaxItems() {
        measure {
            for _ in 0..<1000 {
                _ = licenseManager.getMaxItems()
            }
        }
    }

    // MARK: - Helper Methods

    private func setUpMockProUser() {
        licenseManager.isProUser = true
        licenseManager.licenseType = .lifetime
        licenseManager.licenseEmail = "test@example.com"
    }
}

// MARK: - Mock Data Extensions

extension LicenseManagerTests {
    func generateMockLicenseKey() -> String {
        return "CLIPSO-TEST-\(UUID().uuidString.prefix(4))-\(UUID().uuidString.prefix(4))"
    }
}
