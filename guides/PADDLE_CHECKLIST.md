# Paddle Setup Checklist for Clipso

## ✅ Completed

### Code Implementation
- ✅ Created `LicenseManager.swift` with:
  - License validation system
  - Keychain storage for license keys
  - Pro feature gating methods
  - Paddle checkout integration
  - License activation UI
  - Pro upgrade prompt UI

- ✅ Updated `script.js` with:
  - Paddle.js initialization
  - Checkout functions for Lifetime and Annual
  - Button event handlers

- ✅ Updated `index.html` with:
  - Paddle.js script tag
  - Freemium pricing section
  - Purchase CTAs

## 🔲 TODO: Paddle Account Setup

### Step 1: Create Paddle Account
1. Go to https://vendors.paddle.com/signup
2. Choose "Paddle Classic" (better for desktop software)
3. Fill in business information:
   - Business name
   - Email
   - Country
   - Tax information
4. Submit for verification
5. Wait 1-2 business days for approval

### Step 2: Get Approved
- Check email for approval notification
- Complete any additional verification steps
- Access your Paddle Dashboard

### Step 3: Create Products in Paddle

#### Product 1: Lifetime Pro (Launch Special)
1. Go to Catalog → Products → "+ New Product"
2. Fill in details:
   - **Product Name:** Clipso Pro - Lifetime License
   - **Description:** Lifetime access to all Pro features including AI semantic search and context detection
   - **Product Image:** Upload logo (use assets/logo.svg)
3. Pricing:
   - **Type:** One-time purchase
   - **Price:** $29.99 USD
   - **Recurring:** No
4. Save and note the **Product ID** (e.g., 123456)

#### Product 2: Annual Subscription
1. Create another product:
   - **Product Name:** Clipso Pro - Annual
   - **Description:** Annual subscription with all Pro features
   - **Product Image:** Upload logo
2. Pricing:
   - **Type:** Subscription
   - **Price:** $7.99 USD
   - **Billing Cycle:** Yearly
   - **Trial Period:** 7 days (optional)
3. Save and note the **Product ID** (e.g., 234567)

#### Product 3: Monthly Subscription (Optional)
1. Create product:
   - **Product Name:** Clipso Pro - Monthly
   - **Price:** $0.99 USD
   - **Billing Cycle:** Monthly
2. Save and note the **Product ID**

### Step 4: Get Your Credentials
1. Go to Developer Tools → Authentication
2. Copy your **Vendor ID** (e.g., 123456)
3. Generate **API Key** (for license validation)
4. Store these securely - DO NOT commit to git

### Step 5: Update Configuration Files

#### Update `script.js`:
```javascript
const PADDLE_VENDOR_ID = 'YOUR_ACTUAL_VENDOR_ID'; // Replace with real ID
const LIFETIME_PRODUCT_ID = 'YOUR_LIFETIME_PRODUCT_ID'; // Replace with real ID
const ANNUAL_PRODUCT_ID = 'YOUR_ANNUAL_PRODUCT_ID'; // Replace with real ID
```

#### Update `LicenseManager.swift`:
```swift
private let vendorID = "YOUR_ACTUAL_VENDOR_ID"
private let lifetimeProductID = "YOUR_LIFETIME_PRODUCT_ID"
private let annualProductID = "YOUR_ANNUAL_PRODUCT_ID"
```

### Step 6: Test in Sandbox
1. Go to https://sandbox-vendors.paddle.com
2. Create test products (same as above)
3. Get sandbox credentials
4. Update code to use sandbox:
   ```javascript
   Paddle.Environment.set('sandbox');
   ```
5. Test checkout flow end-to-end
6. Use test card: 4242 4242 4242 4242

### Step 7: Switch to Production
1. Update all Product IDs to production values
2. Change Paddle environment:
   ```javascript
   Paddle.Environment.set('production');
   ```
3. Test one real purchase (refund it after testing)
4. Monitor Paddle Dashboard for transactions

## 🔲 TODO: App Integration

### Add LicenseManager to Xcode Project
1. Open `Clipso.xcodeproj`
2. Add `LicenseManager.swift` to project:
   - Right-click project → Add Files
   - Select `LicenseManager.swift`
   - Ensure target is checked
3. Build to verify no errors

### Integrate Freemium Logic

