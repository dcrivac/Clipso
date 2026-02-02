# Clipso License Validation Server

Backend API for validating Clipso Pro licenses with Paddle Billing integration.

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Setup Database
```bash
# Create PostgreSQL database
createdb clipso_licenses

# Run schema
psql -d clipso_licenses -f schema.sql
```

### 3. Configure Environment
```bash
cp .env.example .env
# Edit .env with your credentials
```

### 4. Start Server
```bash
npm start
```

Server runs on `http://localhost:3000`

## API Endpoints

### Health Check
```bash
GET /health
```

### Activate License
```bash
POST /api/licenses/activate
Content-Type: application/json

{
  "license_key": "CLIPSO-XXXX-XXXX-XXXX-XXXX",
  "device_id": "uuid",
  "device_name": "MacBook Pro",
  "device_model": "MacBookPro18,3",
  "os_version": "macOS 14.2",
  "app_version": "1.0.0"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Device activated successfully",
  "license_type": "lifetime",
  "devices_used": 1,
  "devices_limit": 3
}
```

### Validate License
```bash
POST /api/licenses/validate
Content-Type: application/json

{
  "license_key": "CLIPSO-XXXX-XXXX-XXXX-XXXX",
  "device_id": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "valid": true,
  "license_type": "lifetime",
  "expires_at": null,
  "email": "user@example.com"
}
```

### Deactivate Device
```bash
POST /api/licenses/deactivate
Content-Type: application/json

{
  "license_key": "CLIPSO-XXXX-XXXX-XXXX-XXXX",
  "device_id": "uuid"
}
```

### Get License Info
```bash
GET /api/licenses/:license_key
```

**Response:**
```json
{
  "success": true,
  "license": {
    "license_key": "CLIPSO-XXXX-XXXX-XXXX-XXXX",
    "email": "user@example.com",
    "license_type": "lifetime",
    "status": "active",
    "valid": true,
    "device_limit": 3,
    "devices_used": 1,
    "devices": [
      {
        "device_id": "uuid",
        "device_name": "MacBook Pro",
        "activated_at": "2025-01-24T...",
        "last_seen": "2025-01-24T...",
        "is_active": true
      }
    ]
  }
}
```

### Paddle Webhook
```bash
POST /webhook/paddle
# Paddle sends events here automatically
```

## Database Schema

### Tables
- `licenses` - License keys and subscription info
- `devices` - Activated devices per license
- `webhook_events` - Paddle webhook event log
- `validation_logs` - License validation attempts log

### Views
- `active_licenses_summary` - Quick overview of active licenses with device counts
- `devices_summary` - All active devices with license info

## Testing

```bash
# Run tests
npm test

# Run specific test file
npm test server.test.js

# Run with coverage
npm test -- --coverage
```

## Deployment

See [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) for detailed deployment instructions.

**Quick deploy to Railway:**
1. Push to GitHub
2. Connect Railway to your repo
3. Add PostgreSQL database
4. Set environment variables
5. Deploy!

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Server port (default: 3000) | No |
| `NODE_ENV` | Environment (development/production) | No |
| `DB_HOST` | PostgreSQL host | Yes |
| `DB_PORT` | PostgreSQL port (default: 5432) | No |
| `DB_NAME` | Database name | Yes |
| `DB_USER` | Database user | Yes |
| `DB_PASSWORD` | Database password | Yes |
| `PADDLE_WEBHOOK_SECRET` | Paddle webhook signing secret | Yes |

## Paddle Webhook Events Handled

- `transaction.completed` - Creates new license
- `transaction.updated` - Updates license status
- `subscription.activated` - Activates subscription license
- `subscription.cancelled` - Marks subscription as cancelled
- `subscription.past_due` - Marks subscription as past due

## License Key Format

License keys are automatically generated from Paddle transaction IDs:

```
Format: CLIPSO-XXXX-XXXX-XXXX-XXXX
Example: CLIPSO-A1B2-C3D4-E5F6-G7H8
```

Generated using SHA256 hash of transaction ID.

## Manual License Generation

For gifting licenses or special promotions, you can manually generate lifetime licenses using the included admin tool.

### Generate a Lifetime License

