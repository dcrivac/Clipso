# Lemon Squeezy Product Setup - Complete Assets Guide

## Overview

This guide covers all assets, files, and configuration needed to set up your Clipso products in Lemon Squeezy.

---

## Product Images

### Required Images

For each product (Lifetime, Annual, Monthly), you'll need:

#### 1. Product Card Image
- **Size:** 1200x630px (recommended)
- **Format:** PNG or JPG
- **Purpose:** Displays in checkout, emails, and product listings
- **Design suggestion:**
  - Clipso logo
  - Product name (e.g., "Clipso Pro - Lifetime")
  - Key feature highlights
  - Clean, professional design

#### 2. Product Thumbnail (Optional)
- **Size:** 400x400px
- **Format:** PNG (transparent background recommended)
- **Purpose:** Small icon in product lists
- **Design suggestion:** Just the Clipso logo/icon

#### 3. Checkout Banner (Optional)
- **Size:** 1920x400px
- **Format:** PNG or JPG
- **Purpose:** Header image in checkout overlay
- **Design suggestion:** Branded banner with tagline

### Where to Create Images

**Option 1: Use Existing Assets**
You already have these in your repo:
- `assets/banner.svg` - Use for product banner
- `assets/screenshot-hero.svg` - Use for product card
- App icon from Xcode project

