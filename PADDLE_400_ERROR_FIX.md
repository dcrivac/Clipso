# Fixing Paddle 400 Error - Complete Guide

## What Happened

You're seeing this error in the browser console:
```
Failed to load resource: the server responded with a status of 400
❌ Checkout error: undefined
```

**Root Cause**: The Price IDs in your code don't exist in Paddle Sandbox environment.

## Why This Happened

The code is configured to use **Sandbox** credentials:
- Token: `test_859aa26dd9d5c623ccccf54e0c7` (Sandbox)
- Environment: `sandbox`

But Paddle is returning a 400 error, which means the Price IDs:
- `pri_01kfr145r1eh8f7m8w0nfkvz74` (Yearly/Lifetime)
- `pri_01kfr12rgvdnhpr52zspmqvnk1` (Annual)

Either don't exist, or were created in the **Live** environment instead of Sandbox.

## The Fix: Create Products in Paddle Sandbox

### Step 1: Go to Paddle Sandbox Dashboard

1. Open: https://sandbox-vendors.paddle.com
2. Log in with your Paddle account
3. Make sure you see "SANDBOX" in the top corner (NOT "LIVE")

### Step 2: Create Product

1. Click **Catalog** in the left sidebar
2. Click **Products** → **+ Product** button
3. Fill in the form:

```
Product Name: Clipso Pro
Description: AI-powered clipboard manager with semantic search and context detection
Tax Category: Standard (Software/SaaS)
```

4. For Product Image, use:
   ```
   https://raw.githubusercontent.com/dcrivac/Clipso/main/assets/logo-512.png
   ```
   (Or upload the PNG from `assets/logo-512.png`)

5. Click **Save product**

### Step 3: Add Yearly/Lifetime Price

1. After saving the product, you'll be on the product detail page
2. Scroll down to the **Prices** section
3. Click **+ Add Price**
4. Fill in:

```
Price Name: Yearly/Lifetime License
Description: One-time payment for lifetime access to all Pro features
Billing Period: One-time
Unit Price: $29.99 USD
Currency: USD
```

5. Click **Save price**
6. **CRITICAL**: Copy the **Price ID** that appears (format: `pri_01...`)
   - This replaces `pri_01kfr145r1eh8f7m8w0nfkvz74`

### Step 4: Add Annual Subscription Price

1. Click **+ Add Price** again
2. Fill in:

```
Price Name: Annual Subscription
Description: Annual subscription with all Pro features
Billing Period: Year
Unit Price: $7.99 USD
Currency: USD
Trial Period: 14 days (optional - set to 0 if you don't want a trial)
```

3. Click **Save price**
4. **CRITICAL**: Copy the **Price ID** that appears
   - This replaces `pri_01kfr12rgvdnhpr52zspmqvnk1`

### Step 5: Update Your Code

Now you have **NEW Sandbox Price IDs**. You need to update them in your code.

#### Update website/paddle-test.html

Open `website/paddle-test.html` and find these lines (around line 119-120):

```javascript
const LIFETIME_PRICE_ID = 'pri_01kfr145r1eh8f7m8w0nfkvz74';
const ANNUAL_PRICE_ID = 'pri_01kfr12rgvdnhpr52zspmqvnk1';
```

Replace with your NEW Sandbox Price IDs:

```javascript
const LIFETIME_PRICE_ID = 'pri_01YOUR_NEW_YEARLY_ID';  // Paste your Yearly/Lifetime Price ID here
const ANNUAL_PRICE_ID = 'pri_01YOUR_NEW_ANNUAL_ID';    // Paste your Annual Price ID here
```

#### Update website/script.js

Open `website/script.js` and find these lines (around line 19-20):

```javascript
const LIFETIME_PRICE_ID = 'pri_01kfr145r1eh8f7m8w0nfkvz74';
const ANNUAL_PRICE_ID = 'pri_01kfr12rgvdnhpr52zspmqvnk1';
```

Replace with the same NEW Sandbox Price IDs:

```javascript
const LIFETIME_PRICE_ID = 'pri_01YOUR_NEW_YEARLY_ID';
const ANNUAL_PRICE_ID = 'pri_01YOUR_NEW_ANNUAL_ID';
```

### Step 6: Test Locally

1. Open `website/paddle-test.html` directly in your browser (double-click the file)
2. Open browser console (Cmd+Option+J on Mac)
3. Check that "Paddle Status" shows ✅ Ready
4. Click **"Test Lifetime Checkout"** or **"Test Annual Checkout"**
5. The Paddle checkout overlay should open (no 400 error!)

