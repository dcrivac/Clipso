# RevenueCat Setup Guide for Clipso

This guide walks through setting up RevenueCat + Apple In-App Purchases for Clipso, replacing the previous Paddle integration.

## Overview

The new monetization system uses:
- **RevenueCat SDK**: Handles subscription/purchase management
- **Apple In-App Purchases (IAP)**: Direct payment processing outside the App Store
- **StoreKit2**: Apple's modern framework for in-app purchases
- **macOS app distribution**: Direct app distribution (not through Mac App Store)

## Step 1: Set Up App Store Connect (Apple Developer Account)

### 1.1 Create a Bundle ID
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple Developer account
3. Go to **Certificates, Identifiers & Profiles** → **Identifiers**
4. Click **+** to create new identifier
5. Choose **App IDs** → **App**
6. Enter:
   - **App Name**: Clipso
   - **Bundle ID**: `com.clipso` (matches `Clipso.xcodeproj`)
7. Enable **In-App Purchase** capability
8. Click **Continue** → **Register**

### 1.2 Configure In-App Purchase Products

In App Store Connect:

1. Go to **My Apps** → **Clipso** (or create if new)
2. Navigate to **In-App Purchases**
3. Create **Lifetime Purchase**:
   - **Reference Name**: Lifetime Pro
   - **Product ID**: `com.clipso.lifetime` (must match RevenueCatManager)
   - **Type**: Non-Consumable
   - **Price Tier**: $29.99
   - **Localized Details**: "Unlock all Pro features forever with a one-time payment"

4. Create **Annual Subscription**:
   - **Reference Name**: Annual Pro Subscription
   - **Product ID**: `com.clipso.annual` (must match RevenueCatManager)
   - **Type**: Auto-Renewable Subscription
   - **Billing Period**: 1 Year
   - **Price Tier**: $7.99
   - **Renewal Terms**: Auto-renew enabled
   - **Localized Details**: "Unlock all Pro features. Renews annually."

5. **Important**: Add your banking information to receive payments

### 1.3 Create a Sandbox Apple ID (for testing)
1. Go to **Users and Access** → **Sandbox**
2. Click **+** under "Sandbox Testers"
3. Create a test Apple ID (use a fake email you can access)
4. Save for later testing

## Step 2: Set Up RevenueCat

