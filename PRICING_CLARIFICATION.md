# Clipso Pricing Structure Clarification

## Overview

This document clarifies the pricing structure for Clipso Pro and resolves the confusing "Yearly/Lifetime" naming.

## Pricing Tiers

### 1. **Lifetime License** (One-Time Payment)
- **Price**: $29.99 USD
- **Payment Type**: One-time purchase
- **Duration**: Lifetime access (never expires)
- **Best For**: Users who want permanent access with a single payment
- **Paddle Price ID (Sandbox)**: `pri_01kfr145r1eh8f7m8w0nfkvz74uf`
- **Paddle Price ID (Live)**: `pri_01kfqf40kc2jn9cgx9a6naenk7`

**What you get:**
- ✅ All Pro features forever
- ✅ All future updates included
- ✅ No recurring payments
- ✅ Activate on up to 3 devices

### 2. **Annual Subscription** (Recurring)
- **Price**: $7.99 USD per year
- **Payment Type**: Recurring yearly subscription
- **Duration**: Renews annually until cancelled
- **Best For**: Users who prefer lower upfront cost or want to try Pro long-term
- **Paddle Price ID (Sandbox)**: `pri_01kfr12rgvdnhpr52zspmqvnk1`
- **Paddle Price ID (Live)**: `pri_01kfqf26bqncwbr7nvrg445esy`

**What you get:**
- ✅ All Pro features for 1 year
- ✅ Automatically renews at $7.99/year
- ✅ Cancel anytime (access until end of billing period)
- ✅ Activate on up to 3 devices

### 3. **Free Tier**
- **Price**: $0
- **Limitations**:
  - ❌ No semantic search
  - ❌ No context detection
  - ⚠️ Maximum 250 items
  - ⚠️ 30-day retention limit

## Naming Convention Changes

### ❌ Old (Confusing)
- "Yearly/Lifetime" - This was ambiguous and confusing
  - Does "Yearly" mean annual subscription?
  - Does "Lifetime" mean one-time payment?
  - Why are both names used together?

### ✅ New (Clear)
- **"Lifetime"** - One-time payment, permanent access
- **"Annual"** - Yearly subscription, recurring payment

## Code Variable Names

### Updated Names

**PaddleConfig.swift:**
```swift
// OLD (confusing)
let lifetimePriceID = "pri_..." // Was called "Yearly/Lifetime"

// NEW (clear)
let lifetimePriceID = "pri_..." // One-time payment for lifetime access
let annualPriceID = "pri_..."   // Yearly subscription
```

**LicenseManager.swift:**
```swift
enum LicenseType {
    case free       // Free tier
    case lifetime   // One-time payment
    case annual     // Yearly subscription
    case monthly    // Monthly subscription (future)
}
```

**Database Schema:**
```sql
license_type VARCHAR(50) -- Values: 'lifetime', 'annual', 'monthly', 'free'
```

## Marketing Copy

### For Website / App Store

**Lifetime License**
> Get Clipso Pro forever with a single payment. No subscriptions, no recurring charges. Pay once, use forever.

**Annual Subscription**
> Try Clipso Pro with our affordable yearly plan. Cancel anytime, and you'll keep access until the end of your billing period.

### Price Comparison

| Feature | Free | Annual | Lifetime |
|---------|------|--------|----------|
| **Price** | $0 | $7.99/year | $29.99 once |
| **Payment** | - | Recurring | One-time |
| **Break-even** | - | 4 years | Immediate |
| Semantic Search | ❌ | ✅ | ✅ |
| Context Detection | ❌ | ✅ | ✅ |
| Max Items | 250 | Unlimited | Unlimited |
| Retention | 30 days | Unlimited | Unlimited |
| Device Limit | - | 3 devices | 3 devices |

**Value Proposition:**
- Annual = Best for trying out Pro features with low commitment
- Lifetime = Best for long-term users (pays for itself after 4 years vs Annual)

## FAQ

### Q: What's the difference between Lifetime and Annual?
**A:** Lifetime is a one-time payment of $29.99 that gives you Pro features forever. Annual is a subscription that costs $7.99 per year and renews automatically until you cancel.

### Q: Which should I choose?
**A:** If you plan to use Clipso for 4+ years, Lifetime is more economical. If you want lower upfront cost or want to try Pro first, choose Annual.

### Q: Can I upgrade from Annual to Lifetime?
**A:** Yes! Contact support and we can apply a credit for your remaining subscription time toward a Lifetime license.

### Q: Do both options include the same features?
**A:** Yes! Both Lifetime and Annual give you access to all Pro features with no differences.

### Q: How many devices can I activate?
**A:** Both Lifetime and Annual licenses can be activated on up to 3 devices. You can deactivate devices and activate new ones anytime.

## Implementation Checklist

### Files Updated
- [x] `Managers/PaddleConfig.swift` - Price ID naming
- [x] `Managers/LicenseManager.swift` - Variable naming and comments
- [x] `backend/server.js` - License type handling
- [x] `backend/schema.sql` - Database comments
- [x] `website/script.js` - Button labels and text
- [x] `website/paddle-test.html` - Test page labels
- [x] `website/index.html` - Marketing copy
- [x] `PADDLE_CREDENTIALS.md` - Documentation
- [ ] `README.md` - Update pricing section (if exists)
- [ ] App Store listing - Update subscription copy
- [ ] Marketing materials - Update all references

### Marketing Assets to Update
- [ ] Website hero section
- [ ] Pricing page
- [ ] Feature comparison table
- [ ] Email templates (welcome, purchase confirmation)
- [ ] Social media posts
- [ ] App Store description
- [ ] Product screenshots

## Summary

**Before:** Confusing "Yearly/Lifetime" naming caused ambiguity about whether it was a subscription or one-time payment.

**After:** Clear separation:
- **Lifetime** = One-time payment, $29.99
- **Annual** = Yearly subscription, $7.99/year

This makes the pricing structure crystal clear for customers and reduces confusion during the purchase process.
