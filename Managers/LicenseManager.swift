//
//  LicenseManager.swift
//  ClipboardManager
//
//  License validation and Pro feature management
//

import Foundation
import Security

// MARK: - Paddle Configuration
// Uses a simple checkout page on your website (website/checkout.html)
// Deploy checkout.html to your website, then it will open Paddle.js checkout

struct PaddleConfig {
    // Your website checkout page URL (GitHub Pages)
    static let checkoutPageURL = "https://dcrivac.github.io/Clipso/checkout.html"

    // Production Paddle price IDs from Catalog → Products
    static let lifetimePriceID = "pri_01kfqf26bqncwbr7nvrg445esy"  // Lifetime: $29.99
    static let annualPriceID = "pri_01kfqf40kc2jn9cgx9a6naenk7"    // Annual: $7.99/year

    // Generate checkout URLs with price_id parameter
    static var lifetimeCheckoutURL: String {
        return "\(checkoutPageURL)?price_id=\(lifetimePriceID)"
    }

    static var annualCheckoutURL: String {
        return "\(checkoutPageURL)?price_id=\(annualPriceID)"
    }
}

// MARK: - License Manager
class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    @Published var isProUser: Bool = false
    @Published var licenseType: LicenseType = .free
    @Published var licenseEmail: String?

    // MARK: - Development Mode
    // Set this to true in debug builds to test Pro features without activation
    #if DEBUG
    @Published var isDevelopmentMode: Bool = false {
        didSet {
            print("🔧 Development Mode: \(isDevelopmentMode ? "ENABLED" : "DISABLED")")
            print("   Pro features are now \(isDevelopmentMode ? "accessible" : "restricted")")
        }
    }
    #endif

    // License server URL
    private let licenseServerURL = "https://api.clipso.app" // Update with your deployed server URL
    // For local testing: "http://localhost:3000"

    // Keychain keys
    private let licenseKeyKeychainKey = "com.clipboardmanager.license.key"
    private let licenseEmailKeychainKey = "com.clipboardmanager.license.email"
    private let licenseTypeKeychainKey = "com.clipboardmanager.license.type"
    private let lastValidationKeychainKey = "com.clipboardmanager.license.lastvalidation"

    // Revalidation settings
    private let revalidationIntervalDays = 7 // Revalidate every 7 days
    private var revalidationTimer: Timer?

    enum LicenseType: String, Codable {
        case free = "free"
        case lifetime = "lifetime"
        case annual = "annual"
        case monthly = "monthly"
    }

    enum LicenseError: Error {
        case invalidKey
        case validationFailed
        case networkError
        case alreadyActivated
    }

    private init() {
        loadLicenseFromKeychain()

        // Start periodic revalidation if license is active
        if isProUser {
            startPeriodicRevalidation()
        }
    }

    // MARK: - Public Methods

    /// Check if user has Pro features
    func hasProAccess() -> Bool {
        #if DEBUG
        // In debug builds, allow development mode bypass for testing
        if isDevelopmentMode {
            return true
        }
        #endif

        return isProUser && (licenseType == .lifetime || licenseType == .annual || licenseType == .monthly)
    }

    #if DEBUG
    /// Enable development mode to test Pro features without license activation
    /// Only available in debug builds
    func enableDevelopmentMode() {
        isDevelopmentMode = true
    }

    /// Disable development mode
    func disableDevelopmentMode() {
        isDevelopmentMode = false
    }

    /// Toggle development mode
    func toggleDevelopmentMode() {
        isDevelopmentMode.toggle()
    }
    #endif

    /// Activate license with key
    func activateLicense(key: String, email: String = "") async throws {
        // Validate format
        guard !key.isEmpty else {
            throw LicenseError.invalidKey
        }

        // Validate with Paddle API
        let (isValid, type) = try await validateLicenseWithPaddle(key: key)

        guard isValid else {
            throw LicenseError.validationFailed
        }

        // Save to Keychain
        try saveLicenseToKeychain(key: key, email: email, type: type)

        // Update state
        await MainActor.run {
            self.isProUser = true
            self.licenseType = type
            self.licenseEmail = email.isEmpty ? nil : email

            // Start periodic revalidation
            self.startPeriodicRevalidation()
        }
    }

    /// Deactivate license (for logout or refund)
    func deactivateLicense() {
        deleteLicenseFromKeychain()
        isProUser = false
        licenseType = .free
        licenseEmail = nil

        // Stop periodic revalidation
        stopPeriodicRevalidation()
    }

    /// Open Paddle checkout for purchase
    func purchaseLifetime() {
        // Simply open the Paddle payment link (no API calls needed!)
        if let url = URL(string: PaddleConfig.lifetimeCheckoutURL) {
            NSWorkspace.shared.open(url)
        }
    }

    func purchaseAnnual() {
        // Simply open the Paddle payment link (no API calls needed!)
        if let url = URL(string: PaddleConfig.annualCheckoutURL) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Feature Gating

    func canUseSemanticSearch() -> Bool {
        return hasProAccess()
    }

    func canUseContextDetection() -> Bool {
        return hasProAccess()
    }

    func getMaxItems() -> Int {
        return hasProAccess() ? Int.max : 250
    }

    func getMaxRetentionDays() -> Int {
        return hasProAccess() ? Int.max : 30
    }

    // MARK: - Private Methods

    private func validateLicenseWithPaddle(key: String) async throws -> (Bool, LicenseType) {
        // Use backend API for license validation and activation
        let urlString = "\(licenseServerURL)/api/licenses/activate"

        guard let url = URL(string: urlString) else {
            throw LicenseError.networkError
        }

        // Get device info
        let instanceID = getDeviceInstanceID()
        let deviceName = Host.current().localizedName ?? "Mac"
        let deviceModel = getDeviceModel()
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        // Configure URL session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)

        // Prepare request body
        let requestBody: [String: Any] = [
            "license_key": key,
            "device_id": instanceID,
            "device_name": deviceName,
            "device_model": deviceModel,
            "os_version": osVersion,
            "app_version": appVersion
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw LicenseError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseError.networkError
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LicenseError.networkError
        }

        // Check if activation was successful
        guard let success = json["success"] as? Bool, success else {
            // Handle specific error cases
            if let error = json["error"] as? String {
                switch error {
                case "INVALID_LICENSE":
                    throw LicenseError.invalidKey
                case "DEVICE_LIMIT_EXCEEDED":
                    throw LicenseError.alreadyActivated
                default:
                    throw LicenseError.validationFailed
                }
            }
            throw LicenseError.validationFailed
        }

        // Extract license type
        guard let licenseTypeString = json["license_type"] as? String,
              let licenseType = LicenseType(rawValue: licenseTypeString) else {
            throw LicenseError.validationFailed
        }

        // Save last validation timestamp
        saveToKeychain(key: lastValidationKeychainKey, value: ISO8601DateFormatter().string(from: Date()))

        return (true, licenseType)
    }

    /// Revalidate existing license with backend
    private func revalidateLicense() async throws {
        guard let licenseKey = getFromKeychain(key: licenseKeyKeychainKey) else {
            throw LicenseError.invalidKey
        }

        let urlString = "\(licenseServerURL)/api/licenses/validate"

        guard let url = URL(string: urlString) else {
            throw LicenseError.networkError
        }

        let instanceID = getDeviceInstanceID()

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        let session = URLSession(configuration: config)

        let requestBody: [String: Any] = [
            "license_key": licenseKey,
            "device_id": instanceID
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw LicenseError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseError.networkError
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let valid = json["valid"] as? Bool else {
            throw LicenseError.networkError
        }

        if !valid {
            // License is no longer valid, deactivate
            print("⚠️ License validation failed, deactivating")
            deactivateLicense()
            throw LicenseError.validationFailed
        }

        // Update last validation timestamp
        saveToKeychain(key: lastValidationKeychainKey, value: ISO8601DateFormatter().string(from: Date()))

        print("✅ License revalidated successfully")
    }

    private func determineLicenseTypeFromPriceID(priceID: String) -> LicenseType {
        // Check naming patterns in price ID
        let idLower = priceID.lowercased()
        if idLower.contains("lifetime") {
            return .lifetime
        } else if idLower.contains("annual") || idLower.contains("year") {
            return .annual
        } else if idLower.contains("month") {
            return .monthly
        }

        // Default to lifetime for one-time purchases
        return .lifetime
    }

    private func getDeviceInstanceID() -> String {
        // Use a unique identifier for this Mac
        // Check if we have one stored, otherwise create new
        let instanceKey = "com.clipboardmanager.device.instanceid"

        if let stored = UserDefaults.standard.string(forKey: instanceKey) {
            return stored
        }

        // Create new instance ID using device serial number or UUID
        let instanceID = UUID().uuidString
        UserDefaults.standard.set(instanceID, forKey: instanceKey)
        return instanceID
    }

    private func getDeviceModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    /// Start periodic revalidation timer
    private func startPeriodicRevalidation() {
        // Check if we need to revalidate now
        Task {
            await checkAndRevalidate()
        }

        // Set up timer to check every day
        revalidationTimer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.checkAndRevalidate()
            }
        }

        print("🔄 Periodic revalidation started (every 24 hours)")
    }

    /// Stop periodic revalidation timer
    private func stopPeriodicRevalidation() {
        revalidationTimer?.invalidate()
        revalidationTimer = nil
        print("🛑 Periodic revalidation stopped")
    }

    /// Check if revalidation is needed and perform it
    private func checkAndRevalidate() async {
        guard isProUser else {
            return
        }

        // Check last validation timestamp
        guard let lastValidationString = getFromKeychain(key: lastValidationKeychainKey),
              let lastValidation = ISO8601DateFormatter().date(from: lastValidationString) else {
            // No validation timestamp, revalidate now
            print("ℹ️ No validation timestamp, revalidating now")
            await performRevalidation()
            return
        }

        // Check if revalidation interval has passed
        let daysSinceValidation = Calendar.current.dateComponents([.day], from: lastValidation, to: Date()).day ?? 0

        if daysSinceValidation >= revalidationIntervalDays {
            print("ℹ️ \(daysSinceValidation) days since last validation, revalidating now")
            await performRevalidation()
        } else {
            print("✅ License still valid (\(daysSinceValidation) days since last validation)")
        }
    }

    /// Perform license revalidation
    private func performRevalidation() async {
        do {
            try await revalidateLicense()
        } catch {
            print("⚠️ License revalidation failed: \(error)")
            // Don't immediately deactivate on network errors
            // Only deactivate if server explicitly says license is invalid
            if case LicenseError.validationFailed = error {
                await MainActor.run {
                    self.deactivateLicense()
                }
            }
        }
    }


    // MARK: - Keychain Management

    private func loadLicenseFromKeychain() {
        guard let _ = getFromKeychain(key: licenseKeyKeychainKey),
              let email = getFromKeychain(key: licenseEmailKeychainKey),
              let typeString = getFromKeychain(key: licenseTypeKeychainKey),
              let type = LicenseType(rawValue: typeString) else {
            return
        }

        self.isProUser = true
        self.licenseType = type
        self.licenseEmail = email

        // TODO: Re-validate license every 7 days to prevent key sharing
    }

    private func saveLicenseToKeychain(key: String, email: String, type: LicenseType) throws {
        saveToKeychain(key: licenseKeyKeychainKey, value: key)
        saveToKeychain(key: licenseEmailKeychainKey, value: email)
        saveToKeychain(key: licenseTypeKeychainKey, value: type.rawValue)
    }

    private func deleteLicenseFromKeychain() {
        deleteFromKeychain(key: licenseKeyKeychainKey)
        deleteFromKeychain(key: licenseEmailKeychainKey)
        deleteFromKeychain(key: licenseTypeKeychainKey)
    }

    // Generic Keychain helpers
    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else {
            print("⚠️ Failed to convert string to data for keychain: \(key)")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("⚠️ Failed to save to keychain: \(key), status: \(status)")
        }
    }

    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - License Activation View
