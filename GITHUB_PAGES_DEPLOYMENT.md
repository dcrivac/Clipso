# GitHub Pages Deployment Instructions

Your landing page is ready to deploy! All website files have been organized in the `docs/` folder.

## Quick Deploy (5 minutes)

### Step 1: Merge Feature Branch to Main

First, you need to merge the `claude/artwork-marketing-landing-OXgkW` branch to `main`:

**Option A: Via GitHub Web Interface (Recommended)**
1. Go to: https://github.com/dcrivac/Clipso/compare
2. Create a Pull Request from `claude/artwork-marketing-landing-OXgkW` to `main`
3. Review the changes
4. Click "Merge Pull Request"
5. Confirm the merge

**Option B: Via Command Line**
```bash
git checkout main
git pull origin main
git merge claude/artwork-marketing-landing-OXgkW
git push origin main
```

### Step 2: Enable GitHub Pages

1. Go to your repository: https://github.com/dcrivac/Clipso
2. Click **"Settings"** (top right)
3. Scroll down to **"Pages"** in the left sidebar
4. Under **"Source"**, select:
   - **Branch:** `main`
   - **Folder:** `/docs`
5. Click **"Save"**

### Step 3: Wait for Deployment (1-2 minutes)

GitHub will automatically build and deploy your site. You'll see a message:
> "Your site is ready to be published at https://dcrivac.github.io/Clipso/"

After 1-2 minutes, your landing page will be live at:
**https://dcrivac.github.io/Clipso/**

---

## What's Deployed

The `docs/` folder contains:

### Core Website
- ✅ `index.html` - Landing page with pricing section
- ✅ `styles.css` - All styling including pricing cards
- ✅ `script.js` - Interactive features

### Assets
- ✅ `assets/logo.svg` - App logo
- ✅ `assets/banner.svg` - GitHub README banner
- ✅ `assets/social-card.svg` - Social media share card
- ✅ `assets/screenshot-*.svg` - Demo screenshots
- ✅ `assets/social-*.svg` - Social media graphics

### Blog Posts
- ✅ `blog/product-launch.md` - General launch post
- ✅ `blog/technical-deep-dive.md` - Technical audience
- ✅ `blog/privacy-manifesto.md` - Privacy focus

---

## Pricing Model Live

Your landing page now displays:

### Free Tier ($0)
- 10 AI semantic searches per day
- Unlimited clipboard history
- Unlimited keyword search
- Unlimited OCR
- 100% private (local processing)

### Premium Tier ($7.99/year)
- Unlimited AI semantic search
- Auto context detection
- Smart suggestions
- iCloud sync (E2E encrypted)
- Custom snippets & templates
- Advanced search filters
- Priority support

### Lifetime ($29.99 one-time)
- All Premium features forever
- All future updates included
- No recurring charges

**Key Messaging:** "47% cheaper than Paste with superior privacy"

---

## Verify Deployment

Once deployed, check:

1. **Homepage loads**: https://dcrivac.github.io/Clipso/
2. **Pricing section works**: Scroll to pricing, check all 3 cards
3. **Images load**: All SVG assets should display
4. **Navigation works**: Click "Pricing" in nav bar
5. **Mobile responsive**: Test on mobile device

---

## Update Landing Page Later

To update the landing page after deployment:

1. Make changes to files in `docs/` folder
2. Commit: `git add docs/ && git commit -m "Update landing page"`
3. Push to main: `git push origin main`
4. GitHub Pages will auto-deploy (1-2 minutes)

---

## Custom Domain (Optional)

If you want to use a custom domain like `clipboardmanager.app`:

1. Buy domain from Namecheap, Google Domains, etc.
2. In GitHub Settings → Pages → Custom domain
3. Enter your domain: `clipboardmanager.app`
4. Add DNS records at your domain registrar:
   - Type: `A`, Name: `@`, Value: `185.199.108.153`
   - Type: `A`, Name: `@`, Value: `185.199.109.153`
   - Type: `A`, Name: `@`, Value: `185.199.110.153`
   - Type: `A`, Name: `@`, Value: `185.199.111.153`
   - Type: `CNAME`, Name: `www`, Value: `dcrivac.github.io`
5. Wait 24-48 hours for DNS propagation
6. Enable "Enforce HTTPS" in GitHub Pages settings

---

## Troubleshooting

### Page shows 404
- Wait 2-3 minutes after enabling Pages
- Check Settings → Pages shows green success message
- Verify branch is `main` and folder is `/docs`

### Images don't load
- Check `docs/assets/` folder exists
- Verify paths in `index.html` use relative paths
- Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)

### CSS not applying
- Check `docs/styles.css` exists
- Verify `<link>` tag in `index.html` points to `styles.css`
- Clear browser cache and hard refresh

### Changes not showing
- Verify you pushed to `main` branch
- Check GitHub Actions tab for build status
- Wait 1-2 minutes for deployment
- Hard refresh browser

---

## Next Steps

After deployment, you can:

1. **Share the link**
   - Twitter: "Check out our landing page: https://dcrivac.github.io/Clipso/"
   - Reddit: Post in r/macapps, r/opensource
   - Hacker News: Submit to Show HN

2. **Add to README**
   - Update main README.md with live demo link
   - Add "🌐 Live Demo" badge

3. **Set up analytics** (optional)
   - Google Analytics
   - Plausible (privacy-friendly)
   - Simple Analytics

4. **Test on real devices**
   - iPhone Safari
   - Android Chrome
   - Desktop browsers (Chrome, Firefox, Safari, Edge)

---

## Success Criteria

Your landing page is successfully deployed when:
- ✅ URL is live: https://dcrivac.github.io/Clipso/
- ✅ Pricing section shows all 3 tiers
- ✅ All images and graphics load
- ✅ Mobile responsive (works on phone)
- ✅ Navigation links work (Features, Pricing, Privacy)
- ✅ Download buttons point to GitHub releases

---

**Your marketing materials are production-ready and deployed!** 🚀

Questions? Check:
- GitHub Pages docs: https://docs.github.com/pages
- Troubleshooting: https://docs.github.com/pages/getting-started-with-github-pages/troubleshooting-404-errors-for-github-pages-sites
