# Lemon Squeezy Product Setup - Quick Checklist

## What You Need (Quick Reference)

### ✅ Images (Use Your Existing Assets!)

You already have great SVG assets in `/assets/`. Use these:

#### For Product Cards (1200x630px):
- **Lifetime Pro**: Use `social-card.svg` or `social-pricing-comparison.svg`
- **Annual Pro**: Use `social-privacy-first.svg`
- **Monthly Pro**: Use `social-twitter-semantic-search.svg`

#### For Thumbnails (400x400px):
- Use `logo.svg` - your Clipso logo

#### For Banners (optional):
- Use `banner.svg`

**Convert to PNG:**
```bash
# Run this script to convert all SVGs to PNGs automatically:
./create-product-images.sh

# Or use online converter:
# https://cloudconvert.com/svg-to-png
```

---

### ✅ Files to Upload

#### Option 1: GitHub Release (Easiest)
No file upload needed! Just provide:
- **URL**: `https://github.com/dcrivac/Clipso/releases/latest`
- Customers get link after purchase

#### Option 2: Direct DMG Upload
Build your app DMG:
```bash
# If you have the script:
./create-dmg.sh

# Or manually:
# 1. Xcode → Product → Archive
# 2. Export as macOS app
# 3. Create DMG
```

---

### ✅ Links to Configure

| Link Type | URL | Status |
|-----------|-----|--------|
| Landing Page | https://dcrivac.github.io/Clipso/ | ✅ Ready |
| GitHub Repo | https://github.com/dcrivac/Clipso | ✅ Ready |
| Terms of Service | https://dcrivac.github.io/Clipso/terms.html | ✅ Have file |
| Privacy Policy | https://dcrivac.github.io/Clipso/privacy-policy.html | ✅ Have file |
| Refund Policy | https://dcrivac.github.io/Clipso/refund-policy.html | ✅ Have file |
| Support/Issues | https://github.com/dcrivac/Clipso/issues | ✅ Ready |
| Documentation | https://github.com/dcrivac/Clipso#readme | ✅ Ready |

**Action needed:** Make sure GitHub Pages is enabled to serve the HTML files!

---

### ✅ Variants Configuration

**Recommended Setup: 1 Product with 3 Variants**

#### Product: "Clipso Pro"

**Variant 1: Lifetime**
- Price: $29.99 (one-time)
- Billing: Single payment
- License: Yes, 2 activations, never expires

**Variant 2: Annual**
- Price: $7.99/year
- Billing: Yearly subscription
- License: Yes, 2 activations, expires with subscription

**Variant 3: Monthly** (Optional)
- Price: $0.99/month
- Billing: Monthly subscription
- License: Yes, 2 activations, expires with subscription

---

## Step-by-Step Setup in Lemon Squeezy

### Step 1: Create Product