**Option 2: Create New Images**
Tools you can use:
- Figma (https://figma.com) - Free
- Canva (https://canva.com) - Free templates
- Sketch or Adobe Illustrator

**Quick Image Creation:**
I can help you create simple product images using your existing assets.

---

## Product Files (Downloads)

### What You Need to Upload

For Lemon Squeezy, you have several options for delivering the app:

#### Option 1: Direct DMG Download (Recommended)
- **File:** Clipso.dmg (your built app)
- **Upload to:** Lemon Squeezy → Product → Files
- **How customers get it:** Automatic download link after purchase

**To create DMG:**
```bash
# Use your existing script
./create-dmg.sh

# Or manually in Xcode:
# 1. Archive the app (Product → Archive)
# 2. Export as macOS app
# 3. Create DMG with Disk Utility
```

#### Option 2: GitHub Releases Link
- **File:** None uploaded to Lemon Squeezy
- **Instead:** Provide GitHub release URL
- **Setup in Lemon Squeezy:**
  - Product → Files → Add external link
  - URL: `https://github.com/dcrivac/Clipso/releases/latest`
  - Customers get link in purchase email

#### Option 3: Both DMG + GitHub Link
- Upload DMG for immediate download
- Also include GitHub link for updates
- Best user experience

### File Configuration in Lemon Squeezy

```
Product → Files Section:

[Primary Download]
- File name: Clipso-1.0.0.dmg
- File size: ~15-30MB (approximate)
- Description: "Clipso for macOS 13.0+"

[Additional Links]
- GitHub Releases: https://github.com/dcrivac/Clipso/releases
- Documentation: https://github.com/dcrivac/Clipso#readme
- Support: https://github.com/dcrivac/Clipso/issues
```

---

## Product Links

### Links to Configure in Each Product

#### 1. Download Links
```
Primary Download: Direct DMG or GitHub release
Format: https://github.com/dcrivac/Clipso/releases/download/v1.0.0/Clipso.dmg
```

#### 2. Documentation Links
```
Getting Started: https://github.com/dcrivac/Clipso#getting-started
User Guide: https://github.com/dcrivac/Clipso#readme
FAQ: https://github.com/dcrivac/Clipso#faq
```

#### 3. Support Links
```
GitHub Issues: https://github.com/dcrivac/Clipso/issues
Email Support: Your support email
Discord/Slack: (if you have a community)
```

#### 4. Legal Links (Required)
```
Terms of Service: https://dcrivac.github.io/Clipso/terms.html
Privacy Policy: https://dcrivac.github.io/Clipso/privacy-policy.html
Refund Policy: https://dcrivac.github.io/Clipso/refund-policy.html
```

You already have these files:
- ✅ `terms.html`
- ✅ `privacy-policy.html`
- ✅ `refund-policy.html`

Just make sure they're deployed to GitHub Pages!

#### 5. Website/Landing Page
```
Product Website: https://dcrivac.github.io/Clipso/
GitHub Repo: https://github.com/dcrivac/Clipso
```

---

## Product Variants

### What Are Variants?

Variants are different versions/options of the same product. For Clipso, you might use:

### Recommended Variant Strategy

#### Product 1: Clipso Pro (with variants)
Create ONE product with 3 variants:

**Variant 1: Lifetime License**
- Name: "Lifetime - $29.99"
- Price: $29.99 (one-time)
- Billing: Single payment
- License: Yes, 2 activations
- Description: "Pay once, use forever"

**Variant 2: Annual Subscription**
- Name: "Annual - $7.99/year"
- Price: $7.99/year
- Billing: Yearly subscription
- License: Yes, 2 activations (follows subscription)
- Description: "Billed annually, cancel anytime"

**Variant 3: Monthly Subscription**
- Name: "Monthly - $0.99/month"
- Price: $0.99/month
- Billing: Monthly subscription
- License: Yes, 2 activations (follows subscription)
- Description: "Billed monthly, cancel anytime"

### Alternative: Separate Products

Or create 3 separate products (simpler):

1. **Clipso Pro - Lifetime**
2. **Clipso Pro - Annual**
3. **Clipso Pro - Monthly**

**Recommended:** Use variants (easier management, single product page)

---

## Complete Product Configuration

### Product 1: Clipso Pro - Lifetime

```yaml
Basic Information:
  Name: "Clipso Pro - Lifetime License"
  Description: |
    Unlock the full power of Clipso with a one-time purchase.

    ✨ Unlimited AI semantic search
    🎯 Automatic context detection
    ♾️ Unlimited clipboard history
    🔒 100% private, local processing
    💾 iCloud sync (E2E encrypted)
    ⚡ Priority support
    🚀 All future updates included

  Price: $29.99
  Type: Single payment
  Currency: USD

Product Media:
  Card Image: [Upload Clipso-Product-Card.png - 1200x630]
  Thumbnail: [Upload Clipso-Icon.png - 400x400]

Files & Downloads:
  Primary File: Clipso-1.0.0.dmg (or GitHub link)
  Additional Links:
    - Documentation: https://github.com/dcrivac/Clipso#readme
    - GitHub: https://github.com/dcrivac/Clipso
    - Support: https://github.com/dcrivac/Clipso/issues

License Keys:
  ✅ Enable license keys
  Activation limit: 2 devices
  Expires: Never
  Format: Auto-generated

Checkout Settings:
  Success URL: https://dcrivac.github.io/Clipso/?purchase=success
  Button text: "Get Lifetime Access"

Email Settings:
  Purchase confirmation: Enabled
  License key delivery: Enabled
  Receipt: Enabled

Legal:
  Terms URL: https://dcrivac.github.io/Clipso/terms.html
  Privacy URL: https://dcrivac.github.io/Clipso/privacy-policy.html
  Refund policy: 30-day money-back guarantee
```

### Product 2: Clipso Pro - Annual

```yaml
Basic Information:
  Name: "Clipso Pro - Annual Subscription"
  Description: |
    All Pro features for just $7.99/year.

    ✨ Unlimited AI semantic search
    🎯 Automatic context detection
    ♾️ Unlimited clipboard history
    🔒 100% private, local processing
    💾 iCloud sync (E2E encrypted)
    ⚡ Priority support

    Cancel anytime. 47% cheaper than competitors.

  Price: $7.99/year
  Type: Subscription
  Billing interval: Yearly
  Currency: USD

Subscription Settings:
  Trial period: 14 days (optional)
  Renewal: Automatic
  Cancellation: Anytime
  Proration: Enabled

Product Media:
  Card Image: [Upload Clipso-Annual-Card.png - 1200x630]
  Thumbnail: [Upload Clipso-Icon.png - 400x400]

Files & Downloads:
  Primary File: Clipso-1.0.0.dmg (or GitHub link)
  Additional Links:
    - Documentation: https://github.com/dcrivac/Clipso#readme

License Keys:
  ✅ Enable license keys
  Activation limit: 2 devices
  Expires: Follows subscription
  Deactivate on cancel: Yes

Checkout Settings:
  Success URL: https://dcrivac.github.io/Clipso/?purchase=success
  Button text: "Start Annual Subscription"
```

---

## Asset Checklist

Before setting up products in Lemon Squeezy, prepare:

### Images
- [ ] Product card image (1200x630px)
- [ ] Product thumbnail/icon (400x400px)
- [ ] Checkout banner (optional, 1920x400px)

### Files
- [ ] Clipso.dmg (built app) OR
- [ ] GitHub release URL
- [ ] README/Documentation
- [ ] License key instructions

### Links
- [ ] Landing page (https://dcrivac.github.io/Clipso/)
- [ ] GitHub repo (https://github.com/dcrivac/Clipso)
- [ ] Terms of Service URL
- [ ] Privacy Policy URL
- [ ] Refund Policy URL
- [ ] Support/Contact URL

### Copy/Text
- [ ] Product descriptions (for each variant)
- [ ] Feature lists
- [ ] Email templates (purchase confirmation)
- [ ] License activation instructions

### Legal
- [ ] Terms of Service (✅ Already have)
- [ ] Privacy Policy (✅ Already have)
- [ ] Refund Policy (✅ Already have)

---

## Quick Setup Steps

### Step 1: Prepare Images
```bash
# From your assets folder
# You have: banner.svg, screenshot-hero.svg
# Convert to PNG if needed:
# Use online tool or export from Sketch/Figma
```

### Step 2: Build App DMG
```bash
cd /Users/crivac/projects/Clipso
./create-dmg.sh

# Or use Xcode Archive
```

### Step 3: Deploy Legal Pages
```bash
# Make sure GitHub Pages is enabled
# Your pages should be accessible at:
# https://dcrivac.github.io/Clipso/terms.html
# https://dcrivac.github.io/Clipso/privacy-policy.html
```

### Step 4: Create Products in Lemon Squeezy
1. Go to Products → New Product
2. Fill in name, price, description
3. Upload product card image
4. Add DMG file or GitHub link
5. Enable license keys
6. Configure checkout settings
7. Add legal URLs
8. Publish!

---

## Example Product Descriptions

### Lifetime License
```
Clipso Pro - Lifetime License

Get lifetime access to all Pro features with a single payment.

What's Included:
• Unlimited AI-powered semantic search
• Automatic context detection and organization
• Unlimited clipboard history (no 250-item limit)
• Unlimited retention (no 30-day limit)
• End-to-end encrypted iCloud sync
• Priority email support
• All future updates and features

Perfect for power users who want the best value.

One-time payment. No subscriptions. Yours forever.

System Requirements:
• macOS 13.0 or later
• 50MB disk space

After purchase, you'll receive:
• Download link for Clipso.dmg
• License key for activation
• Getting started guide
```

### Annual Subscription
```
Clipso Pro - Annual Subscription

Unlock all Pro features for just $7.99/year. 47% less than competitors.

What's Included:
• Everything in the Free plan, plus:
• Unlimited AI semantic search (vs 10/day free limit)
• Automatic context detection
• Unlimited clipboard items
• Unlimited retention period
• Advanced search filters
• Priority support

Cancel anytime. No long-term commitment.

Try free for 14 days. No credit card required for trial.

After purchase, you'll receive your license key instantly.
```

---

## Image Templates (Descriptions)

If you want me to help create simple product images, here's what they should contain:

### Lifetime Product Card (1200x630)
```
Background: Gradient (Indigo #6366F1 → Purple #8B5CF6)
Logo: Clipso icon (top-left)
Main Text: "Clipso Pro"
Subtitle: "Lifetime License"
Price: "$29.99" (large, bold)
Tagline: "Pay once. Use forever."
Features (icons):
  • AI Search
  • Unlimited History
  • 100% Private
```

### Annual Product Card (1200x630)
```
Background: Gradient (Blue → Cyan)
Logo: Clipso icon
Main Text: "Clipso Pro"
Subtitle: "Annual Subscription"
Price: "$7.99/year"
Tagline: "47% less than competitors"
Badge: "14-day free trial"
```

---

## Need Help Creating Images?

I can help you:
1. Generate HTML/CSS templates for product cards
2. Convert your SVG assets to PNG
3. Create simple designs using your existing assets

Just let me know what you need!

---

## Resources

- **Lemon Squeezy Product Setup:** https://docs.lemonsqueezy.com/help/products
- **Checkout Customization:** https://docs.lemonsqueezy.com/help/checkout
- **License Keys Guide:** https://docs.lemonsqueezy.com/help/licensing
- **Your Existing Assets:** `/Users/crivac/projects/Clipso/assets/`
