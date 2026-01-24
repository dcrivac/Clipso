# Paddle Custom Data & Webhooks Guide

This guide shows how to pass custom data to Paddle and use webhooks to automatically activate licenses when customers purchase.

## Table of Contents

1. [Overview](#overview)
2. [Adding Custom Data to Checkout](#adding-custom-data-to-checkout)
3. [Setting Up Webhooks](#setting-up-webhooks)
4. [Handling Webhooks](#handling-webhooks)
5. [Auto License Activation](#auto-license-activation)
6. [Testing](#testing)

## Overview

**Custom Data** allows you to pass metadata through Paddle that comes back in webhooks. This enables:

- ✅ Auto-activating licenses after purchase
- ✅ Linking transactions to customer emails
- ✅ Tracking app version, platform, referral source
- ✅ Storing any metadata you need

**Flow:**
```
User clicks "Buy" →
Website passes custom data to Paddle →
User completes checkout →
Paddle sends webhook with custom data →
Your server generates & emails license key →
User receives license automatically
```

## Adding Custom Data to Checkout

### Method 1: Using customData Parameter (Recommended)

Update your checkout functions in `website/script.js`:

```javascript
// Paddle Checkout with Custom Data
function openLifetimeCheckout() {
    if (typeof window.Paddle === 'undefined') {
        alert('Payment system loading... Please try again in a moment.');
        return;
    }

    // Prepare custom data
    const customData = {
        product_type: 'lifetime',
        app_version: '1.0.0',
        platform: 'macOS',
        source: window.location.pathname,
        timestamp: new Date().toISOString()
    };

    // Open Paddle checkout with custom data
    Paddle.Checkout.open({
        items: [{
            priceId: LIFETIME_PRICE_ID,
            quantity: 1
        }],
        customData: customData,
        settings: {
            successUrl: window.location.origin + '/thank-you?type=lifetime'
        }
    });
}

function openAnnualCheckout() {
    if (typeof window.Paddle === 'undefined') {
        alert('Payment system loading... Please try again in a moment.');
        return;
    }

    const customData = {
        product_type: 'annual',
        app_version: '1.0.0',
        platform: 'macOS',
        source: window.location.pathname,
        timestamp: new Date().toISOString()
    };

    Paddle.Checkout.open({
        items: [{
            priceId: ANNUAL_PRICE_ID,
            quantity: 1
        }],
        customData: customData,
        settings: {
            successUrl: window.location.origin + '/thank-you?type=annual'
        }
    });
}
```

### Method 2: Pre-fill Customer Email (Optional)

If you want to collect email before checkout:

```javascript
function openCheckoutWithEmail() {
    // Prompt for email (or get from a form)
    const email = prompt('Enter your email for license delivery:');

    if (!email || !validateEmail(email)) {
        alert('Please enter a valid email address.');
        return;
    }

    Paddle.Checkout.open({
        items: [{ priceId: LIFETIME_PRICE_ID, quantity: 1 }],
        customer: {
            email: email  // Pre-fill email
        },
        customData: {
            product_type: 'lifetime',
            pre_filled_email: email,  // Store in custom data too
            platform: 'macOS'
        }
    });
}

function validateEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

### What Custom Data Can You Include?

You can pass any key-value pairs as strings:

```javascript
customData: {
    // Purchase metadata
    product_type: 'lifetime',      // 'lifetime', 'annual', 'monthly'
    license_tier: 'pro',            // 'free', 'pro', 'enterprise'

    // App metadata
    app_version: '1.0.0',           // Current app version
    platform: 'macOS',              // 'macOS', 'iOS', 'Windows'
    os_version: '14.0',             // macOS version

    // User metadata
    user_id: 'abc123',              // Your internal user ID (if applicable)
    referral_source: 'producthunt', // Where they came from

    // Tracking
    source: '/pricing',             // Page where purchase originated
    utm_campaign: 'launch_week',    // Marketing campaign
    timestamp: '2025-01-24T10:00:00Z'
}
```

**Important Limits:**
- Max 1000 characters total for all custom data
- Keys and values must be strings
- No nested objects or arrays

## Setting Up Webhooks

### Step 1: Create Webhook Endpoint

You need a server endpoint to receive Paddle webhooks. Options:

**Option A: Hosted Backend** (Recommended)
- Deploy a simple serverless function (Vercel, Netlify, AWS Lambda)
- Receives webhooks, generates license, emails customer

**Option B: GitHub Actions** (Free, but delayed)
- Use repository dispatch to trigger license generation
- Slower but requires no paid hosting

**Option C: Paddle's Email Alerts** (Simplest, but manual)
- No webhook needed
- Manually email license keys after purchase
- Not recommended for scale

### Step 2: Configure Webhook in Paddle

1. Go to Paddle Dashboard → **Developer Tools** → **Webhooks**
2. Click **+ New Webhook**
3. Enter your endpoint URL: `https://yourdomain.com/api/paddle-webhook`
4. Select events to receive:
   - ✅ `transaction.completed` (payment succeeded)
   - ✅ `transaction.updated` (subscription changes)
   - ✅ `subscription.created`
   - ✅ `subscription.cancelled`
   - ✅ `subscription.updated`
5. Save and copy the **Webhook Secret** (for verification)

### Step 3: Webhook Security

Always verify webhooks are from Paddle:

```javascript
// Example: Node.js webhook verification
const crypto = require('crypto');

function verifyPaddleWebhook(webhookSecret, signature, requestBody) {
    const hash = crypto
        .createHmac('sha256', webhookSecret)
        .update(requestBody)
        .digest('hex');

    return hash === signature;
}

// In your webhook handler
app.post('/api/paddle-webhook', (req, res) => {
    const signature = req.headers['paddle-signature'];
    const rawBody = JSON.stringify(req.body);

    if (!verifyPaddleWebhook(WEBHOOK_SECRET, signature, rawBody)) {
        return res.status(401).send('Invalid signature');
    }

    // Process webhook...
});
```

## Handling Webhooks

### Webhook Payload Structure

When a purchase completes, Paddle sends this JSON:

```json
{
  "event_type": "transaction.completed",
  "data": {
    "id": "txn_01h8...",
    "status": "completed",
    "customer": {
      "id": "ctm_01h8...",
      "email": "customer@example.com",
      "name": "John Doe"
    },
    "items": [
      {
        "price_id": "pri_01h8...",
        "product_id": "pro_01h8...",
        "quantity": 1
      }
    ],
    "custom_data": {
      "product_type": "lifetime",
      "platform": "macOS",
      "app_version": "1.0.0"
    },
    "created_at": "2025-01-24T10:00:00.000Z"
  }
}
```

### Processing the Webhook

```javascript
// Example: Node.js/Express webhook handler
app.post('/api/paddle-webhook', async (req, res) => {
    const event = req.body;

    // Verify signature first (see above)

    if (event.event_type === 'transaction.completed') {
        const { data } = event;

        // Extract information
        const customerEmail = data.customer.email;
        const transactionId = data.id;
        const customData = data.custom_data;

        // Generate license key
        const licenseKey = generateLicenseKey(transactionId);

        // Determine license type
        const licenseType = customData.product_type; // 'lifetime' or 'annual'

        // Store in database
        await storeLicense({
            email: customerEmail,
            licenseKey: licenseKey,
            licenseType: licenseType,
            transactionId: transactionId,
            createdAt: new Date(),
            expiresAt: licenseType === 'annual' ? addOneYear(new Date()) : null
        });

        // Send email with license key
        await sendLicenseEmail({
            to: customerEmail,
            licenseKey: licenseKey,
            licenseType: licenseType,
            transactionId: transactionId
        });

        // Track in analytics
        if (typeof gtag !== 'undefined') {
            gtag('event', 'purchase', {
                transaction_id: transactionId,
                value: data.details.totals.total / 100,
                currency: data.details.totals.currency_code,
                items: [{
                    item_id: licenseType,
                    item_name: `Clipso Pro ${licenseType}`,
                    price: data.details.totals.total / 100
                }]
            });
        }

        console.log(`✅ License activated for ${customerEmail}: ${licenseKey}`);
    }

    // Always return 200 to acknowledge receipt
    res.status(200).send('OK');
});
```

## Auto License Activation

### Generate License Keys

Use transaction IDs as license keys (simple and verifiable):

```javascript
function generateLicenseKey(transactionId) {
    // Option 1: Use transaction ID directly
    // Pro: Already unique, verifiable with Paddle API
    // Con: Long and ugly
    return transactionId; // e.g., "txn_01h8x9y0z1a2b3c4d5e6f7g8"

    // Option 2: Format transaction ID nicely
    // e.g., "CLIP-50-01H8-X9Y0-Z1A2"
    const clean = transactionId.replace('txn_', '').toUpperCase();
    return `CLIP-${clean.substring(0, 4)}-${clean.substring(4, 8)}-${clean.substring(8, 12)}`;

    // Option 3: Generate custom key (requires storage)
    const uuid = require('crypto').randomUUID();
    return `CLIPSO-${uuid.split('-').slice(0, 3).join('-').toUpperCase()}`;
}
```

### Email Template

```javascript
async function sendLicenseEmail({ to, licenseKey, licenseType, transactionId }) {
    const subject = `Your Clipso Pro License Key`;

    const html = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; line-height: 1.6; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
                .content { background: #f7fafc; padding: 30px; border-radius: 0 0 8px 8px; }
                .license-box { background: white; border: 2px solid #667eea; border-radius: 6px; padding: 20px; margin: 20px 0; text-align: center; }
                .license-key { font-family: 'Courier New', monospace; font-size: 18px; font-weight: bold; color: #667eea; letter-spacing: 2px; }
                .button { display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin: 10px 0; }
                .footer { color: #718096; font-size: 14px; margin-top: 30px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 Welcome to Clipso Pro!</h1>
                    <p>Thank you for your purchase</p>
                </div>
                <div class="content">
                    <p>Hi there,</p>
                    <p>Your <strong>${licenseType === 'lifetime' ? 'Lifetime' : 'Annual'} Pro</strong> license has been activated!</p>

                    <div class="license-box">
                        <p style="margin: 0; color: #718096; font-size: 14px;">Your License Key:</p>
                        <p class="license-key">${licenseKey}</p>
                    </div>

                    <h3>🚀 Activate Your License:</h3>
                    <ol>
                        <li>Open <strong>Clipso</strong> on your Mac</li>
                        <li>Click the menu bar icon → <strong>Settings</strong></li>
                        <li>Click <strong>Activate License</strong></li>
                        <li>Paste your license key above</li>
                        <li>Enjoy unlimited Pro features!</li>
                    </ol>

                    <h3>✨ What You Get:</h3>
                    <ul>
                        <li>🧠 <strong>Unlimited AI Semantic Search</strong> - Find items by meaning</li>
                        <li>🎯 <strong>Context Detection</strong> - Auto-organize clipboard by project</li>
                        <li>♾️ <strong>Unlimited Items</strong> - No 250 item limit</li>
                        <li>⏰ <strong>Unlimited Retention</strong> - Keep history forever</li>
                    </ul>

                    <div style="text-align: center;">
                        <a href="https://clipso.app/docs" class="button">View Documentation</a>
                        <a href="https://github.com/dcrivac/Clipso/issues" class="button" style="background: #48bb78;">Get Support</a>
                    </div>

                    <div class="footer">
                        <p><strong>Transaction ID:</strong> ${transactionId}</p>
                        <p>Need help? Reply to this email or visit <a href="https://clipso.app">clipso.app</a></p>
                        <p>© 2025 Clipso. All rights reserved.</p>
                    </div>
                </div>
            </div>
        </body>
        </html>
    `;

    // Send via your email service (SendGrid, AWS SES, Postmark, etc.)
    await emailService.send({
        from: 'support@clipso.app',
        to: to,
        subject: subject,
        html: html
    });
}
```

### Store Licenses in Database

```javascript
// Example schema (use your database of choice)
const licenseSchema = {
    id: 'uuid',
    email: 'string',
    licenseKey: 'string',        // The license key
    licenseType: 'string',       // 'lifetime', 'annual', 'monthly'
    transactionId: 'string',     // Paddle transaction ID
    customerId: 'string',        // Paddle customer ID
    status: 'string',            // 'active', 'cancelled', 'expired'
    createdAt: 'timestamp',
    expiresAt: 'timestamp|null', // null for lifetime
    lastValidated: 'timestamp'
};

// Store license
async function storeLicense(licenseData) {
    await db.licenses.create({
        ...licenseData,
        status: 'active'
    });
}

// Validate license (called from app)
async function validateLicense(licenseKey, email) {
    const license = await db.licenses.findOne({
        licenseKey: licenseKey,
        email: email,
        status: 'active'
    });

    if (!license) {
        return { valid: false, reason: 'License not found' };
    }

    // Check expiration
    if (license.expiresAt && new Date() > license.expiresAt) {
        return { valid: false, reason: 'License expired' };
    }

    // Update last validated
    await db.licenses.update(license.id, {
        lastValidated: new Date()
    });

    return {
        valid: true,
        licenseType: license.licenseType,
        expiresAt: license.expiresAt
    };
}
```

## Testing

### Test in Sandbox

1. **Set sandbox mode:**
   ```javascript
   const PADDLE_ENVIRONMENT = 'sandbox';
   ```

2. **Create test products** in Paddle Sandbox

3. **Use test card:**
   - Card: 4242 4242 4242 4242
   - Expiry: Any future date
   - CVC: Any 3 digits

4. **Test webhook locally** with ngrok:
   ```bash
   # Install ngrok
   brew install ngrok

   # Expose local server
   ngrok http 3000

   # Use ngrok URL in Paddle webhook settings
   # https://abc123.ngrok.io/api/paddle-webhook
   ```

5. **Verify custom data** in webhook payload

### Test Checklist

- [ ] Custom data appears in Paddle dashboard transaction details
- [ ] Webhook receives correct custom data
- [ ] License key is generated correctly
- [ ] Email is sent with license key
- [ ] License can be activated in app
- [ ] Pro features unlock after activation
- [ ] Invalid keys are rejected
- [ ] Expired annual licenses stop working

## Production Deployment

### Before Going Live:

1. **Switch to production:**
   ```javascript
   const PADDLE_ENVIRONMENT = 'production';
   const PADDLE_VENDOR_ID = 'your_production_vendor_id';
   const LIFETIME_PRICE_ID = 'your_production_lifetime_price_id';
   const ANNUAL_PRICE_ID = 'your_production_annual_price_id';
   ```

2. **Update webhook URL** to production endpoint

3. **Test one real purchase** (refund it after)

4. **Monitor webhooks** in Paddle dashboard

5. **Set up monitoring** for failed webhooks

### Webhook Reliability

Paddle retries failed webhooks up to 10 times with exponential backoff:
- 1st retry: 5 minutes
- 2nd retry: 15 minutes
- 3rd retry: 1 hour
- ...up to 48 hours

Always return `200 OK` quickly (< 5 seconds) even if processing fails. Process async:

```javascript
app.post('/api/paddle-webhook', async (req, res) => {
    // Verify signature
    // Store webhook in queue for async processing
    await webhookQueue.add(req.body);

    // Return 200 immediately
    res.status(200).send('OK');
});

// Process webhooks asynchronously
webhookQueue.process(async (job) => {
    const event = job.data;
    // Process license activation
    // Send email
    // Update database
});
```

## Summary

**Key Points:**

1. **Custom Data** = Metadata you pass through Paddle
2. **Webhooks** = Paddle notifies you when events happen
3. **Auto-activation** = Webhook → Generate license → Email customer
4. **Transaction ID** = Can be used as license key (already unique)
5. **Always verify** webhook signatures for security

**Benefits:**

- ✅ Instant license delivery (no manual work)
- ✅ Better customer experience
- ✅ Track purchase metadata
- ✅ Scalable (handles 1 or 10,000 purchases/day)
- ✅ Reduces support burden

**Next Steps:**

1. Set up webhook endpoint (serverless function recommended)
2. Update script.js with custom data
3. Test in Paddle Sandbox
4. Deploy to production

---

**Need Help?**

- Paddle Webhook Docs: https://developer.paddle.com/webhooks/overview
- Paddle Custom Data: https://developer.paddle.com/build/transactions/custom-data
- Clipso Support: https://github.com/dcrivac/Clipso/issues
