# Formspree Setup - 5 Minute Quickstart

Follow these exact steps to get your waitlist working.

---

## Step 1: Create Formspree Account (2 minutes)

1. **Go to:** https://formspree.io/
2. **Click:** "Get Started" or "Sign Up"
3. **Sign up with:**
   - Email + Password, OR
   - GitHub account (recommended - faster)
4. **Verify email** if using email signup

**Free tier includes:**
- 50 form submissions per month
- Email notifications
- Spam filtering
- CSV export

---

## Step 2: Create Your Form (1 minute)

1. **In Formspree Dashboard:**
   - Click **"+ New Form"**

2. **Form Settings:**
   - **Name:** `Clipso Waitlist`
   - **Email:** (your email - where you'll receive signups)
   - Click **"Create Form"**

3. **Copy Your Form Endpoint:**
   - You'll see: `https://formspree.io/f/YOUR_FORM_ID`
   - Example: `https://formspree.io/f/xwkgpqyw`
   - **Copy the entire URL** (you'll need this in Step 3)

---

## Step 3: Update Landing Page (30 seconds)

I've prepared the landing page - you just need to add your form ID:

### Option A: Quick Command (Recommended)

Run this command, replacing `YOUR_FORM_ID` with your actual form ID:

```bash
cd /home/user/Clipso
sed -i 's|action="https://formspree.io/f/YOUR_FORM_ID"|action="https://formspree.io/f/xwkgpqyw"|g' docs/index.html
```

**Example with real form ID:**
```bash
sed -i 's|action="https://formspree.io/f/YOUR_FORM_ID"|action="https://formspree.io/f/xwkgpqyw"|g' docs/index.html
```

### Option B: Manual Edit

1. Open `docs/index.html`
2. Find line 696: `<form action="https://formspree.io/f/YOUR_FORM_ID"`
3. Replace `YOUR_FORM_ID` with your actual form ID
4. Save

**Before:**
```html
<form class="waitlist-form" action="https://formspree.io/f/YOUR_FORM_ID" method="POST">
```

**After:**
```html
<form class="waitlist-form" action="https://formspree.io/f/xwkgpqyw" method="POST">
```

---

## Step 4: Test Your Form (1 minute)

### Local Test:

```bash
cd docs/
python3 -m http.server 8000
```

Open: http://localhost:8000

1. Scroll to "Join the Waitlist" section
2. Enter your email
3. Click "Join Waitlist"
4. **You should see:** Formspree confirmation page
5. **Check your email:** You'll receive a notification

### Check Formspree Dashboard:

1. Go back to Formspree dashboard
2. Click on your form
3. You should see your test submission!

---

## Step 5: Configure Auto-Responder (Optional - 2 minutes)

Send an automatic thank-you email to people who sign up:

1. **In Formspree Dashboard:**
   - Click your form
   - Go to **"Settings"** → **"Autoresponder"**

2. **Enable Autoresponder**

3. **Use this template:**

**Subject:**
```
Thanks for joining the Clipso waitlist! 🚀
```

**Message:**
```
Hi there,

Thanks for joining the Clipso waitlist!

You're on the list to be among the first to experience:
• AI-powered semantic search that understands meaning
• Automatic context detection
• 100% private (all AI runs locally on your Mac)
• Free tier + Premium at $7.99/year (47% less than Paste)

We'll email you as soon as we launch. In the meantime:
→ Star us on GitHub: https://github.com/dcrivac/Clipso
→ Follow development progress
→ Build from source if you're a developer

Thanks for your support!

Best,
The Clipso Team

---
P.S. We respect your privacy. You can unsubscribe anytime.
```

4. **Save**

---

## Step 6: Deploy (Follow existing guide)

Now follow the deployment instructions in `GITHUB_PAGES_DEPLOYMENT.md`:

1. Commit your changes:
   ```bash
   git add docs/index.html
   git commit -m "Add Formspree form ID for waitlist"
   git push
   ```

2. Deploy to GitHub Pages (see GITHUB_PAGES_DEPLOYMENT.md)

---

## ✅ You're Done!

Your waitlist is now live and will:
- ✅ Collect email signups
- ✅ Send you notifications
- ✅ Send auto-responder to users
- ✅ Filter spam automatically
- ✅ Export to CSV anytime

---

## Common Issues

### "Form isn't submitting"
**Fix:** Make sure you replaced `YOUR_FORM_ID` with your actual form ID (no brackets, no quotes)

### "Spam submissions"
**Fix:** In Formspree settings, enable:
- Honeypot spam filtering (free)
- reCAPTCHA (optional)

### "Not receiving notifications"
**Fix:** Check your email spam folder, or update notification email in Formspree settings

### "Want to see all submissions"
**Fix:** Formspree dashboard → Click your form → See all submissions

### "Need to export emails"
**Fix:** Formspree dashboard → Click your form → "Export" button → Download CSV

---

## Your Form ID

**Write it down here for reference:**

```
My Formspree Form ID: ___________________

Full URL: https://formspree.io/f/___________________
```

---

## Next: Share Your Waitlist

Once deployed, share on:
- **Twitter:** "Building Clipso - intelligent clipboard for Mac with AI. Join waitlist: [link]"
- **Reddit:** r/macapps, r/opensource
- **Hacker News:** When you have good traction
- **Product Hunt:** Use "Ship" to collect emails before main launch

---

## Need Help?

- **Formspree Docs:** https://help.formspree.io/
- **Formspree Support:** support@formspree.io
- **Test form:** https://formspree.io/forms/demo

---

**Total setup time: ~5 minutes** ⏱️

Once you have your form ID, just run the sed command or manually update line 696 in `docs/index.html`!