import SwiftUI

struct LicenseActivationView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var licenseKey = ""
    @State private var email = ""
    @State private var isActivating = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Activate Pro License")
                .font(.title)
                .fontWeight(.bold)

            Text("Enter your license key from the purchase email")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("your@email.com", text: $email)
                    .textFieldStyle(.roundedBorder)

                Text("License Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: activateLicense) {
                if isActivating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.7)
                } else {
                    Text("Activate License")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(licenseKey.isEmpty || email.isEmpty || isActivating)

            Divider()

            HStack(spacing: 20) {
                Button("Purchase Lifetime ($29.99)") {
                    licenseManager.purchaseLifetime()
                }
                .buttonStyle(.bordered)

                Button("Purchase Annual ($7.99)") {
                    licenseManager.purchaseAnnual()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(30)
        .frame(width: 500)
        .alert("License Activated!", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text("Your Pro features have been activated!")
        }
    }

    private func activateLicense() {
        isActivating = true
        errorMessage = nil

        Task {
            do {
                try await licenseManager.activateLicense(key: licenseKey, email: email)
                await MainActor.run {
                    isActivating = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isActivating = false
                    errorMessage = "Invalid license key or email. Please check and try again."
                }
            }
        }
    }
}

// MARK: - Pro Upgrade Prompt View
struct ProUpgradePromptView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @Environment(\.dismiss) var dismiss

    let feature: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Upgrade to Pro")
                .font(.title)
                .fontWeight(.bold)

            Text("\(feature) is a Pro feature")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "brain", text: "AI Semantic Search")
                FeatureRow(icon: "chart.pie", text: "Context Detection")
                FeatureRow(icon: "infinity", text: "Unlimited Items")
                FeatureRow(icon: "clock", text: "Unlimited Retention")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            HStack(spacing: 15) {
                Button("Get Lifetime Pro ($29.99)") {
                    licenseManager.purchaseLifetime()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("Get Annual Pro ($7.99)") {
                    licenseManager.purchaseAnnual()
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            Button("Maybe Later") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 450)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
        }
    }
}
