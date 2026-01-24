//
//  PaddleConfig.swift
//  ClipboardManager
//
//  Paddle configuration separated from main code for security
//

import Foundation

struct PaddleConfig {
    // MARK: - Configuration Loading

    /// Load Paddle configuration from environment or plist
    /// In production, use build configurations or environment variables
    static func loadConfig() -> PaddleEnvironment {
        #if DEBUG
        // In debug builds, use sandbox by default
        return loadFromPlist() ?? .sandbox
        #else
        // In release builds, use production
        return loadFromPlist() ?? .production
        #endif
    }

    /// Load configuration from Info.plist
    /// Add these keys to your Info.plist:
    /// - PADDLE_VENDOR_ID
    /// - PADDLE_LIFETIME_PRICE_ID
    /// - PADDLE_ANNUAL_PRICE_ID
    /// - PADDLE_API_KEY
    /// - PADDLE_USE_SANDBOX
    private static func loadFromPlist() -> PaddleEnvironment? {
        guard let infoPlist = Bundle.main.infoDictionary else {
            return nil
        }

        guard let vendorID = infoPlist["PADDLE_VENDOR_ID"] as? String,
              let lifetimePriceID = infoPlist["PADDLE_LIFETIME_PRICE_ID"] as? String,
              let annualPriceID = infoPlist["PADDLE_ANNUAL_PRICE_ID"] as? String else {
            return nil
        }

        let apiKey = infoPlist["PADDLE_API_KEY"] as? String ?? ""
        let useSandbox = infoPlist["PADDLE_USE_SANDBOX"] as? Bool ?? true

        return PaddleEnvironment(
            vendorID: vendorID,
            lifetimePriceID: lifetimePriceID,
            annualPriceID: annualPriceID,
            apiKey: apiKey,
            useSandbox: useSandbox
        )
    }

    // MARK: - Environment Presets

    /// Sandbox environment for testing
    /// Note: These are PUBLIC client-side tokens, not secret
    /// Store API keys in Info.plist or environment variables
    static var sandbox: PaddleEnvironment {
        PaddleEnvironment(
            vendorID: "test_859aa26dd9d5c623ccccf54e0c7",
            lifetimePriceID: "pri_01kfr145r1eh8f7m8w0nfkvz74uf", // Lifetime: one-time $29.99
            annualPriceID: "pri_01kfr12rgvdnhpr52zspmqvnk1", // Annual: $7.99/year subscription
            apiKey: "", // API key should be loaded from secure source
            useSandbox: true
        )
    }

    /// Production environment
    /// Note: Update these when ready to go live
    static var production: PaddleEnvironment {
        PaddleEnvironment(
            vendorID: "live_fc98babc1d8bb9e39a3482fd2bc",
            lifetimePriceID: "pri_01kfqf40kc2jn9cgx9a6naenk7", // Lifetime: one-time $29.99
            annualPriceID: "pri_01kfqf26bqncwbr7nvrg445esy", // Annual: $7.99/year subscription
            apiKey: "", // API key should be loaded from secure source
            useSandbox: false
        )
    }
}

// MARK: - Environment Model

struct PaddleEnvironment {
    let vendorID: String
    let lifetimePriceID: String
    let annualPriceID: String
    let apiKey: String
    let useSandbox: Bool

    var baseURL: String {
        useSandbox ? "https://sandbox-api.paddle.com" : "https://api.paddle.com"
    }

    var checkoutBaseURL: String {
        useSandbox ? "https://sandbox-checkout.paddle.com" : "https://checkout.paddle.com"
    }
}
