//
//  LicenseManager.swift
//  ClipboardManager
//
//  License validation and Pro feature management
//

import Foundation
import Security

// MARK: - License Manager
class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    @Published var isProUser: Bool = false
    @Published var licenseType: LicenseType = .free
    @Published var licenseEmail: String?

    // Paddle Configuration
    private let vendorID = "YOUR_PADDLE_VENDOR_ID" // Replace with actual Vendor ID
    private let lifetimeProductID = "YOUR_LIFETIME_PRODUCT_ID"
    private let annualProductID = "YOUR_ANNUAL_PRODUCT_ID"

    // Keychain keys
    private let licenseKeyKeychainKey = "com.clipboardmanager.license.key"
    private let licenseEmailKeychainKey = "com.clipboardmanager.license.email"
    private let licenseTypeKeychainKey = "com.clipboardmanager.license.type"

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
    }

    // MARK: - Public Methods

    /// Check if user has Pro features
    func hasProAccess() -> Bool {
        return isProUser && (licenseType == .lifetime || licenseType == .annual || licenseType == .monthly)
    }

    /// Activate license with key and email
    func activateLicense(key: String, email: String) async throws {
        // Validate format
        guard !key.isEmpty, !email.isEmpty else {
            throw LicenseError.invalidKey
        }

        // Validate with Paddle API
        let isValid = try await validateLicenseWithPaddle(key: key, email: email)

        guard isValid else {
            throw LicenseError.validationFailed
        }

        // Determine license type from key prefix or API response
        let type = determineLicenseType(from: key)

        // Save to Keychain
        try saveLicenseToKeychain(key: key, email: email, type: type)

        // Update state
        await MainActor.run {
            self.isProUser = true
            self.licenseType = type
            self.licenseEmail = email
        }
    }

    /// Deactivate license (for logout or refund)
    func deactivateLicense() {
        deleteLicenseFromKeychain()
        isProUser = false
        licenseType = .free
        licenseEmail = nil
    }

    /// Open Paddle checkout for purchase
    func purchaseLifetime() {
        let checkoutURL = "https://buy.paddle.com/product/\(lifetimeProductID)"
        if let url = URL(string: checkoutURL) {
            NSWorkspace.shared.open(url)
        }
    }

    func purchaseAnnual() {
        let checkoutURL = "https://buy.paddle.com/product/\(annualProductID)"
        if let url = URL(string: checkoutURL) {
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

    private func validateLicenseWithPaddle(key: String, email: String) async throws -> Bool {
        // Paddle License Verification API
        // https://vendors.paddle.com/api/2.0/product/verify_license

        let urlString = "https://vendors.paddle.com/api/2.0/product/verify_license"
        guard let url = URL(string: urlString) else {
            throw LicenseError.networkError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "vendor_id": vendorID,
            "license_code": key,
            "activation_email": email
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LicenseError.networkError
        }

        // Parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool {
            return success
        }

        return false
    }

    private func determineLicenseType(from key: String) -> LicenseType {
        // Example: Keys could be prefixed with type
        // LT-XXXX-XXXX-XXXX for Lifetime
        // AN-XXXX-XXXX-XXXX for Annual
        if key.hasPrefix("LT-") {
            return .lifetime
        } else if key.hasPrefix("AN-") {
            return .annual
        }
        // Default to lifetime for launch special
        return .lifetime
    }

    // MARK: - Keychain Management

    private func loadLicenseFromKeychain() {
        guard let key = getFromKeychain(key: licenseKeyKeychainKey),
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
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        SecItemAdd(query as CFDictionary, nil)
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
