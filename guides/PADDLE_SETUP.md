# Paddle Integration Guide for Clipso

## Overview

This guide covers integrating Paddle payment processing for the freemium Clipso app.

## Products to Create in Paddle

### 1. Launch Special - Lifetime Pro
- **Product Name:** Clipso Pro - Lifetime License
- **Price:** $29.99 USD (one-time)
- **Product Type:** Software Download
- **Recurring:** No
- **Trial Period:** None

### 2. Regular Pro - Annual Subscription
- **Product Name:** Clipso Pro - Annual
- **Price:** $7.99 USD / year
- **Product Type:** Software Download / SaaS
- **Recurring:** Yearly
- **Trial Period:** 7 days (optional)

### 3. Monthly Subscription (Optional)
- **Product Name:** Clipso Pro - Monthly
- **Price:** $0.99 USD / month
- **Product Type:** Software Download / SaaS
- **Recurring:** Monthly
- **Trial Period:** 7 days (optional)

## Step-by-Step Paddle Setup

### 1. Create Paddle Account
1. Sign up at https://vendors.paddle.com/signup
2. Complete business verification
3. Wait for approval (1-2 business days)

### 2. Configure Products
1. Go to Catalog → Products → New Product
2. Create each product above with pricing
3. Note down Product IDs for each

### 3. Get API Credentials
1. Go to Developer Tools → Authentication
2. Copy **Vendor ID** (e.g., 123456)
3. Generate **Vendor Auth Code** or **API Key**
4. Store securely (never commit to git)

### 4. Set Up Webhooks (Optional but Recommended)
1. Go to Developer Tools → Webhooks
2. Add webhook URL: `https://yourdomain.com/paddle/webhook`
3. Select events:
   - Subscription Created
   - Subscription Updated
   - Subscription Cancelled
   - Payment Succeeded
   - Payment Failed

## Paddle Product IDs

After creating products in Paddle, note the IDs:

```
LIFETIME_PRODUCT_ID = 123456  // Replace with actual ID
ANNUAL_PRODUCT_ID = 234567    // Replace with actual ID
MONTHLY_PRODUCT_ID = 345678   // Replace with actual ID (if using)
```

## Testing

Paddle provides a Sandbox environment:
- Sandbox Dashboard: https://sandbox-vendors.paddle.com
- Create test products
- Use test cards: https://developer.paddle.com/concepts/payment-methods/credit-debit-card

## Integration Options

### Option 1: Paddle.js (Web Checkout - Recommended)
- Opens Paddle checkout in browser
- Paddle handles all payment UI
- Returns license key on success
- Easiest to implement

### Option 2: Paddle SDK (Native)
- Requires macOS SDK integration
- More native feel
- More complex implementation

**Recommendation:** Start with Paddle.js (Option 1) for fastest launch.

## License Management Strategy

### License Storage
- Store license key in macOS Keychain
- Validate on app launch
- Re-validate every 7 days (prevents key sharing)

### License Validation
1. User purchases → Paddle sends license key via email
2. User enters key in app
3. App validates with Paddle API
4. Store validated license in Keychain
5. Enable Pro features

## Next Steps

1. ✅ Create Paddle account
2. ✅ Set up products (Lifetime, Annual, Monthly)
3. ✅ Get Product IDs and Vendor ID
4. ✅ Integrate Paddle.js into landing page
5. ✅ Add license activation UI to macOS app
6. ✅ Implement license validation
7. ✅ Add freemium restrictions (250 items, no AI)
8. ✅ Test end-to-end flow

## Support Resources

- Paddle Documentation: https://developer.paddle.com
- Paddle Classic Docs: https://developer.paddle.com/classic
- Support: vendors@paddle.com