### 2.1 Create RevenueCat Account
1. Go to [revenuecat.com](https://revenuecat.com)
2. Sign up for a free account
3. Create a new **Project** named "Clipso"

### 2.2 Configure Apple IAP in RevenueCat
1. Go to **Project Settings** → **Products**
2. Add your in-app purchase products:
   - Import from App Store Connect, OR manually add:
     - **com.clipso.lifetime** (Lifetime)
     - **com.clipso.annual** (Annual)
3. Go to **Entitlements** and create an entitlement named **"pro"**
4. Map products to the "pro" entitlement:
   - Both `com.clipso.lifetime` and `com.clipso.annual` grant "pro" access

### 2.3 Get Your RevenueCat API Key
1. Go to **Project Settings** → **API Keys**
2. Copy your **Public API Key** (starts with `pk_`)
3. Store this safely - you'll need it for the app

## Step 3: Update Clipso Code

### 3.1 Add RevenueCat SDK via SPM

In Xcode:
1. **File** → **Add Packages**
2. Enter: `https://github.com/RevenueCat/purchases-ios.git`
3. Select version: **Latest** or **4.0.0+**
4. Choose target: **Clipso**
5. Click **Add Package**

Alternatively, edit `project.pbxproj` directly if using Command Line.

### 3.2 Update RevenueCatManager.swift

Replace `YOUR_REVENUECAT_API_KEY` in `Clipso/Managers/RevenueCatManager.swift`:

```swift
private let apiKey = "pk_your_actual_api_key_here" // Replace with real key
```

### 3.3 Update Info.plist

Add RevenueCat configuration to `Clipso/Info.plist`:

```xml
<dict>
    <!-- Existing permissions -->
    <key>NSAppleEventsUsageDescription</key>
    <string>Monitor clipboard changes for clipboard history</string>

    <key>NSAccessibilityUsageDescription</key>
    <string>Detect active application for context detection</string>

    <!-- RevenueCat Configuration -->
    <key>RevenueCat</key>
    <dict>
        <key>APIKey</key>
        <string>pk_your_actual_api_key_here</string>
    </dict>
</dict>
```

## Step 4: Configure Xcode Project

### 4.1 Update Bundle Identifier
1. Open **Clipso.xcodeproj** in Xcode
2. Select **Clipso** target
3. Go to **General** → **Identity**
4. Set **Bundle Identifier**: `com.clipso`
5. Set **Team** to your Apple Developer team
6. Set **Development Team**

### 4.2 Add Signing Capabilities
1. Select **Clipso** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Search for and add:
   - **In-App Purchase**
   - **StoreKit Configuration** (for testing)

### 4.3 Create StoreKit Configuration for Testing (Optional)
1. **File** → **New** → **StoreKit Configuration**
2. Name: `StoreKit.storekit`
3. Add products matching your App Store Connect setup:
   - `com.clipso.lifetime` - Lifetime ($29.99)
   - `com.clipso.annual` - Annual ($7.99/year)
4. In Xcode scheme settings, select this configuration for testing

## Step 5: Code Changes Summary

The following changes have been made:

### New Files
- **RevenueCatManager.swift** - Manages subscriptions and entitlements
- **RevenueCatPaywallView.swift** - Modern paywall UI

### Modified Files
- **SettingsView.swift** - Updated to use RevenueCatManager
- **ClipsoApp.swift** - Initialize RevenueCat on app launch
- **Removed**: Old Paddle license activation view (LicenseManager.swift still exists for backward compatibility)

### Key Differences from Paddle
| Feature | Paddle | RevenueCat |
|---------|--------|-----------|
| License Activation | Manual key entry | Automatic via Apple ID |
| Payment Provider | Paddle | Apple (direct) |
| License Check | Keychain storage | RevenueCat backend |
| Purchase Flow | External browser | Native App Store UI |
| Restore Purchases | Manual activation | One-tap restore |

## Step 6: Testing

### 6.1 Local Testing with StoreKit Configuration
1. Run the app with StoreKit configuration active
2. Click **"Upgrade to Pro"** in the menu bar
3. Select a product and click **"Purchase"**
4. In the sandbox payment popup, use the test Apple ID created earlier
5. Verify license changes show in settings

### 6.2 Testing with Sandbox Account
1. Build and sign the app
2. Open System Preferences → **Users & Groups**
3. Log out of the current Apple ID
4. Sign in with your sandbox test Apple ID
5. Run Clipso and test purchases

## Step 7: Production Deployment

### 7.1 Sign the App
```bash
codesign --force --deep --sign "Developer ID Application: Your Name" /path/to/Clipso.app
```

### 7.2 Notarize (Required for macOS)
```bash
xcrun notarytool submit /path/to/Clipso.zip \
  --apple-id "your-apple-id@example.com" \
  --password "app-specific-password" \
  --team-id "YOUR_TEAM_ID"
```

### 7.3 Distribute
- Create DMG or ZIP for distribution
- Post to your website
- Include changelog mentioning new RevenueCat integration

## Troubleshooting

### Issue: "Product not found" error
**Solution**: Verify product IDs match exactly in:
- App Store Connect
- RevenueCat dashboard
- RevenueCatManager.swift

### Issue: Purchase fails with network error
**Solution**:
1. Check API key is correct
2. Verify sandbox account is logged in (if testing)
3. Check RevenueCat status page for outages

### Issue: License not activating after purchase
**Solution**:
1. Verify entitlement name is "pro" in RevenueCat
2. Check that both products are mapped to "pro" entitlement
3. Try "Restore Purchases" from menu bar

### Issue: Can't access RevenueCat SDK
**Solution**:
1. Verify SPM package is installed: **File** → **Packages** → **Resolve Package Versions**
2. Check target membership: Select RevenueCat package → **Target Membership** includes Clipso

## File Reference

| File | Purpose |
|------|---------|
| `Managers/RevenueCatManager.swift` | Core subscription logic |
| `Views/RevenueCatPaywallView.swift` | Purchase UI |
| `ClipsoApp.swift` | RevenueCat initialization |
| `REVENUECAT_SETUP_GUIDE.md` | This guide |

## Next Steps

1. Complete Steps 1-4 above
2. Replace `YOUR_REVENUECAT_API_KEY` with your actual key
3. Test locally with StoreKit configuration
4. Test with sandbox Apple ID
5. Deploy production app with notarization

## Support

For issues:
- **RevenueCat**: [docs.revenuecat.com](https://docs.revenuecat.com)
- **Apple IAP**: [developer.apple.com/in-app-purchase](https://developer.apple.com/in-app-purchase)
- **macOS Code Signing**: [developer.apple.com/macos](https://developer.apple.com/macos)
