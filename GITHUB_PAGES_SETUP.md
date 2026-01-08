# GitHub Pages Deployment Guide

Complete guide to deploying the Clipso landing page on GitHub Pages.

---

## Why GitHub Pages?

✅ **Free hosting**
✅ **Automatic HTTPS**
✅ **Custom domain support**
✅ **Built-in CDN**
✅ **Zero configuration needed**

Perfect for static sites like our landing page.

---

## Quick Deploy (5 Minutes)

### Step 1: Ensure Files Are in the Right Place

Your landing page files should be in the repository root:

```
Clipso/
├── index.html          ✓
├── styles.css          ✓
├── script.js           ✓
├── assets/             ✓
│   ├── banner.svg
│   ├── logo.svg
│   └── ...
└── README.md
```

**Current status**: ✅ All files are already in place!

### Step 2: Merge or Deploy from Your Branch

**Option A: Merge to Main** (Recommended)

```bash
# Switch to main branch
git checkout main

# Merge the marketing branch
git merge claude/artwork-marketing-landing-OXgkW

# Push to GitHub
git push origin main
```

**Option B: Deploy from Feature Branch**

Keep everything on `claude/artwork-marketing-landing-OXgkW` and deploy from there.

### Step 3: Enable GitHub Pages

1. Go to your repository on GitHub:
   ```
   https://github.com/dcrivac/Clipso
   ```

2. Click **Settings** (top navigation)

3. Scroll down to **Pages** (left sidebar)

4. Under "Source":
   - **Source**: Deploy from a branch
   - **Branch**: Select `main` (or `claude/artwork-marketing-landing-OXgkW`)
   - **Folder**: `/ (root)`

5. Click **Save**

### Step 4: Wait for Deployment

GitHub will now build and deploy your site. This takes 1-2 minutes.

You'll see:
```
✓ Your site is live at https://dcrivac.github.io/Clipso/
```

### Step 5: Test Your Site

Visit: `https://dcrivac.github.io/Clipso/`

Everything should work! ✨

---

## Custom Domain (Optional)

### Why Use a Custom Domain?

- **Professional**: `clipboard.yourdomain.com` vs `dcrivac.github.io/Clipso`
- **Branding**: Better for marketing
- **Memorable**: Easier to share

### Setup Instructions

#### 1. Purchase a Domain

Recommended registrars:
- **Namecheap** (~$10/year)
- **Google Domains** (~$12/year)
- **Cloudflare** (~$9/year)

Or use a subdomain if you already own one:
- `clipboard.yourdomain.com`
- `clipboardmanager.yourdomain.com`

#### 2. Configure DNS

Add a **CNAME record** pointing to GitHub Pages:

**If using subdomain** (e.g., `clipboard.yourdomain.com`):

| Type | Name | Value | TTL |
|------|------|-------|-----|
| CNAME | clipboard | dcrivac.github.io | 3600 |

**If using apex domain** (e.g., `clipboardmanager.app`):

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | 185.199.108.153 | 3600 |
| A | @ | 185.199.109.153 | 3600 |
| A | @ | 185.199.110.153 | 3600 |
| A | @ | 185.199.111.153 | 3600 |

#### 3. Add Custom Domain to GitHub

1. Go to repository **Settings → Pages**

2. Under "Custom domain", enter your domain:
   ```
   clipboard.yourdomain.com
   ```

3. Click **Save**

4. Wait for DNS check (can take up to 24 hours, usually 10 minutes)

5. Once verified, check **"Enforce HTTPS"**

#### 4. Add CNAME File to Repository

GitHub Pages needs a `CNAME` file in your repository root:

```bash
# Create CNAME file
echo "clipboard.yourdomain.com" > CNAME

# Commit and push
git add CNAME
git commit -m "Add custom domain"
git push origin main
```

**Done!** Your site will now be at `https://clipboard.yourdomain.com`

---

## Troubleshooting

### Issue: Site Not Loading

**Solution**:
1. Wait 2-3 minutes after enabling Pages
2. Clear browser cache
3. Try incognito mode
4. Check deployment status: Settings → Pages

### Issue: Styles Not Loading

**Cause**: File paths are case-sensitive on GitHub Pages

**Solution**:
```bash
# Make sure all file paths match exactly
# Good: assets/banner.svg
# Bad: Assets/Banner.svg or ASSETS/banner.svg
```

### Issue: Images Not Showing

**Cause**: Absolute paths don't work

**Solution**: Use relative paths
```html
<!-- Good -->
<img src="assets/logo.svg">

<!-- Bad -->
<img src="/assets/logo.svg">
```

### Issue: Custom Domain Not Working

**Solutions**:
1. Wait 24-48 hours for DNS propagation
2. Check DNS settings with: https://dnschecker.org
3. Verify CNAME file exists in repository
4. Make sure "Enforce HTTPS" is enabled

### Issue: 404 Error

**Cause**: GitHub is looking for the wrong file

**Solution**: Make sure `index.html` is in the root directory

---

## Performance Optimization

### Enable Cloudflare (Optional)

Cloudflare adds:
- **Faster loading** (CDN)
- **Better security** (DDoS protection)
- **Analytics** (traffic insights)