#### Update ContentView to gate features:
```swift
@StateObject private var licenseManager = LicenseManager.shared

var body: some View {
    VStack {
        // Show Pro badge if licensed
        if licenseManager.isProUser {
            Text("Pro")
                .font(.caption)
                .padding(4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
        }

        // Existing UI...

        // Gate semantic search
        Toggle("Semantic Search", isOn: $enableSemanticSearch)
            .disabled(!licenseManager.canUseSemanticSearch())
            .onTapGesture {
                if !licenseManager.canUseSemanticSearch() {
                    showProUpgrade = true
                }
            }
    }
    .sheet(isPresented: $showProUpgrade) {
        ProUpgradePromptView(feature: "Semantic Search")
    }
}
```

#### Update SettingsManager:
```swift
func getMaxItems() -> Int {
    return LicenseManager.shared.getMaxItems()
}

func getMaxRetentionDays() -> Int {
    return LicenseManager.shared.getMaxRetentionDays()
}
```

#### Update ClipboardMonitor:
```swift
func clipboardChanged() {
    let maxItems = LicenseManager.shared.getMaxItems()

    // Enforce limit
    if allItems.count >= maxItems {
        // Show upgrade prompt
        showUpgradePrompt = true
        return
    }

    // Continue with capture...
}
```

### Add Settings Menu Item
```swift
// In AppDelegate
func applicationDidFinishLaunching(_ notification: Notification) {
    // Existing code...

    let menu = NSMenu()

    // Add License menu item
    if !LicenseManager.shared.isProUser {
        menu.addItem(NSMenuItem(title: "Upgrade to Pro...", action: #selector(showUpgrade), keyEquivalent: ""))
    } else {
        menu.addItem(NSMenuItem(title: "License: \(LicenseManager.shared.licenseType.rawValue.capitalized)", action: nil, keyEquivalent: ""))
    }

    menu.addItem(NSMenuItem(title: "Activate License...", action: #selector(showLicenseActivation), keyEquivalent: ""))

    // Existing menu items...
}

@objc func showUpgrade() {
    LicenseManager.shared.purchaseLifetime()
}

@objc func showLicenseActivation() {
    // Show LicenseActivationView
}
```

## 🔲 TODO: Testing

### End-to-End Test Flow
1. ✅ Fresh install (no license)
2. ✅ App shows Free tier (250 items limit)
3. ✅ Try to use AI search → shows upgrade prompt
4. ✅ Click "Get Pro" → opens Paddle checkout
5. ✅ Complete purchase in Paddle
6. ✅ Receive email with license key
7. ✅ Enter license in app
8. ✅ License validates successfully
9. ✅ Pro features unlock
10. ✅ AI search works
11. ✅ Unlimited items work
12. ✅ Restart app → license persists

### Edge Cases to Test
- Invalid license key
- Wrong email address
- Network failure during validation
- License revocation (refund)
- Multiple activations (if limiting)

## 🔲 TODO: Deployment

### Commit Changes
```bash
git add LicenseManager.swift PADDLE_SETUP.md PADDLE_CHECKLIST.md script.js index.html
git commit -m "Add Paddle payment integration and freemium licensing"
git push origin main
```

### Update GitHub Releases
1. Build app in Xcode (Release configuration)
2. Archive → Export
3. Create DMG installer
4. Create GitHub Release with license-enabled build
5. Update download links on landing page

### Go Live
1. Ensure Paddle is in production mode
2. Test one real purchase
3. Announce launch with pricing
4. Monitor sales and support emails

## 📊 Success Metrics

Track these in Paddle Dashboard:
- Conversion rate (free downloads → paid)
- Average order value
- Churn rate (for subscriptions)
- Refund rate
- Geographic sales distribution

## 🆘 Support

### Common Issues

**"Paddle is not defined" error:**
- Ensure Paddle.js script is loading
- Check browser console for errors
- Verify vendor ID is correct

**License validation fails:**
- Check network connection
- Verify API credentials
- Check Paddle API status

**Checkout doesn't open:**
- Check product ID is correct
- Verify Paddle.Environment matches (sandbox/production)
- Check browser console

### Resources
- Paddle Documentation: https://developer.paddle.com
- Paddle Support: vendors@paddle.com
- Paddle Community: https://paddle.com/community

## Next Steps

1. ⏰ **Today:** Create Paddle account
2. ⏰ **Day 2-3:** Wait for approval, create products
3. ⏰ **Day 4:** Update configuration with real IDs
4. ⏰ **Day 5:** Integrate license gating in app
5. ⏰ **Day 6:** End-to-end testing
6. ⏰ **Day 7:** Launch! 🚀