```bash
# Interactive mode (prompts for email)
node generate-license.js

# Or provide email directly
node generate-license.js friend@example.com
```

**Example output:**
```
✅ Lifetime license created successfully!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📧 Email:        friend@example.com
🔑 License Key:  CLIPSO-A1B2-C3D4-E5F6-G7H8
🎫 Type:         lifetime
✓  Status:       active
📱 Device Limit: 3 devices
📅 Created:      2025-01-24T12:00:00.000Z
⏰ Expires:      Never (Lifetime)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Send this information to your friend:

   Subject: Your Clipso Lifetime License
   ─────────────────────────────────────────────────
   Email: friend@example.com
   License Key: CLIPSO-A1B2-C3D4-E5F6-G7H8
   ─────────────────────────────────────────────────
   To activate:
   1. Open Clipso app
   2. Go to Settings → License
   3. Enter the email and license key above
   4. Click "Activate License"
```

**What it does:**
- Generates a unique license key in the CLIPSO format
- Creates a lifetime license entry in the database
- Sets device limit to 3 by default
- No expiration date (lifetime access)
- Checks for existing licenses and warns if email already has one

**Requirements:**
- Database must be running and accessible
- `.env` file must be configured with database credentials
- `npm install` must have been run

### Direct SQL Method

Alternatively, you can insert a license directly via SQL:

```sql
INSERT INTO licenses (
    license_key,
    email,
    transaction_id,
    product_id,
    price_id,
    license_type,
    status,
    device_limit,
    purchased_at,
    expires_at,
    custom_data
)
VALUES (
    'CLIPSO-XXXX-XXXX-XXXX-XXXX',  -- Generate unique key
    'friend@example.com',
    'manual_' || extract(epoch from now()) || '_' || md5(random()::text),
    'prod_clipso_lifetime',
    'manual',
    'lifetime',
    'active',
    3,
    NOW(),
    NULL,
    '{"source": "manual", "generated_by": "admin"}'::jsonb
);
```

## Device Limits

- Default: 3 devices per license
- Configurable in database (`device_limit` column)
- Users can deactivate devices to activate new ones
- Tracked via `devices` table with `is_active` flag

## Monitoring

### Check Database Stats

```sql
-- Active licenses
SELECT COUNT(*) FROM licenses WHERE status = 'active';

-- Total devices activated
SELECT COUNT(*) FROM devices WHERE is_active = TRUE;

-- Recent activations
SELECT * FROM devices ORDER BY activated_at DESC LIMIT 10;

-- Failed validations
SELECT * FROM validation_logs WHERE validation_result != 'success' ORDER BY created_at DESC LIMIT 10;

-- Webhook events not processed
SELECT * FROM webhook_events WHERE processed = FALSE;
```

### View Summaries

```sql
-- Active licenses with device counts
SELECT * FROM active_licenses_summary;

-- All active devices
SELECT * FROM devices_summary;
```

## Troubleshooting

### Database connection failed
- Check `DB_*` environment variables
- Verify PostgreSQL is running
- Test connection: `psql -h $DB_HOST -U $DB_USER -d $DB_NAME`

### Webhook not receiving events
- Verify webhook URL in Paddle Dashboard
- Check `PADDLE_WEBHOOK_SECRET` is correct
- Test with Paddle's webhook testing tool
- Check server logs for signature verification errors

### License activation fails
- Check license exists in database: `SELECT * FROM licenses WHERE license_key = 'KEY';`
- Verify license status is 'active'
- Check device limit not exceeded
- Review validation_logs for error details

## Development

```bash
# Start with auto-reload
npm run dev

# Run tests in watch mode
npm test -- --watch

# Check code style
npm run lint  # (if configured)
```

## Security

- ✅ Webhook signature verification
- ✅ SQL injection prevention (parameterized queries)
- ✅ Environment-based secrets
- ✅ HTTPS required in production
- ✅ Request timeouts configured
- ✅ CORS enabled (configure as needed)

## Support

- **Full Documentation**: [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md)
- **Pricing Info**: [PRICING_CLARIFICATION.md](../PRICING_CLARIFICATION.md)
- **Paddle Docs**: https://developer.paddle.com

## License

MIT License - See LICENSE file
