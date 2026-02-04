# Deploy Clipso Backend to Railway

Quick 5-minute deployment guide for Railway.app

## Why Railway?

- ✅ $5/month (includes PostgreSQL)
- ✅ Automatic HTTPS
- ✅ Easy database management
- ✅ One-command deployment
- ✅ Free $5 credit to start

## Quick Deploy (5 minutes)

### 1. Install Railway CLI

```bash
npm install -g @railway/cli
```

### 2. Login to Railway

```bash
railway login
```

This opens your browser to authenticate.

### 3. Deploy from Backend Directory

```bash
cd backend
railway init
```

Select: **"Create new project"**

### 4. Add PostgreSQL

```bash
railway add --plugin postgresql
```

### 5. Deploy the App

```bash
railway up
```

Wait for deployment to complete (~2 minutes).

### 6. Set Environment Variables

Go to Railway dashboard or use CLI:

```bash
# Set Paddle webhook secret
railway variables set PADDLE_WEBHOOK_SECRET=pdl_ntfset_your_secret_here

# Set email service (Resend recommended)
railway variables set RESEND_API_KEY=re_your_resend_api_key
railway variables set EMAIL_FROM="Clipso <licenses@clipso.app>"
```

### 7. Run Database Schema

```bash
# Connect to Railway PostgreSQL
railway connect postgres

# You're now in psql
# Run the schema
\i schema-fixed.sql

# Exit
\q
```

### 8. Get Your Backend URL

```bash
railway open
```

Copy the URL (e.g., `https://clipso-production.up.railway.app`)

### 9. Test Health Check

```bash
curl https://your-railway-url.com/health
```

Expected:
```json
{"status":"ok","timestamp":"2024-01-24T..."}
```

## Done! 🎉

Your backend is now live at `https://your-railway-url.com`

### Next Steps

1. **Configure Paddle Webhook:**
   - Go to Paddle Dashboard → Developer Tools → Webhooks
   - Set URL to: `https://your-railway-url.com/webhook/paddle`

2. **Update Clipso App:**
   - Edit `Managers/LicenseManager.swift`
   - Set `baseURL = "https://your-railway-url.com"`

3. **Test Payment Flow:**
   - Make test purchase
   - Check Railway logs: `railway logs`
   - Verify license in database

## Managing Your Deployment

### View Logs

```bash
railway logs
```

### Connect to Database

```bash
railway connect postgres
```

### Redeploy After Changes

```bash
git add .
git commit -m "Update backend"
railway up
```

### Environment Variables

```bash
# View all variables
railway variables

# Set a variable
railway variables set KEY=value

# Delete a variable
railway variables delete KEY
```

### Database Queries

```bash
# Connect to database
railway connect postgres

# View licenses
SELECT * FROM licenses ORDER BY created_at DESC LIMIT 10;

# View recent activations
SELECT * FROM devices ORDER BY activated_at DESC LIMIT 10;

# Check webhook events
SELECT event_type, processed, created_at FROM webhook_events ORDER BY created_at DESC LIMIT 20;
```

## Costs

- **Hobby Plan:** $5/month
  - Includes PostgreSQL
  - 500 hours execution time
  - $0.000463/GB of RAM/hr
  - Perfect for small-scale production

## Troubleshooting

### Deployment Fails

```bash
# Check build logs
railway logs --deployment

# Rebuild
railway up --detach
```

### Database Connection Issues

```bash
# Verify database is linked
railway link

# Check database variables
railway variables | grep DATABASE
```

### Schema Load Fails

Make sure you're using `schema-fixed.sql` not `schema.sql` (the original has syntax errors).

```bash
railway connect postgres
\i schema-fixed.sql
```

## Alternative: Deploy via GitHub

1. Push code to GitHub
2. Go to [railway.app](https://railway.app)
3. Click "New Project"
4. Select "Deploy from GitHub repo"
5. Choose your repo
6. Railway auto-detects Node.js and deploys
7. Add PostgreSQL plugin
8. Set environment variables in dashboard
9. Run schema via `railway connect postgres`

## Support

- Railway Docs: [docs.railway.app](https://docs.railway.app)
- Railway Discord: [discord.gg/railway](https://discord.gg/railway)
- Clipso Issues: [github.com/dcrivac/Clipso/issues](https://github.com/dcrivac/Clipso/issues)
