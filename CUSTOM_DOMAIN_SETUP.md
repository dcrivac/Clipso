# Custom Domain Setup Guide for Clipso.app

## Step 1: Configure DNS Records

Go to your domain registrar (where you registered clipso.app) and add these DNS records:

### Option A: Apex Domain (clipso.app)

Add **4 A records** pointing to GitHub's IPs:

```
Type: A
Name: @
Value: 185.199.108.153

Type: A
Name: @
Value: 185.199.109.153

Type: A
Name: @
Value: 185.199.110.153

Type: A
Name: @
Value: 185.199.111.153
```

### Option B: Subdomain (www.clipso.app)

Add a **CNAME record**:

```
Type: CNAME
Name: www
Value: dcrivac.github.io
```

**Recommended:** Set up both! Use apex domain + www subdomain.

---

## Step 2: Enable GitHub Pages

1. Go to https://github.com/dcrivac/clipso/settings/pages
2. Under **Source**, select:
   - Branch: `main`
   - Folder: `/docs`
3. Click **Save**
4. Wait for the site to build (usually 1-2 minutes)

---

## Step 3: Configure Custom Domain on GitHub

1. Still in the GitHub Pages settings
2. Under **Custom domain**, enter: `clipso.app`
3. Click **Save**
4. Wait for DNS check to complete (can take 24-48 hours for DNS propagation)
5. Once DNS is verified, check **Enforce HTTPS**

---

## Step 4: Verify Setup

After DNS propagates (usually 10-60 minutes, max 48 hours):

1. Visit https://clipso.app
2. Verify the landing page loads
3. Check that HTTPS is working (green lock icon)
4. Test that www.clipso.app redirects to clipso.app

---

## CNAME File

A `docs/CNAME` file has been created with `clipso.app`. This tells GitHub Pages which custom domain to use.

**Important:** Don't delete the CNAME file! GitHub Pages needs it.

---

## Troubleshooting

### DNS Not Propagating
- Use https://dnschecker.org to check if DNS has propagated globally
- It can take up to 48 hours in rare cases
- Clear your browser cache

### Certificate Errors
- Wait for GitHub to provision HTTPS certificate (can take 15-30 minutes after DNS verification)
- Don't enable "Enforce HTTPS" until certificate is ready

### 404 Errors
- Make sure GitHub Pages is set to use the `/docs` folder
- Verify the `docs/CNAME` file exists with `clipso.app` inside
- Check that index.html exists in the docs/ folder

---

## Current Status

✅ CNAME file created: `docs/CNAME`
✅ Landing page ready: `docs/index.html`
✅ All assets ready: `docs/assets/`, `docs/styles.css`, `docs/script.js`

**Next Steps for You:**
1. Push the CNAME file to GitHub
2. Configure DNS records at your registrar
3. Enable GitHub Pages in repository settings
4. Configure custom domain in GitHub Pages settings
