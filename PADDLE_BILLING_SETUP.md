# Paddle Billing Setup Guide

This guide shows you how to set up Paddle Billing checkout for Clipso **without a backend**.

## Architecture

```
User clicks "Purchase" → macOS app opens URL → Your website (checkout.html) → Paddle.js opens checkout
```

**No backend needed!** Just a simple HTML page with Paddle.js.

## Step 1: Get Your Paddle Credentials

### 1.1 Client-Side Token

1. Go to **[Paddle Sandbox Dashboard](https://sandbox-vendors.paddle.com/)**
2. Navigate to: **Developer Tools** → **Authentication**
3. Find or create a **Client-side token** (starts with `test_`)
4. Copy it

### 1.2 Price IDs

1. Go to: **Catalog** → **Products**
2. Click on your **Lifetime Pro** product
3. Under **Prices**, copy the price ID (e.g., `pri_01kfr145r1eh8f7m8w0nfkvz74`)
4. Do the same for your **Annual Pro** product

## Step 2: Configure checkout.html

Edit `website/checkout.html` line 47:

```javascript
Paddle.Setup({
    token: 'test_YOUR_SANDBOX_TOKEN_HERE', // ← Replace with your client-side token
    // ...
});
```

## Step 3: Deploy checkout.html to Your Website

Upload `website/checkout.html` to your website. It should be accessible at:
- `https://clipso.app/checkout.html` (or your domain)

**Testing locally?** You can use:
```bash
cd website
python3 -m http.server 8080
# Then use: http://localhost:8080/checkout.html
```

## Step 4: Update macOS App

Edit `Managers/LicenseManager.swift` line 13:

```swift
static let checkoutPageURL = "https://clipso.app/checkout.html" // ← Your actual URL
```

Your price IDs are already configured in lines 16-17.

## Step 5: Test It!

1. Rebuild the macOS app:
   ```bash
   xcodebuild -scheme Clipso -configuration Debug build
   ```

2. Run the app and click "Purchase Lifetime" or "Purchase Annual"

3. Your checkout page should open in the browser

4. Paddle checkout overlay should appear automatically

## How It Works

1. User clicks purchase button in macOS app
2. App opens URL: `https://clipso.app/checkout.html?price_id=pri_xxxxx`
3. Checkout page loads and reads `price_id` from URL
4. Page calls `Paddle.Checkout.open()` with that price
5. Paddle overlay opens for user to complete purchase

## For Production

When ready for production:

1. Get production credentials from **live** Paddle dashboard
2. Update `checkout.html`:
   ```javascript
   token: 'live_YOUR_PRODUCTION_TOKEN',
   ```
3. Update `LicenseManager.swift` lines 20-21 with production price IDs
4. Rebuild in Release mode

## Troubleshooting

**Checkout doesn't open?**
- Check browser console for errors (F12)
- Verify client-side token is correct
- Ensure checkout.html is publicly accessible

**Wrong prices shown?**
- Verify price IDs in `PaddleConfig`
- Check that prices are active in Paddle Dashboard

**Testing in Sandbox:**
- Use test card: `4242 4242 4242 4242`
- Any future expiry date
- Any CVC

## Security Notes

✅ **This approach is secure because:**
- Client-side tokens are meant to be public
- Price IDs are not sensitive
- No API keys in the app
- No backend to secure
- Paddle handles all payment processing

## Cost

**$0** - No server costs, no backend hosting. Just a static HTML file on your existing website.