**Setup**:
1. Sign up at cloudflare.com
2. Add your domain
3. Update nameservers at your registrar
4. Enable "Proxied" for your DNS records

**Free tier** includes everything you need.

### Minify Files (Optional)

For slightly faster loading:

```bash
# Install minifiers
npm install -g html-minifier clean-css-cli uglify-js

# Minify (create backup first!)
html-minifier --collapse-whitespace --remove-comments index.html -o index.min.html
cleancss -o styles.min.css styles.css
uglifyjs script.js -o script.min.js --compress --mangle

# Update index.html to use minified files
```

**Trade-off**: Harder to read/debug. Usually not worth it for this size site.

---

## Updating Your Site

### Making Changes

```bash
# Make changes to files locally
nano index.html

# Commit changes
git add .
git commit -m "Update landing page copy"

# Push to GitHub
git push origin main
```

GitHub Pages will automatically rebuild (takes 1-2 minutes).

### Preview Changes Locally First

```bash
# Run local server
python3 -m http.server 8000

# Visit http://localhost:8000
# Test changes before pushing
```

---

## Analytics Setup

### Google Analytics

1. Sign up at analytics.google.com
2. Create property for your site
3. Get measurement ID (G-XXXXXXXXXX)
4. Add to `index.html` before `</head>`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

### Plausible Analytics (Privacy-Friendly Alternative)

1. Sign up at plausible.io ($9/month)
2. Add your domain
3. Add to `index.html` before `</head>`:

```html
<script defer data-domain="yourdomain.com" src="https://plausible.io/js/script.js"></script>
```

**Advantages over Google Analytics**:
- Privacy-focused (no cookies)
- GDPR compliant
- Lightweight (<1KB)
- Simple dashboard

### Simple Analytics

Free alternative: https://simpleanalytics.com

---

## SEO Optimization

### Add Metadata

Already included in `index.html`, but verify:

```html
<head>
  <!-- Essential -->
  <title>Clipso - The First Truly Intelligent Clipboard for Mac</title>
  <meta name="description" content="AI-powered clipboard manager with semantic search and context detection. 100% private, free forever.">

  <!-- OpenGraph (for social sharing) -->
  <meta property="og:title" content="Clipso - Intelligent Clipboard for Mac">
  <meta property="og:description" content="Never lose important clipboard content again. AI-powered semantic search, 100% private.">
  <meta property="og:image" content="https://dcrivac.github.io/Clipso/assets/social-card.svg">
  <meta property="og:url" content="https://dcrivac.github.io/Clipso/">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Clipso - Intelligent Clipboard for Mac">
  <meta name="twitter:description" content="AI-powered clipboard with semantic search. 100% private, free forever.">
  <meta name="twitter:image" content="https://dcrivac.github.io/Clipso/assets/social-card.svg">
</head>
```

### Submit to Search Engines

**Google**:
1. Go to search.google.com/search-console
2. Add property: `https://dcrivac.github.io/Clipso/`
3. Verify ownership (upload HTML file or DNS record)
4. Submit sitemap (optional)

**Bing**:
1. Go to webmaster.bing.com
2. Add site
3. Verify

Usually indexed within 24-48 hours.

---

## Backup Strategy

### Keep a Local Copy

```bash
# Clone to a backup location
git clone https://github.com/dcrivac/Clipso.git ~/backup/Clipso

# Or create a release
git tag v1.0.0
git push origin v1.0.0
```

### Export to Vercel/Netlify (Failover)

If GitHub Pages ever has issues:

**Vercel**:
```bash
vercel --prod
```

**Netlify**:
```bash
netlify deploy --prod
```

Both automatically deploy from your GitHub repo.

---

## Checklist

Before going live:

- [ ] All files committed and pushed to GitHub
- [ ] GitHub Pages enabled in repository settings
- [ ] Site loads at https://dcrivac.github.io/Clipso/
- [ ] All images and styles loading correctly
- [ ] Links work (test all navigation)
- [ ] Responsive design works (test mobile)
- [ ] Custom domain configured (if using)
- [ ] HTTPS enforced
- [ ] Analytics installed (if desired)
- [ ] Social sharing tags working (test with Facebook debugger)
- [ ] No console errors (check browser dev tools)

---

## Next Steps After Deployment

1. **Update Repository Links**
   - Add website URL to repository description
   - Update README with live site link

2. **Share the Link**
   - Add to social media profiles
   - Include in Product Hunt launch
   - Share in blog posts

3. **Monitor Performance**
   - Check analytics weekly
   - Monitor page load speed
   - Watch for broken links

4. **Keep Updated**
   - Add testimonials as they come in
   - Update screenshots
   - Refresh copy based on feedback

---

## Support

**Issues?**
- GitHub Pages Status: https://www.githubstatus.com
- GitHub Pages Docs: https://docs.github.com/pages
- Community: https://github.com/community

**Questions?**
- Open an issue on the repository
- Check GitHub Pages documentation

---

## Summary

**Your site is now live!** 🎉

✅ Free hosting
✅ Automatic HTTPS
✅ Fast CDN delivery
✅ Easy to update

**URL**: `https://dcrivac.github.io/Clipso/`

Now go share it with the world! 🚀
