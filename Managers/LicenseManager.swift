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
    private let vendorID = "YOUR_PADDLE_VENDOR_ID" // Replace with your Vendor ID from Paddle Dashboard
    private let lifetimePriceID = "pri_LIFETIME_PRICE_ID" // Price ID for Lifetime from Paddle
    private let annualPriceID = "pri_ANNUAL_PRICE_ID" // Price ID for Annual subscription from Paddle
    private let apiKey = "YOUR_PADDLE_API_KEY" // API Key from Paddle Developer Tools
    private let useSandbox = true // Set to false for production

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
        // Paddle checkout URL format
        let baseURL = useSandbox ? "https://sandbox-checkout.paddle.com" : "https://checkout.paddle.com"
        let checkoutURL = "\(baseURL)/checkout/custom/\(lifetimePriceID)"
        if let url = URL(string: checkoutURL) {
            NSWorkspace.shared.open(url)
        }
    }

    func purchaseAnnual() {
        // Paddle checkout URL format
        let baseURL = useSandbox ? "https://sandbox-checkout.paddle.com" : "https://checkout.paddle.com"
        let checkoutURL = "\(baseURL)/checkout/custom/\(annualPriceID)"
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

    private func validateLicenseWithPaddle(key: String) async throws -> (Bool, LicenseType) {
        // Paddle License Validation API
        // https://developer.paddle.com/api-reference/transactions/get-transaction
        // Note: This implementation validates using Paddle's transaction API
        // In production, you'd typically validate the license key using your backend

        let baseURL = useSandbox ? "https://sandbox-api.paddle.com" : "https://api.paddle.com"
        let urlString = "\(baseURL)/transactions"

        guard let url = URL(string: urlString) else {
            throw LicenseError.networkError
        }

        // Generate unique instance ID for device
        let instanceID = getDeviceInstanceID()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // In a real implementation, you would:
        // 1. Store transaction IDs with license keys in your backend
        // 2. Use Paddle's webhook to track purchases
        // 3. Validate license keys against your backend
        //
        // For now, we'll validate by checking if the key format is valid
        // and assume it's tied to a transaction you've stored

        // Simple format validation (Paddle transaction IDs typically start with "txn_")
        if !key.hasPrefix("txn_") && !key.contains("-") {
            throw LicenseError.invalidKey
        }

        // For a complete implementation, make an API call to your backend
        // that checks if this license key is valid and returns the subscription status
        // This is a simplified version for demonstration

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseError.networkError
        }

        // Check response status
        guard httpResponse.statusCode == 200 else {
            throw LicenseError.validationFailed
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]] else {
            throw LicenseError.validationFailed
        }

        // Find the transaction matching this license key
        guard let transaction = dataArray.first(where: { trans in
            if let transID = trans["id"] as? String {
                return transID == key || key.contains(transID)
            }
            return false
        }) else {
            throw LicenseError.validationFailed
        }

        // Extract subscription/product information
        guard let items = transaction["items"] as? [[String: Any]],
              let firstItem = items.first,
              let price = firstItem["price"] as? [String: Any],
              let priceID = price["id"] as? String else {
            throw LicenseError.validationFailed
        }

        // Determine license type from price ID
        let licenseType = determineLicenseTypeFromPriceID(priceID: priceID)

        return (true, licenseType)
    }

    private func determineLicenseTypeFromPriceID(priceID: String) -> LicenseType {
        // Match against configured price IDs
        if priceID == lifetimePriceID {
            return .lifetime
        } else if priceID == annualPriceID {
            return .annual
        }

        // Fallback to checking naming patterns
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
