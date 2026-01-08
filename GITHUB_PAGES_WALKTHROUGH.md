# GitHub Pages Setup - Complete Walkthrough

**Absolute beginner-friendly guide** to getting your landing page live in 10 minutes.

---

## ✅ What You'll Accomplish

By the end of this guide:
- ✨ Your landing page will be **live on the internet**
- 🔗 Accessible at `https://dcrivac.github.io/Clipso/`
- 🔒 Free HTTPS (secure connection)
- 🌍 Available worldwide via CDN

**Cost**: $0 (completely free)

---

## 📋 Prerequisites

You need:
1. ✅ GitHub account (you have this - you're reading from GitHub!)
2. ✅ Landing page files in your repository (already done!)
3. ⏱️ 10 minutes of time

That's it! No technical skills required.

---

## 🚀 Step-by-Step Setup

### Step 1: Go to Your Repository Settings

**1.1** Open your browser and go to:
```
https://github.com/dcrivac/Clipso
```

**1.2** Look for the **"Settings"** tab at the top

It looks like this:
```
Code  Issues  Pull requests  Actions  Projects  Wiki  Security  Insights  ⚙️ Settings
                                                                            ↑ Click here
```

**1.3** Click **Settings**

If you don't see "Settings", make sure:
- You're logged into GitHub
- You have admin access to the repository (you do if it's your repo)

---

### Step 2: Navigate to Pages

**2.1** In the left sidebar, scroll down until you see **"Pages"**

The sidebar looks like this:
```
General
Collaborators
Branches
Tags
Actions
...
Pages  ← Click here!
```

**2.2** Click **"Pages"**

You'll see the GitHub Pages configuration page.

---

### Step 3: Configure GitHub Pages

**3.1** Under **"Source"**, you'll see a dropdown that says "None" or "Deploy from a branch"

**3.2** Click the dropdown and select **"Deploy from a branch"**

**3.3** A second dropdown appears for **"Branch"**

Click it and select:
- **Branch**: `claude/artwork-marketing-landing-OXgkW`
- **Folder**: `/ (root)`

It should look like this:
```
Source
└── Deploy from a branch

Branch
└── claude/artwork-marketing-landing-OXgkW  / (root)  [Save]
    ↑ Select this                            ↑ Keep as root
```

**3.4** Click the **"Save"** button

---

### Step 4: Wait for Deployment

**4.1** You'll see a message:
```
✓ Your site is ready to be published at
  https://dcrivac.github.io/Clipso/
```

**4.2** Wait 1-2 minutes for GitHub to build your site

You can refresh the page to check status. When ready, you'll see:
```
✓ Your site is live at
  https://dcrivac.github.io/Clipso/
```

---

### Step 5: Visit Your Live Site! 🎉

**5.1** Click the URL or copy-paste into your browser:
```
https://dcrivac.github.io/Clipso/
```

**5.2** Your landing page should be live!

If you see your landing page → **Success!** 🎉

---

## 🔧 Troubleshooting

### Issue: "There isn't a GitHub Pages site here"

**Wait longer**: Sometimes it takes up to 5 minutes. Refresh and wait.

**Check your settings**: Go back to Settings → Pages and verify:
- Source: "Deploy from a branch"
- Branch is selected correctly
- "Save" was clicked

### Issue: Landing Page Shows README Instead

**Solution**: Make sure `index.html` is in the **root** of your repository, not in a subfolder.

Check by going to:
```
https://github.com/dcrivac/Clipso
```

You should see `index.html` in the file list.

### Issue: Styles Not Loading (Page Looks Broken)

**Cause**: File paths might be wrong

**Solution**: In `index.html`, paths should be relative:

✅ **Correct**:
```html
<link rel="stylesheet" href="styles.css">
<script src="script.js"></script>
<img src="assets/logo.svg">
```

❌ **Wrong**:
```html
<link rel="stylesheet" href="/styles.css">
<img src="/assets/logo.svg">
```

### Issue: 404 Error on Images

**Cause**: File paths are case-sensitive on GitHub Pages

✅ **Correct**:
```
assets/logo.svg  (matches actual filename)
```

❌ **Wrong**:
```
Assets/Logo.svg  (wrong case!)
ASSETS/logo.svg  (wrong case!)
```

**Solution**: Check your actual filenames and match them exactly.

---

## 🎨 Optional: Merge to Main Branch

Right now your site is deploying from `claude/artwork-marketing-landing-OXgkW`.

To deploy from `main` branch instead:

### Option A: Merge via GitHub UI (Easiest)

**Step 1**: Go to your repository homepage
```
https://github.com/dcrivac/Clipso
```

**Step 2**: Click **"Compare & pull request"** button (yellow banner at top)

If you don't see it, click **"Pull requests"** tab → **"New pull request"**

**Step 3**: Set up the pull request:
- **Base**: `main`
- **Compare**: `claude/artwork-marketing-landing-OXgkW`

**Step 4**: Click **"Create pull request"**

**Step 5**: Add a title like:
```
Add marketing materials and landing page
```

**Step 6**: Click **"Merge pull request"** → **"Confirm merge"**

**Step 7**: Go back to Settings → Pages and change:
- **Branch**: `main` (instead of feature branch)
- **Folder**: `/ (root)`
- **Save**

**Done!** Your site now deploys from `main`.

### Option B: Merge via Command Line

If you're comfortable with git:

```bash
# Switch to main branch
git checkout main

# Merge the marketing branch
git merge claude/artwork-marketing-landing-OXgkW

# Push to GitHub
git push origin main
```

Then update GitHub Pages settings to use `main` branch.

---

## 🌐 Custom Domain (Optional)

Want to use `clipboard.yourdomain.com` instead of `dcrivac.github.io/Clipso`?

### Prerequisites

You need:
- A domain name (buy from Namecheap, Google Domains, etc. ~$10-15/year)
- Access to DNS settings

### Quick Setup

**Step 1: Configure DNS**

Add a CNAME record:
| Type | Name | Value | TTL |
|------|------|-------|-----|
| CNAME | clipboard | dcrivac.github.io | 3600 |

(Or whatever subdomain you want: `clipboardmanager`, `cm`, etc.)

**Step 2: Add Custom Domain to GitHub**

In Settings → Pages:
1. Under **"Custom domain"**, enter: `clipboard.yourdomain.com`
2. Click **"Save"**
3. Wait for DNS check (can take 24 hours, usually 10 minutes)
4. Once verified, check **"Enforce HTTPS"**

**Step 3: Add CNAME File**

GitHub needs a `CNAME` file in your repository:

**Via GitHub web interface**:
1. Go to repository homepage
2. Click **"Add file"** → **"Create new file"**
3. Name it: `CNAME`
4. Contents: `clipboard.yourdomain.com`
5. Click **"Commit new file"**

**Or via command line**:
```bash
echo "clipboard.yourdomain.com" > CNAME
git add CNAME
git commit -m "Add custom domain"
git push origin main
```

**Wait for DNS**: Can take up to 48 hours, usually <1 hour

**Done!** Your site is now at `https://clipboard.yourdomain.com`

---

## 📊 Adding Analytics (Optional)

Track visitors to your landing page.

### Option 1: Google Analytics (Free)

**Step 1**: Create account at [analytics.google.com](https://analytics.google.com)

**Step 2**: Get your Measurement ID (format: `G-XXXXXXXXXX`)

**Step 3**: Add to `index.html` before `</head>`:

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

**Step 4**: Commit and push

**Done!** Check analytics.google.com after 24 hours

### Option 2: Plausible (Privacy-Friendly, $9/month)

**Step 1**: Sign up at [plausible.io](https://plausible.io)

**Step 2**: Add to `index.html` before `</head>`:

```html
<script defer data-domain="yourdomain.com" src="https://plausible.io/js/script.js"></script>
```

**Advantages**:
- No cookies (GDPR compliant)
- Lightweight (<1KB)
- Privacy-focused
- Simple dashboard

---

## 🔄 Updating Your Site

After making changes to `index.html` or other files:

### Via GitHub Web Interface

1. Navigate to the file on GitHub
2. Click the pencil icon (Edit)
3. Make changes
4. Scroll down, click **"Commit changes"**
5. Wait 1-2 minutes for rebuild

### Via Command Line

```bash
# Make changes to files locally
nano index.html  # or use any editor

# Commit changes
git add .
git commit -m "Update landing page"

# Push to GitHub
git push origin main  # or your branch name
```

**GitHub Pages automatically rebuilds** when you push changes.

---

## ✅ Post-Setup Checklist

After your site is live:

**Verify Everything Works**:
- [ ] Landing page loads
- [ ] All images show
- [ ] All links work
- [ ] Styles applied correctly
- [ ] Responsive on mobile (test on phone)
- [ ] HTTPS enabled (lock icon in browser)

**Update Repository**:
- [ ] Add website URL to repository description
- [ ] Update README with live site link
- [ ] Add link to social profiles

**Share**:
- [ ] Tweet the launch
- [ ] Post to LinkedIn
- [ ] Share in relevant communities
- [ ] Add to email signature

---

## 📝 Quick Reference

**Your Live URLs**:
- **Landing Page**: https://dcrivac.github.io/Clipso/
- **GitHub Repo**: https://github.com/dcrivac/Clipso
- **Settings**: https://github.com/dcrivac/Clipso/settings/pages

**Common Tasks**:

| Task | How To |
|------|--------|
| View site | Visit your GitHub Pages URL |
| Update content | Edit files, commit, push to GitHub |
| Check build status | Settings → Pages (shows build status) |
| Change domain | Settings → Pages → Custom domain |
| Disable Pages | Settings → Pages → Source → None |

---

## 🎯 Next Steps

Now that your landing page is live:

1. **Test on Multiple Devices**
   - Desktop (Chrome, Safari, Firefox)
   - Mobile (iPhone, Android)
   - Tablet

2. **Update All Links**
   - Add landing page URL to Product Hunt materials
   - Update press email templates
   - Add to social media bios

3. **Set Up Analytics** (if desired)
   - Google Analytics or Plausible
   - Track visitor counts
   - Monitor performance

4. **Share Widely**
   - Twitter with landing page link
   - LinkedIn post
   - Product Hunt launch
   - Press outreach

---

## 💡 Pro Tips

### Performance

**Optimize Images Before Uploading**:
```bash
# Install ImageOptim
brew install imageoptim-cli

# Optimize all images
imageoptim assets/*.svg assets/*.png
```

**Minify Files** (optional, for slightly faster load):
```bash
# Install minifiers
npm install -g html-minifier clean-css-cli uglify-js

# Minify (backup first!)
html-minifier --collapse-whitespace index.html -o index.min.html
cleancss -o styles.min.css styles.css
```

### SEO

**Add Sitemap** (for better Google indexing):

Create `sitemap.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://dcrivac.github.io/Clipso/</loc>
    <lastmod>2025-01-15</lastmod>
    <priority>1.0</priority>
  </url>
</urlset>
```

**Submit to Google**:
1. Go to [search.google.com/search-console](https://search.google.com/search-console)
2. Add your site
3. Verify ownership
4. Submit sitemap

### Monitoring

**Check Site Health**:
- [PageSpeed Insights](https://pagespeed.web.dev/): Test performance
- [GTmetrix](https://gtmetrix.com/): Detailed analysis
- GitHub Pages status: [githubstatus.com](https://www.githubstatus.com/)

---

## 🆘 Need Help?

**Common Resources**:
- [GitHub Pages Documentation](https://docs.github.com/pages)
- [GitHub Pages Troubleshooting](https://docs.github.com/en/pages/getting-started-with-github-pages/troubleshooting-404-errors-for-github-pages-sites)
- [GitHub Community Forum](https://github.com/orgs/community/discussions)

**Still Stuck?**
- Open an issue on your repository
- Ask in GitHub Discussions
- Check [GITHUB_PAGES_SETUP.md](GITHUB_PAGES_SETUP.md) for more details

---

## 🎉 Congratulations!

Your landing page is now **live on the internet** and accessible to everyone! 🚀

**What you've accomplished**:
✅ Professional landing page deployed
✅ Free hosting forever
✅ Automatic HTTPS
✅ Fast CDN delivery
✅ Easy to update

**Now go share it with the world!** 🌍

---

**Time to completion**: 10 minutes
**Cost**: $0
**Awesomeness**: 💯

---

*This walkthrough is part of the Clipso marketing package. See [COMPLETE_MARKETING_PACKAGE.md](COMPLETE_MARKETING_PACKAGE.md) for the full launch strategy.*
