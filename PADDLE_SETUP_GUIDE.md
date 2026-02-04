# Paddle Integration Setup Guide

Complete guide to setting up Paddle payments for Clipso.

## Quick Setup Checklist

- [ ] Create Paddle account
- [ ] Configure products and prices
- [ ] Set up webhook URL
- [ ] Copy webhook secret to backend
- [ ] Update app with Paddle credentials
- [ ] Test payment flow

---

## Step 1: Create Paddle Account

1. Go to [paddle.com](https://paddle.com)
2. Sign up for Seller account
3. Complete business verification
4. Set up payout information

### Sandbox vs Production

- **Sandbox:** Use for testing (no real money)
- **Production:** Live payments

You'll get different credentials for each:
- Sandbox: `test_859aa26dd9d5c623ccccf54e0c7`
- Production: `live_fc98babc1d8bb9e39a3482fd2bc`

---

## Step 2: Create Products

### Create Lifetime License Product

1. Go to Paddle Dashboard → Catalog → Products
2. Click "Create Product"
3. Fill in:
   - **Name:** Clipso Pro - Lifetime
   - **Description:** Lifetime access to Clipso Pro features
   - **Tax category:** Digital goods
   - **Image:** Upload Clipso logo

4. Create Price:
   - **Amount:** $29.99
   - **Currency:** USD
   - **Billing cycle:** One-time
   - **Trial:** None

5. Copy the **Price ID** (e.g., `pri_01kfqf26bqncwbr7nvrg445esy`)

### Create Annual Subscription Product

1. Create another product: "Clipso Pro - Annual"
2. Create Price:
   - **Amount:** $7.99
   - **Currency:** USD
   - **Billing cycle:** Annual
   - **Trial:** 7 days (optional)

3. Copy the **Price ID**

### Update App Configuration

Edit `Managers/PaddleConfig.swift`:

```swift
static let lifetimePriceId = "pri_01kfqf26bqncwbr7nvrg445esy"  // Your lifetime price ID
static let annualPriceId = "pri_01kfqf40kc2jn9cgx9a6naenk7"   // Your annual price ID
```

---

## Step 3: Configure Webhooks

### Get Webhook Secret

1. Go to Paddle Dashboard → Developer Tools → Notifications
2. Find your **Notification Settings**
3. Copy the **Webhook Secret Key**
   - Format: `pdl_ntfset_xxxxxxxxxxxxxxxxxxxx`

### Set Webhook URL

1. In Notifications settings, set:
   - **Destination URL:** `https://your-backend-url.com/webhook/paddle`
   - Example: `https://clipso-production.up.railway.app/webhook/paddle`

2. Enable these events:
   - ✅ `transaction.completed`
   - ✅ `transaction.updated`
   - ✅ `subscription.activated`
   - ✅ `subscription.cancelled`
   - ✅ `subscription.past_due`

3. Click "Save"

### Add Secret to Backend

Add to your backend `.env` file:

```bash
PADDLE_WEBHOOK_SECRET=pdl_ntfset_xxxxxxxxxxxxxxxxxxxx
```

Or in Railway dashboard: Add environment variable `PADDLE_WEBHOOK_SECRET`

---

## Step 4: Test Webhook Integration

### Using Paddle's Webhook Simulator

1. Go to Developer Tools → Notifications → Simulation
2. Select event: `transaction.completed`
3. Click "Send Test Event"
4. Check your backend logs

**Expected in logs:**
```
Received Paddle webhook: transaction.completed (evt_xxxx)
License created: CLIPSO-XXXX-XXXX-XXXX-XXXX for test@example.com (type: lifetime)
✅ License email sent to test@example.com via Resend
```

### Manual Test with Test Payment

1. Open Clipso app (in development mode)
2. Click "Get Lifetime Pro"
3. Paddle checkout opens
4. Use test card:
   - **Card:** 4242 4242 4242 4242
   - **Expiry:** Any future date
   - **CVV:** Any 3 digits

5. Complete checkout
6. Check backend logs for webhook processing
7. Check database for created license:
   ```sql
   SELECT * FROM licenses ORDER BY created_at DESC LIMIT 1;
   ```

---

## Step 5: Update Clipso App

### Configure Paddle in App

1. Open `Managers/PaddleConfig.swift`
2. Update credentials:

```swift
struct PaddleConfig {
    // For Sandbox Testing
    static let sandboxVendorId = "test_859aa26dd9d5c623ccccf54e0c7"
    static let sandboxLifetimePriceId = "pri_01kfr145r1eh8f7m8w0nfkvz74"
    static let sandboxAnnualPriceId = "pri_01kfr12rgvdnhpr52zspmqvnk1"

    // For Production
    static let productionVendorId = "live_fc98babc1d8bb9e39a3482fd2bc"
    static let productionLifetimePriceId = "pri_01kfqf26bqncwbr7nvrg445esy"
    static let productionAnnualPriceId = "pri_01kfqf40kc2jn9cgx9a6naenk7"

    // Toggle between sandbox and production
    static let useSandbox = false  // Set to false for production

    static var vendorId: String {
        useSandbox ? sandboxVendorId : productionVendorId
    }

    static var lifetimePriceId: String {
        useSandbox ? sandboxLifetimePriceId : productionLifetimePriceId
    }

    static var annualPriceId: String {
        useSandbox ? sandboxAnnualPriceId : productionAnnualPriceId
    }
}
```

### Update License Manager

Make sure `Managers/LicenseManager.swift` has the correct API endpoint:

```swift
private let baseURL = "https://your-backend-url.com"  // Your Railway URL

func activateLicense(licenseKey: String, email: String) async throws {
    let endpoint = "\(baseURL)/api/licenses/activate"
    // ... rest of implementation
}
```

---

## Step 6: End-to-End Test

### Complete Payment Flow Test

1. **Customer Buys License:**
   - Open Clipso app
   - Click "Get Lifetime Pro" or "Get Annual Pro"
   - Complete Paddle checkout (use test mode for testing)

2. **Webhook Processes Payment:**
   - Paddle sends webhook to your backend
   - Backend receives `transaction.completed` event
   - Backend generates license key: `CLIPSO-XXXX-XXXX-XXXX-XXXX`
   - Backend inserts license into database
   - Backend sends email with license key

3. **Customer Receives Email:**
   - Check inbox for "🎉 Your Clipso License Key" email
   - Email contains license key and activation instructions

4. **Customer Activates License:**
   - Open Clipso app
   - Go to Settings → License
   - Enter email and license key from email
   - Click "Activate License"

5. **Verify Activation:**
   - License should show as "Active" in app
   - Pro features should unlock
   - Database should show device activation:
     ```sql
     SELECT * FROM devices WHERE license_id = (
         SELECT id FROM licenses WHERE email = 'customer@example.com'
     );
     ```

---

## Common Issues & Solutions

### Webhook Not Receiving Events

**Symptoms:**
- Payment completes but no license created
- No logs in backend

**Solutions:**
1. Check webhook URL is correct in Paddle dashboard
2. Verify backend is accessible: `curl https://your-backend-url.com/health`
3. Check webhook secret is correct in `.env`
4. Look for signature verification errors in logs

### License Email Not Sending

**Symptoms:**
- License created in database
- Customer doesn't receive email

**Solutions:**
1. Check `RESEND_API_KEY` or `SENDGRID_API_KEY` is set
2. Verify email service dashboard for errors
3. Check backend logs for email sending errors
4. Verify `EMAIL_FROM` domain is correct

### License Activation Fails

**Symptoms:**
- Customer enters valid license key
- Gets "Invalid license" error

**Solutions:**
1. Check license exists: `SELECT * FROM licenses WHERE license_key = 'XXX'`
2. Verify license status is 'active'
3. Check backend API is running: `curl https://your-backend-url.com/health`
4. Look at backend logs for activation errors

---

## Production Deployment Checklist

- [ ] Switch from Sandbox to Production Paddle account
- [ ] Update `PaddleConfig.swift` with production credentials
- [ ] Update `useSandbox = false` in PaddleConfig
- [ ] Deploy backend to production (Railway/server)
- [ ] Configure production webhook URL in Paddle
- [ ] Set up production email service (Resend/SendGrid)
- [ ] Test complete purchase flow end-to-end
- [ ] Monitor first few real purchases closely
- [ ] Set up error monitoring (Sentry optional)

---

## Monitoring & Maintenance

### Check Recent Transactions

```sql
-- Recent license purchases
SELECT
    email,
    license_key,
    license_type,
    purchased_at
FROM licenses
ORDER BY purchased_at DESC
LIMIT 10;
```

### Webhook Event Log

```sql
-- Recent webhook events
SELECT
    event_type,
    processed,
    created_at,
    error
FROM webhook_events
ORDER BY created_at DESC
LIMIT 20;
```

### Failed Webhooks

```sql
-- Find failed webhooks
SELECT * FROM webhook_events
WHERE processed = FALSE OR error IS NOT NULL
ORDER BY created_at DESC;
```

---

## Support

- **Paddle Support:** [paddle.com/support](https://paddle.com/support)
- **Paddle Docs:** [developer.paddle.com](https://developer.paddle.com)
- **Clipso Issues:** [github.com/dcrivac/Clipso/issues](https://github.com/dcrivac/Clipso/issues)