1. Go to **Products** → **New Product**
2. Fill in:
   - **Name**: "Clipso Pro"
   - **Description**: (see template below)
   - **Price**: $29.99 (you'll add variants next)

### Step 2: Add Product Images

1. Upload **Product Card** (1200x630):
   - Use: `product-images/clipso-product-card.png`

2. Upload **Thumbnail** (400x400):
   - Use: `product-images/clipso-thumbnail.png`

### Step 3: Add Files/Downloads

Choose one:

**Option A: GitHub Link**
- Click "Add external link"
- URL: `https://github.com/dcrivac/Clipso/releases/latest`
- Label: "Download Clipso for macOS"

**Option B: Direct Upload**
- Upload `Clipso.dmg`
- File name: `Clipso-1.0.0.dmg`

### Step 4: Enable License Keys

1. Scroll to **License Keys**
2. Toggle **Enable license keys** ON
3. Configure:
   - **Activation limit**: 2 devices
   - **Expires**: Never (for lifetime) / Follows subscription (for annual/monthly)

### Step 5: Add Variants

1. Click **Add variant**
2. Create 3 variants:

**Lifetime Variant**
- Name: "Lifetime - $29.99"
- Price: $29.99
- Billing: One-time
- Description: "Pay once, use forever"

**Annual Variant**
- Name: "Annual - $7.99/year"
- Price: $7.99
- Billing: Every 1 year
- Trial: 14 days (optional)
- Description: "Cancel anytime"

**Monthly Variant** (optional)
- Name: "Monthly - $0.99/month"
- Price: $0.99
- Billing: Every 1 month
- Trial: 7 days (optional)
- Description: "Flexible monthly billing"

### Step 6: Configure Checkout

1. Scroll to **Checkout settings**
2. Fill in:
   - **Success URL**: `https://dcrivac.github.io/Clipso/?purchase=success`
   - **Button text**: "Get Clipso Pro"

### Step 7: Add Legal Links

1. Scroll to **Legal**
2. Add URLs:
   - **Terms**: `https://dcrivac.github.io/Clipso/terms.html`
   - **Privacy**: `https://dcrivac.github.io/Clipso/privacy-policy.html`

### Step 8: Publish Product

1. Click **Save**
2. Click **Publish**
3. Copy **Product ID** and **Variant IDs**

---

## Product Description Template

### For Lemon Squeezy Product Page

```markdown
# Clipso Pro - Intelligent Clipboard for Mac

The first truly intelligent clipboard manager with AI-powered semantic search and automatic context detection.

## What's Included

✨ **Unlimited AI Semantic Search**
Find clipboard items by meaning, not just keywords

🎯 **Automatic Context Detection**
Organizes your clipboard into projects automatically

♾️ **Unlimited Clipboard History**
No 250-item limit. Store as much as you need.

⏰ **Unlimited Retention**
No 30-day limit. Keep items forever.

🔒 **100% Private & Local**
All processing happens on your Mac. Zero cloud sync.

💾 **iCloud Sync** (Coming Soon)
End-to-end encrypted sync across your devices

⚡ **Priority Support**
Get help directly from the developer

🚀 **All Future Updates**
Included with your purchase

## System Requirements

- macOS 13.0 or later
- 50MB disk space
- No internet required (works 100% offline)

## What Happens After Purchase?

1. ✅ Instant email with your license key
2. ✅ Download link for Clipso.dmg
3. ✅ Activation instructions
4. ✅ Getting started guide

## Questions?

- 📖 [Read Documentation](https://github.com/dcrivac/Clipso#readme)
- 🐛 [Get Support](https://github.com/dcrivac/Clipso/issues)
- 💬 [Contact Developer](mailto:your@email.com)

## Money-Back Guarantee

Try Clipso risk-free with our 30-day money-back guarantee. If you're not satisfied, we'll refund you—no questions asked.

---

**Pay once. Use forever. No subscriptions required.**
```

---

## After Product Creation

### Get These IDs:

Once you create the product and variants, copy these IDs:

```bash
# From Lemon Squeezy dashboard
STORE_ID: __________
PRODUCT_ID: __________

# Variant IDs:
LIFETIME_VARIANT_ID: __________
ANNUAL_VARIANT_ID: __________
MONTHLY_VARIANT_ID: __________

# API Key (Settings → API):
API_KEY: lsk_________________
```

### Update Your Code:

**In `Clipso/Managers/LicenseManager.swift`:**
```swift
private let storeID = "YOUR_STORE_ID"
private let lifetimeProductID = "YOUR_LIFETIME_VARIANT_ID"
private let annualProductID = "YOUR_ANNUAL_VARIANT_ID"
private let apiKey = "YOUR_API_KEY"
```

**In `script.js`:**
```javascript
const LEMONSQUEEZY_STORE_ID = 'YOUR_STORE_ID';
const LIFETIME_PRODUCT_ID = 'YOUR_LIFETIME_VARIANT_ID';
const ANNUAL_PRODUCT_ID = 'YOUR_ANNUAL_VARIANT_ID';
```

---

## Quick Start Commands

```bash
# 1. Convert SVG assets to PNG
./create-product-images.sh

# 2. Check GitHub Pages is enabled
# Go to: https://github.com/dcrivac/Clipso/settings/pages

# 3. Build app (if uploading DMG)
xcodebuild -project Clipso.xcodeproj -scheme Clipso -configuration Release

# 4. Create DMG
./create-dmg.sh
```

---

## Resources

- **Full Setup Guide**: `LEMONSQUEEZY_SETUP.md`
- **Assets Guide**: `LEMONSQUEEZY_PRODUCT_ASSETS.md`
- **Quick Start**: `LEMONSQUEEZY_QUICKSTART.md`
- **Lemon Squeezy Docs**: https://docs.lemonsqueezy.com

---

## Need Help?

Check the detailed guides or ask questions!

**You have everything you need already! Just need to:**
1. ✅ Convert images (run `./create-product-images.sh`)
2. ✅ Set up products in Lemon Squeezy
3. ✅ Copy the IDs back to your code
4. ✅ Test and launch! 🚀
