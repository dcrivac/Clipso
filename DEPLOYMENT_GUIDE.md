# Clipso License Server - Deployment Guide

## Overview

This guide covers deploying the Clipso license validation backend server and configuring the macOS app to use it.

## Architecture

```
┌─────────────────┐
│   Clipso App    │
│   (macOS)       │
└────────┬────────┘
         │
         │ HTTPS/JSON
         ▼
┌─────────────────┐       ┌──────────────┐
│ License Server  │◄─────►│  PostgreSQL  │
│  (Node.js API)  │       │   Database   │
└────────┬────────┘       └──────────────┘
         │
         │ Webhooks
         ▼
┌─────────────────┐
│ Paddle Billing  │
│   (Payments)    │
└─────────────────┘
```

## Prerequisites

- **Node.js** 18+
- **PostgreSQL** 14+
- **Paddle Account** (Sandbox for testing, Production for live)
- **Domain with SSL** (for production deployment)
- **Server** (DigitalOcean, AWS, Heroku, Railway, etc.)

---

## Part 1: Database Setup

### Step 1: Install PostgreSQL

**macOS (Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Docker:**
```bash
docker run --name clipso-db \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_DB=clipso_licenses \
  -p 5432:5432 \
  -d postgres:14
```

### Step 2: Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE clipso_licenses;

# Create user (optional)
CREATE USER clipso_user WITH PASSWORD 'secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE clipso_licenses TO clipso_user;

\q
```

### Step 3: Run Schema Migration

```bash
cd backend
psql -U postgres -d clipso_licenses -f schema.sql
```

**Verify schema:**
```bash
psql -U postgres -d clipso_licenses

\dt  # List tables
# Should show: licenses, devices, webhook_events, validation_logs

\dv  # List views
# Should show: active_licenses_summary, devices_summary

\q
```

---

## Part 2: Backend Server Setup

### Step 1: Install Dependencies

```bash
cd backend
npm install
```

### Step 2: Configure Environment

```bash
cp .env.example .env
nano .env
```

**Edit `.env`:**
```env
# Server
PORT=3000
NODE_ENV=production

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=clipso_licenses
DB_USER=postgres
DB_PASSWORD=your_database_password

# Paddle
PADDLE_WEBHOOK_SECRET=your_paddle_webhook_secret
```

**Get Paddle Webhook Secret:**
1. Go to Paddle Dashboard → Developer Tools → Notifications
2. Click "Notification Settings"
3. Copy the "Webhook Secret Key"
4. Paste into `.env` file

### Step 3: Test Locally

```bash
npm start
```

**Test health endpoint:**
```bash
curl http://localhost:3000/health
```

**Expected response:**
```json
{
  "status": "ok",
  "timestamp": "2025-01-24T..."
}
```

### Step 4: Run Tests

```bash
npm test
```

---

## Part 3: Paddle Webhook Configuration

### Step 1: Set Up Webhook URL

**For local testing (using ngrok):**
```bash
# Install ngrok
brew install ngrok  # macOS
# or download from https://ngrok.com

# Start ngrok tunnel
ngrok http 3000

# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
```

**For production:**
- Use your deployed server URL (e.g., `https://api.clipso.app`)

### Step 2: Configure Paddle Notifications

1. Go to **Paddle Dashboard** → **Developer Tools** → **Notifications**
2. Click **"Create Notification Destination"** (or **"Edit"** if exists)
3. Set:
   - **Name**: Clipso License Server
   - **Type**: Webhook
   - **URL**: `https://your-server.com/webhook/paddle` (or ngrok URL for testing)
   - **Events to subscribe**: Select all transaction and subscription events:
     - `transaction.completed`
     - `transaction.updated`
     - `subscription.activated`
     - `subscription.cancelled`
     - `subscription.past_due`
4. Save

### Step 3: Test Webhook

**Use Paddle's webhook testing tool:**
1. Go to Paddle Dashboard → Developer Tools → Notifications
2. Click "Test" next to your webhook
3. Send a test `transaction.completed` event
4. Check your server logs for: `Received Paddle webhook: transaction.completed`

---

## Part 4: Production Deployment

### Option A: Deploy to Railway.app (Recommended)

**Why Railway:**
- ✅ Easy deployment from GitHub
- ✅ Free PostgreSQL database included
- ✅ Automatic HTTPS
- ✅ Environment variable management
- ✅ Free tier available

**Steps:**

1. **Push code to GitHub:**
```bash
git add backend/
git commit -m "Add license server"
git push origin main
```

2. **Create Railway account:**
- Go to https://railway.app
- Sign up with GitHub

3. **Create new project:**
- Click "New Project"
- Select "Deploy from GitHub repo"
- Choose your repository
- Select `backend` directory

4. **Add PostgreSQL:**
- Click "New" → "Database" → "PostgreSQL"
- Railway will create database and provide connection string

5. **Set environment variables:**
- Go to your service → "Variables"
- Add:
  - `PORT`: 3000
  - `NODE_ENV`: production
  - `DB_HOST`: (provided by Railway)
  - `DB_PORT`: 5432
  - `DB_NAME`: (provided by Railway)
  - `DB_USER`: (provided by Railway)
  - `DB_PASSWORD`: (provided by Railway)
  - `PADDLE_WEBHOOK_SECRET`: (from Paddle)

6. **Run schema migration:**
- Connect to Railway PostgreSQL via terminal or GUI
- Run `schema.sql` file

7. **Deploy:**
- Railway auto-deploys on git push
- Get your public URL (e.g., `https://your-app.up.railway.app`)

### Option B: Deploy to Heroku

```bash
# Install Heroku CLI
brew install heroku  # macOS

# Login
heroku login

# Create app
cd backend
heroku create clipso-license-server

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Set environment variables
heroku config:set NODE_ENV=production
heroku config:set PADDLE_WEBHOOK_SECRET=your_secret_here

# Deploy
git push heroku main

# Run schema migration
heroku pg:psql < schema.sql

# Check logs
heroku logs --tail
```

### Option C: Deploy to DigitalOcean

1. **Create Droplet:**
   - Choose Ubuntu 22.04
   - Add SSH key
   - Select size ($6/month minimum)

2. **Connect and setup:**
```bash
ssh root@your_droplet_ip

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Clone repo
git clone https://github.com/yourusername/Clipso.git
cd Clipso/backend

# Install dependencies
npm install --production

# Setup database
sudo -u postgres psql
CREATE DATABASE clipso_licenses;
\q
psql -U postgres -d clipso_licenses -f schema.sql

# Configure environment
cp .env.example .env
nano .env  # Edit with your values

# Install PM2 for process management
sudo npm install -g pm2

# Start server
pm2 start server.js --name clipso-license-server
pm2 save
pm2 startup  # Follow instructions

# Setup Nginx reverse proxy
sudo apt install nginx
sudo nano /etc/nginx/sites-available/clipso
```

**Nginx config:**
```nginx
server {
    listen 80;
    server_name api.clipso.app;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/clipso /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setup SSL with Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.clipso.app
```

---

## Part 5: Configure macOS App

### Step 1: Update License Server URL

**In `Managers/LicenseManager.swift`:**
```swift
// Update this line
private let licenseServerURL = "https://api.clipso.app"  // Your deployed server URL
```

### Step 2: Add Paddle Configuration to Info.plist

1. Open your Xcode project
2. Select `Info.plist`
3. Add these keys:

**For Sandbox (Testing):**
```xml
<key>PADDLE_VENDOR_ID</key>
<string>test_859aa26dd9d5c623ccccf54e0c7</string>

<key>PADDLE_LIFETIME_PRICE_ID</key>
<string>pri_01kfr145r1eh8f7m8w0nfkvz74uf</string>

<key>PADDLE_ANNUAL_PRICE_ID</key>
<string>pri_01kfr12rgvdnhpr52zspmqvnk1</string>

<key>PADDLE_API_KEY</key>
<string></string>

<key>PADDLE_USE_SANDBOX</key>
<true/>
```

**For Production (Live):**
- Change `PADDLE_USE_SANDBOX` to `<false/>`
- Update credentials to Live values

### Step 3: Test License Activation

1. Build and run the app
2. Go to Settings → License
3. Enter a test license key
4. Click "Activate"
5. Check server logs for activation request

---

## Part 6: Testing

### Test Complete Flow

**1. Complete a test purchase:**
```bash
# Open test page
open https://your-github-pages.io/Clipso/paddle-test.html

# Or locally
open website/paddle-test.html
```

**2. Use test card:**
- Card: `4242 4242 4242 4242`
- Expiry: `12/26`
- CVC: `123`

**3. Check webhook logs:**
```bash
# Railway
railway logs

# Heroku
heroku logs --tail

# DigitalOcean
pm2 logs clipso-license-server
```

**4. Check database:**
```sql
-- Connect to database
psql -U postgres -d clipso_licenses

-- Check licenses
SELECT * FROM licenses;

-- Check webhook events
SELECT * FROM webhook_events ORDER BY created_at DESC LIMIT 10;

-- View active licenses summary
SELECT * FROM active_licenses_summary;
```

**5. Test activation in app:**
- Copy license key from database or webhook logs
- Format: `CLIPSO-XXXX-XXXX-XXXX-XXXX`
- Enter in app settings
- Verify Pro features are enabled

### Test Device Limits

```bash
# Activate on multiple devices
curl -X POST https://api.clipso.app/api/licenses/activate \
  -H "Content-Type: application/json" \
  -d '{
    "license_key": "CLIPSO-XXXX-XXXX-XXXX-XXXX",
    "device_id": "device-1",
    "device_name": "MacBook Pro"
  }'

# Repeat for device-2, device-3

# 4th device should fail with DEVICE_LIMIT_EXCEEDED
curl -X POST https://api.clipso.app/api/licenses/activate \
  -H "Content-Type: application/json" \
  -d '{
    "license_key": "CLIPSO-XXXX-XXXX-XXXX-XXXX",
    "device_id": "device-4",
    "device_name": "iMac"
  }'
```

### Test Periodic Revalidation

- Wait 7 days (or modify `revalidationIntervalDays` for testing)
- App should automatically revalidate
- Check validation_logs table for revalidation attempts

---

## Part 7: Monitoring & Maintenance

### Set Up Logging

**1. Add logging service (optional):**
- Logtail (https://logtail.com)
- Papertrail (https://papertrailapp.com)
- CloudWatch (AWS)

**2. Monitor key metrics:**
- License activations per day
- Failed validation attempts
- Device limit exceeded errors
- Webhook processing failures

### Database Backups

**Railway:**
- Automatic backups included
- Download: Railway Dashboard → Database → Backups

**Heroku:**
```bash
heroku pg:backups:capture
heroku pg:backups:download
```

**DigitalOcean:**
```bash
# Automated daily backup
sudo crontab -e

# Add:
0 2 * * * pg_dump -U postgres clipso_licenses > /backups/clipso_$(date +\%Y\%m\%d).sql
```

### Update Server

**Railway:**
- Push to GitHub, auto-deploys

**Heroku:**
```bash
git push heroku main
```

**DigitalOcean:**
```bash
ssh root@your_droplet_ip
cd Clipso/backend
git pull
npm install
pm2 restart clipso-license-server
```

---

## Troubleshooting

### Server won't start

**Check logs:**
```bash
# Railway
railway logs

# PM2
pm2 logs clipso-license-server

# Heroku
heroku logs --tail
```

**Common issues:**
- Database connection failed → Check DB credentials
- Port already in use → Change PORT environment variable
- Missing environment variables → Check `.env` file

### Webhook not receiving events

1. **Check Paddle webhook configuration:**
   - URL correct?
   - HTTPS enabled?
   - All events subscribed?

2. **Test webhook manually:**
```bash
curl -X POST https://api.clipso.app/webhook/paddle \
  -H "Content-Type: application/json" \
  -d '{"event_type":"test","event_id":"test123","data":{}}'
```

3. **Check signature verification:**
   - `PADDLE_WEBHOOK_SECRET` correct?
   - Signature verification passing?

### License activation fails

1. **Check server logs** for error details
2. **Verify database** has the license
3. **Check license status** is 'active'
4. **Test with curl:**
```bash
curl -X POST https://api.clipso.app/api/licenses/activate \
  -H "Content-Type: application/json" \
  -d '{
    "license_key": "YOUR-LICENSE-KEY",
    "device_id": "test-device"
  }'
```

---

## Security Checklist

- [ ] HTTPS enabled (SSL certificate)
- [ ] Environment variables secure (not in code)
- [ ] Database password strong
- [ ] Paddle webhook secret configured
- [ ] CORS configured correctly
- [ ] Rate limiting enabled (optional)
- [ ] Database backups automated
- [ ] Error logging configured
- [ ] Monitoring alerts set up

---

## Production Checklist

### Before Going Live:

- [ ] Database backed up
- [ ] Server deployed and tested
- [ ] HTTPS/SSL configured
- [ ] Paddle webhooks configured (LIVE environment)
- [ ] App configured with LIVE Paddle credentials
- [ ] Test complete purchase flow end-to-end
- [ ] Monitor first few transactions closely
- [ ] Customer support ready for license issues

### After Going Live:

- [ ] Monitor webhook events daily
- [ ] Check validation_logs for issues
- [ ] Verify license activations work
- [ ] Test from multiple devices
- [ ] Update documentation with actual URLs
- [ ] Set up automated database backups
- [ ] Configure monitoring/alerting

---

## Cost Estimate

**Minimal Setup:**
- Railway Free Tier: $0/month (limited usage)
- Or Railway Starter: $5/month
- PostgreSQL included

**Production Setup:**
- Railway Pro: $20/month
- Or DigitalOcean Droplet: $6-12/month
- Domain: $10-15/year
- SSL: Free (Let's Encrypt)

**Total: ~$5-20/month**

---

## Support

- **Paddle Docs**: https://developer.paddle.com
- **Railway Docs**: https://docs.railway.app
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

---

**Ready to deploy?** Start with local testing, then deploy to Railway, and finally switch to production Paddle credentials when ready to accept real payments.
