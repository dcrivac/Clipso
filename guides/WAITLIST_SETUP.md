# Waitlist Setup Guide

The landing page is now in **pre-launch mode** with a waitlist signup form. Here's how to set it up.

---

## Why Pre-Launch Mode?

You correctly identified that the landing page wasn't ready for public launch because:
- ❌ No downloadable app releases yet
- ❌ No payment processor integrated (Stripe, Paddle, etc.)
- ❌ Broken "Download" and "Buy" links

**Solution:** Waitlist mode lets you:
- ✅ Generate interest and collect emails
- ✅ Build an audience before launch
- ✅ Test market demand
- ✅ Launch with ready customers

---

## Quick Setup (5 minutes)

### Option 1: Formspree (Recommended - Free)

Formspree is the easiest way to handle form submissions without backend code.

**Steps:**

1. **Create Free Account**
   - Go to: https://formspree.io/
   - Sign up (free tier: 50 submissions/month)
   - Click "New Form"
   - Name it: "Clipso Waitlist"

2. **Get Your Form ID**
   - Copy the form endpoint, it looks like: `https://formspree.io/f/YOUR_FORM_ID`
   - Example: `https://formspree.io/f/xwkgpqyw`

3. **Update Your Landing Page**
   - Open `docs/index.html`
   - Find line 696: `action="https://formspree.io/f/YOUR_FORM_ID"`
   - Replace `YOUR_FORM_ID` with your actual form ID
   - Example: `action="https://formspree.io/f/xwkgpqyw"`

4. **Deploy to GitHub Pages**
   - Follow the deployment instructions in `GITHUB_PAGES_DEPLOYMENT.md`
   - Your waitlist is now live!

5. **Configure Email Notifications (Optional)**
   - In Formspree dashboard, go to your form settings
   - Add your email to receive notifications when someone signs up
   - Set up auto-responder to thank users for joining

---

### Option 2: Google Forms (Alternative - Free)

If you prefer Google Forms:

**Steps:**

1. Create a Google Form: https://forms.google.com/
2. Add one field: "Email Address" (required)
3. Click "Send" → Get link
4. Update the form action in `docs/index.html` line 696

**Cons:**
- Less professional looking
- Redirects users away from your site
- No custom styling

---

### Option 3: Mailchimp (For Email Marketing - Free up to 500 subscribers)

If you want to send launch emails later:

**Steps:**

1. Sign up at: https://mailchimp.com/
2. Create an audience
3. Go to "Audience" → "Signup forms" → "Embedded forms"
4. Copy the form action URL
5. Update `docs/index.html` line 696

**Pros:**
- Can send email campaigns to waitlist
- Automation (welcome email, launch announcement)
- Analytics dashboard

---

## Current Landing Page Changes

### What Changed:

**Hero Section:**
- ✅ Badge: "Coming Soon • Join Waitlist for Early Access"
- ✅ Button: "Join Waitlist" instead of "Download for macOS"

**Pricing Section:**
- ✅ Subtitle: "Planned pricing when we launch"
- ✅ Buttons: "Get Notified" / "Join Waitlist for Early Access"
- ✅ Note: "Be first to know when we launch"

**Waitlist Section (New):**
- ✅ Email signup form
- ✅ Early access benefits list
- ✅ Note for developers to build from source

**CTA Section:**
- ✅ Heading: "Ready to Transform Your Clipboard?"
- ✅ Button: "Join Waitlist"
- ✅ Note: "Coming Soon" messaging

---

## What Happens When Someone Signs Up?

### With Formspree:
1. User enters email and clicks "Join Waitlist"
2. Email is sent to your Formspree inbox
3. You receive notification email
4. User sees success message (configurable)
5. You can export emails to CSV anytime

### Managing Your Waitlist:

**In Formspree Dashboard:**
- View all submissions
- Export to CSV
- Set up integrations (Zapier, Slack, etc.)
- Configure auto-responders

---

## Sample Auto-Responder Email

Set this up in Formspree to automatically thank new signups:

```
Subject: Thanks for joining the Clipso waitlist!

Hi there,

Thanks for your interest in Clipso!

You're on the list to be among the first to experience truly intelligent clipboard management with:
• Semantic AI search that understands meaning
• Automatic context detection
• 100% private (all AI runs locally)
• Free tier + Premium at $7.99/year (47% less than Paste)

We'll email you as soon as we launch. In the meantime:
- Star us on GitHub: https://github.com/dcrivac/Clipso
- Follow development progress
- Try building from source if you're a developer

Thanks!
The Clipso Team

P.S. We hate spam too. You can unsubscribe anytime.
```

---

## Launch Day Checklist

When you're ready to launch with the actual app:

### Before Launch:
- [ ] Create GitHub release with downloadable .dmg
- [ ] Set up payment processor (Stripe/Paddle/Gumroad)
- [ ] Test download and installation flow
- [ ] Test payment flow for Premium/Lifetime

### Launch Day:
- [ ] Update `docs/index.html`:
  - Change "Coming Soon" badge to "Now Available"
  - Change "Join Waitlist" to "Download for macOS"
  - Update form action to actual download link
  - Enable payment buttons
- [ ] Email your waitlist with launch announcement
- [ ] Update pricing buttons to actual purchase links
- [ ] Remove waitlist section or keep for future updates

### Launch Email Template:

```
Subject: 🚀 Clipso is now available!

Hi [Name],

Great news! Clipso is officially launching today.

You're getting this email because you joined our waitlist. Here's what you need to know:

**Download Now (Free):**
https://github.com/dcrivac/Clipso/releases

**What's Included:**
• Free tier: 10 AI semantic searches/day
• Premium: $7.99/year for unlimited AI (47% less than Paste)
• Lifetime: $29.99 one-time (limited time)

**Early Bird Special (24 hours only):**
Because you joined the waitlist, use code EARLY for 20% off Premium:
• Premium: $6.39/year (normally $7.99)
• Lifetime: $23.99 (normally $29.99)

Download link: [GitHub Releases]
Pricing page: [Landing Page URL]

Thanks for your patience!
The Clipso Team
```

---

## Analytics (Optional)

### Track Waitlist Signups:

**Option 1: Formspree Built-in**
- Dashboard shows signup count over time
- Export data to analyze trends

**Option 2: Google Analytics**
- Add Google Analytics to `docs/index.html`
- Track form submissions as events
- See where traffic comes from

**Option 3: Plausible (Privacy-friendly)**
- Add Plausible script to `docs/index.html`
- GDPR compliant, no cookies
- Clean analytics dashboard

---

## Testing Your Waitlist

Before deploying publicly, test the form:

1. **Local Testing:**
   ```bash
   cd docs/
   python3 -m http.server 8000
   # Open http://localhost:8000
   ```

2. **Test Form Submission:**
   - Enter your own email
   - Click "Join Waitlist"
   - Check Formspree dashboard for submission
   - Verify you received notification email

3. **Mobile Testing:**
   - Test on iPhone Safari
   - Test on Android Chrome
   - Check form responsiveness

4. **Error Handling:**
   - Try submitting without email (should show error)
   - Try submitting invalid email (should show error)
   - Try submitting twice (Formspree handles duplicates)

---

## Common Issues & Fixes

### "Form isn't submitting"
**Fix:** Make sure you replaced `YOUR_FORM_ID` in line 696 of `docs/index.html`

### "Getting spam signups"
**Fix:** Enable Formspree's spam protection (free tier includes honeypot + reCAPTCHA)

### "Want to customize success message"
**Fix:** Add this after the form in `docs/index.html`:
```html
<div id="success-message" style="display:none;">
  <h3>Thanks for joining!</h3>
  <p>We'll email you when we launch.</p>
</div>
```

### "Need to export emails"
**Fix:** In Formspree dashboard → Click "Export" → Download CSV

---

## Cost Breakdown

| Service | Free Tier | Paid Tier |
|---------|-----------|-----------|
| **Formspree** | 50/month | $10/month (1000/month) |
| **Mailchimp** | 500 subscribers | $13/month (500-2500) |
| **Google Forms** | Unlimited | Free forever |
| **GitHub Pages** | Free | Free (for public repos) |

**Recommendation:** Start with Formspree free tier. Upgrade if you get >50 signups/month.

---

## Next Steps

1. **Set up Formspree** (5 minutes)
   - Create account
   - Get form ID
   - Update `docs/index.html` line 696

2. **Deploy to GitHub Pages** (5 minutes)
   - Follow `GITHUB_PAGES_DEPLOYMENT.md`
   - Merge to main branch
   - Enable Pages in settings

3. **Share Your Waitlist** (ongoing)
   - Twitter: "Building Clipso—intelligent clipboard for Mac. Join the waitlist!"
   - Reddit: r/macapps, r/opensource
   - Hacker News: Show HN when you have 50+ signups
   - Product Hunt: Launch with Ship to collect emails

4. **Build Your App** (parallel)
   - Continue development
   - Create first release build
   - Set up payment integration
   - Prepare launch materials

---

## Questions?

- Formspree docs: https://help.formspree.io/
- GitHub Pages troubleshooting: See `GITHUB_PAGES_DEPLOYMENT.md`
- Payment integration: See `PRICING_STRATEGY.md` (Stripe/Paddle recommendations)

---

**Your landing page is now ready for pre-launch deployment!** 🚀

No broken links, no unfulfilled promises—just a clean waitlist to build your audience.