### Step 7: Complete Test Purchase

1. In the checkout overlay, use the test card:
   - **Card Number**: `4242 4242 4242 4242`
   - **Expiry**: `12/26` (any future date)
   - **CVC**: `123` (any 3 digits)
   - **Name**: Test User
   - **Email**: your-email@example.com
   - **Country**: United States (or any)

2. Click **Subscribe** or **Buy Now**

3. Check the console for: `✅ Transaction completed`

### Step 8: Verify in Paddle Dashboard

1. Go back to https://sandbox-vendors.paddle.com
2. Click **Transactions** in the left sidebar
3. You should see your test transaction!
4. Click into it to see the details and custom data

## If You Already Created Products in Live

If you already created products in the **Live** (production) environment and want to keep those:

**Option A: Switch to Live** (NOT recommended for testing)
1. Get your **Live** client-side token from Paddle → Developer Tools → Authentication
2. Update both files to use Live:
   ```javascript
   const PADDLE_VENDOR_ID = 'live_YOUR_LIVE_TOKEN';
   const PADDLE_ENVIRONMENT = 'production';
   const LIFETIME_PRICE_ID = 'pri_YOUR_LIVE_YEARLY_ID';
   const ANNUAL_PRICE_ID = 'pri_YOUR_LIVE_ANNUAL_ID';
   ```

**Option B: Create Sandbox versions** (RECOMMENDED)
- Follow Steps 1-8 above to create Sandbox versions
- Keep your Live products for when you're ready to launch
- Test everything in Sandbox first, then switch to Live

## Quick Checklist

- [ ] Logged into https://sandbox-vendors.paddle.com
- [ ] Created "Clipso Pro" product in SANDBOX
- [ ] Added Yearly/Lifetime price ($29.99 one-time)
- [ ] Added Annual price ($7.99/year)
- [ ] Copied both NEW Sandbox Price IDs
- [ ] Updated `website/paddle-test.html` with new Price IDs
- [ ] Updated `website/script.js` with new Price IDs
- [ ] Opened paddle-test.html locally in browser
- [ ] Clicked test checkout button
- [ ] Checkout overlay opened (no 400 error!)
- [ ] Completed test purchase with test card
- [ ] Verified transaction in Paddle Sandbox Dashboard

## Common Mistakes

❌ **Creating products in Live instead of Sandbox**
- Make sure you see "SANDBOX" in the top corner of Paddle dashboard

❌ **Mixing Sandbox token with Live Price IDs**
- Sandbox token (`test_...`) only works with Sandbox Price IDs
- Live token (`live_...`) only works with Live Price IDs

❌ **Typo in Price ID**
- Double-check you copied the entire Price ID correctly
- Format is always: `pri_01` followed by 24 characters

❌ **Not refreshing after code changes**
- Hard refresh your browser (Cmd+Shift+R on Mac)
- Or open paddle-test.html fresh

## Still Getting 400 Error?

If you followed all steps and still get 400:

1. **Double-check the Price IDs match EXACTLY**:
   - In Paddle Sandbox Dashboard → Catalog → Products → Clipso Pro → Prices
   - Copy each Price ID again
   - Paste into your code, replacing the old ones

2. **Verify you're looking at Sandbox, not Live**:
   - URL should be: https://sandbox-vendors.paddle.com
   - Top corner should say "SANDBOX"

3. **Check the token is correct**:
   - Go to Paddle Sandbox Dashboard → Developer Tools → Authentication
   - Copy the **Client-side token** (starts with `test_`)
   - Make sure it matches the one in your code

4. **Open browser console for details**:
   - Press Cmd+Option+J (Mac) or F12 (Windows)
   - Look for any red errors
   - Take a screenshot and report the issue

## Next Steps After Fix

Once checkout works in Sandbox:

1. ✅ Test multiple purchases
2. ✅ Verify all transaction data appears correctly
3. ✅ Test webhooks (if you set them up)
4. ✅ Update the macOS app (`Managers/LicenseManager.swift`) with same Price IDs
5. ✅ When ready for production, create products in **Live** environment
6. ✅ Switch code to use Live credentials

## Need Help?

Open an issue: https://github.com/dcrivac/Clipso/issues

Include:
- Screenshot of Paddle Sandbox Dashboard showing your product
- Screenshot of browser console errors
- The Price IDs you're using

---

**Remember**: Sandbox is for testing only. Transactions in Sandbox are NOT real payments. When you're ready to accept real money, you'll need to create the same products in the **Live** environment and update your code to use Live credentials.
