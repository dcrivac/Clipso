//
//  RevenueCatManager.swift
//  Clipso
//
//  License and subscription management via RevenueCat and Apple IAP
//

import Foundation
import StoreKit
import RevenueCat

// MARK: - RevenueCat Manager
class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()

    @Published var isProUser: Bool = false
    @Published var licenseType: LicenseType = .free
    @Published var licenseEmail: String?
    @Published var isLoading: Bool = false
    @Published var customerInfo: CustomerInfo?
    @Published var availableProducts: [StoreProduct] = []

    // RevenueCat Configuration
    private let apiKey = "YOUR_REVENUECAT_API_KEY" // Replace with actual API key

    // App Store Connect Product IDs
    // Two pricing options: lifetime (one-time) or annual (recurring)
    private let lifetimeProductID = "com.clipso.lifetime"
    private let annualProductID = "com.clipso.annual"

    enum LicenseType: String, Codable {
        case free = "free"
        case lifetime = "lifetime"
        case annual = "annual"
    }

    enum LicenseError: Error {
        case purchaseFailed
        case validationFailed
        case networkError
        case productNotFound
    }

    private override init() {
        super.init()
        setupRevenueCat()
    }

    // MARK: - Setup & Initialization

    private func setupRevenueCat() {
        // Initialize RevenueCat with API key
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)

        // Listen for customer info updates
        Purchases.shared.customerInfoStream
            .sink { [weak self] customerInfo in
                Task { @MainActor in
                    self?.customerInfo = customerInfo
                    self?.updateProStatus()
                }
            }
            .store(in: &cancellables)

        // Fetch available products
        Task {
            await fetchAvailableProducts()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Methods

    /// Check if user has Pro features
    func hasProAccess() -> Bool {
        guard let customerInfo = customerInfo else { return false }
        return customerInfo.entitlements.active.keys.contains("pro")
    }

    /// Get the current license type based on active subscription
    func getCurrentLicenseType() -> LicenseType {
        guard let customerInfo = customerInfo else { return .free }

        // Check which product is active
        if let allEntitlements = customerInfo.entitlements.active.values.first {
            if allEntitlements.productIdentifier == lifetimeProductID {
                return .lifetime
            } else if allEntitlements.productIdentifier == annualProductID {
                return .annual
            }
        }

        return .free
    }

    /// Purchase a product
    func purchase(productID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let product = availableProducts.first(where: { $0.productIdentifier == productID }) else {
            throw LicenseError.productNotFound
        }

        do {
            let (transaction, customerInfo) = try await Purchases.shared.purchase(package: Package(storeProduct: product, presentedOfferingIdentifier: nil))

            // Verify the purchase was successful
            if customerInfo.entitlements.active.keys.contains("pro") {
                await MainActor.run {
                    self.customerInfo = customerInfo
                    self.updateProStatus()
                }
            }
        } catch {
            throw LicenseError.purchaseFailed
        }
    }

    /// Restore previous purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await MainActor.run {
                self.customerInfo = customerInfo
                self.updateProStatus()
            }
        } catch {
            throw LicenseError.validationFailed
        }
    }

    /// Get the current customer's email (for display purposes)
    func getCustomerEmail() -> String? {
        return Purchases.shared.appUserID
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

    // MARK: - Product Management

    func fetchAvailableProducts() async {
        do {
            let offerings = try await Purchases.shared.offerings()

            // Get current offering
            if let current = offerings.current {
                // Combine all products from all packages
                var products: [StoreProduct] = []
                for package in current.availablePackages {
                    products.append(package.storeProduct)
                }

                await MainActor.run {
                    self.availableProducts = products
                }
            }
        } catch {
            print("Error fetching offerings: \(error)")
        }
    }

    func getProduct(for productID: String) -> StoreProduct? {
        return availableProducts.first { $0.productIdentifier == productID }
    }

    func getProductPrice(for productID: String) -> String? {
        guard let product = getProduct(for: productID) else { return nil }
        return product.priceFormattedString
    }

    // MARK: - Private Methods

    private func updateProStatus() {
        isProUser = hasProAccess()
        licenseType = getCurrentLicenseType()
    }
}

// MARK: - Paywallable
extension RevenueCatManager {
    /// Get a formatted string for display
    func getLicenseStatusText() -> String {
        switch licenseType {
        case .free:
            return "Free Plan"
        case .lifetime:
            return "Lifetime Pro"
        case .annual:
            return "Annual Pro"
        case .monthly:
            return "Monthly Pro"
        }
    }
}
