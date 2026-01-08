# Landing Page Launch Guide

This guide covers deploying and promoting the Clipso landing page.

## 🚀 Quick Deploy Options

### Option 1: GitHub Pages (Recommended - Free)

1. **Enable GitHub Pages**:
   ```bash
   # Push the landing page files to your repo
   git add index.html styles.css script.js assets/
   git commit -m "Add landing page"
   git push origin main
   ```

2. **Configure GitHub Pages**:
   - Go to repository Settings → Pages
   - Source: Deploy from branch
   - Branch: `main` / root
   - Click Save

3. **Access your site**:
   - URL will be: `https://dcrivac.github.io/Clipso/`
   - Custom domain optional (see below)

### Option 2: Vercel (Free - Better Performance)

1. **Install Vercel CLI**:
   ```bash
   npm i -g vercel
   ```

2. **Deploy**:
   ```bash
   cd Clipso
   vercel
   ```

3. **Follow prompts**:
   - Link to existing project or create new
   - Deploy

4. **Production deploy**:
   ```bash
   vercel --prod
   ```

**Advantages**: Automatic HTTPS, CDN, preview deployments

### Option 3: Netlify (Free - Easy)

1. **Via CLI**:
   ```bash
   npm install -g netlify-cli
   netlify deploy
   ```

2. **Or drag-and-drop**:
   - Go to https://app.netlify.com/drop
   - Drag your Clipso folder
   - Done!

### Option 4: Custom Domain + Hosting

If you have your own domain and hosting:

1. Upload files via FTP/SSH:
   ```
   index.html
   styles.css
   script.js
   assets/
   ```

2. Configure web server to serve `index.html` as default

## 🌐 Custom Domain Setup

### For GitHub Pages:

1. **Add CNAME file**:
   ```bash
   echo "clipboard.yourdomain.com" > CNAME
   git add CNAME
   git commit -m "Add custom domain"
   git push
   ```

2. **Configure DNS**:
   Add CNAME record pointing to `dcrivac.github.io`

3. **Enable HTTPS**:
   - In repo Settings → Pages
   - Check "Enforce HTTPS"

### For Vercel/Netlify:

Follow their custom domain wizards (both very straightforward)

## 📊 Analytics Setup (Optional)

### Google Analytics

Add before `</head>` in index.html:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### Plausible Analytics (Privacy-Friendly)

```html
<script defer data-domain="yourdomain.com" src="https://plausible.io/js/script.js"></script>
```

### Simple Analytics

```html
<script async defer src="https://scripts.simpleanalyticscdn.com/latest.js"></script>
```

## 🎯 Launch Checklist

### Pre-Launch

- [ ] Test landing page locally (open index.html in browser)
- [ ] Check responsive design (mobile, tablet, desktop)
- [ ] Verify all links work
- [ ] Update GitHub repository URL if different
- [ ] Test all interactive features (search animation, hover effects)
- [ ] Validate HTML/CSS (W3C validators)
- [ ] Check browser compatibility (Safari, Chrome, Firefox)
- [ ] Optimize images/SVGs if needed
- [ ] Set up analytics (optional)

### Launch Day

- [ ] Deploy landing page
- [ ] Verify live site works
- [ ] Update README.md with landing page link
- [ ] Submit to Product Hunt
- [ ] Post on Hacker News (Show HN)
- [ ] Post on Reddit (r/MacApps, r/SideProject, r/productivity)
- [ ] Tweet announcement thread
- [ ] Post on LinkedIn
- [ ] Share in relevant Slack/Discord communities

### Week 1

- [ ] Monitor analytics
- [ ] Respond to comments/feedback
- [ ] Fix any bugs reported
- [ ] Update landing page based on feedback
- [ ] Reach out to Mac productivity bloggers
- [ ] Submit to app directories

## 📢 Promotion Strategy

### Day 1: Launch Announcement

**Product Hunt**:
- Best time: 12:01 AM PST
- Prepare: Screenshots, demo GIF, tagline
- Engage: Respond to all comments

**Hacker News**:
- Title: "Show HN: Clipso – AI-powered clipboard for Mac with semantic search"
- Post at 8-9 AM PST
- Be active in comments

**Reddit Posts**:

r/MacApps:
```
Title: [Open Source] Clipso - AI clipboard with semantic search
- Include screenshots
- Technical details
- Link to GitHub and landing page
```

r/SideProject:
```
Title: Built an AI-powered clipboard manager for Mac
- Focus on journey/learnings
- Tech stack
- Ask for feedback
```

**Twitter Thread**:
```
1/ Launching Clipso today 🚀

The first clipboard manager for Mac with true AI intelligence.

Find items by meaning, not just keywords. 100% private. Free forever.

Thread 🧵
[Include demo GIF]

2/ Why build this?

I was tired of losing code snippets and having to remember exact keywords to find things.

Traditional clipboard managers are basically lists with Cmd+F. We can do better.

3/ Key features:

✨ Semantic search (find "coffee recipes" → finds "espresso guide")
🎯 Auto context detection (groups your work into projects)
🔒 100% private (all AI runs locally)
💰 Free & open source

[Include comparison screenshot]

...
```

### Week 1: Build Momentum

**Blog Outreach**:
- AppleInsider tips@appleinsider.com
- 9to5Mac tips@9to5mac.com
- MacRumors tips@macrumors.com
- MacStories tips@macstories.net
- The Sweet Setup team@thesweetsetup.com

**Email Template**:
```
Subject: New open-source clipboard manager with AI semantic search

Hi [Name],

I built Clipso, an open-source clipboard manager for Mac that uses on-device AI for semantic search and context detection.

What makes it unique:
- Finds clipboard items by meaning using Apple's NLEmbedding
- Automatically detects and groups related items into projects
- 100% local processing (no cloud/subscriptions)

I thought it might interest your readers, especially developers and power users looking for privacy-focused productivity tools.

Landing page: [URL]
GitHub: [URL]

Happy to provide screenshots, demo videos, or answer questions.

Best,
[Your Name]
```

**Directory Submissions**:
- AlternativeTo
- Product Hunt alternatives pages
- MacUpdate
- Softpedia
- SourceForge
- GitHub Trending (happens organically with stars)

### Month 1: Content Marketing

**Blog Posts** (publish on Medium, Dev.to, your blog):
1. "Building a Semantic Search Engine with Apple's NLEmbedding"
2. "Why Your Clipboard Manager Needs AI"
3. "Privacy-First AI: Running Machine Learning On-Device"

**Video Content**:
- Product demo (2-3 min)
- Technical walkthrough (10 min)
- "Building in public" dev log

**Community Engagement**:
- Answer questions on GitHub issues
- Help users in discussions
- Share user testimonials
- Celebrate milestones (100 stars, 1000 downloads)

## 🎨 Assets for Promotion

All assets are in the `assets/` folder:

- **Logo**: `logo.svg` - Use for app icon, favicons
- **Banner**: `banner.svg` - GitHub README header
- **Social Card**: `social-card.svg` - Social media sharing
- **Screenshots**: Add to `assets/screenshots/` for sharing

### Creating Screenshots

Recommended screenshots to create:

1. **Hero shot**: Main window with search + results
2. **Semantic search demo**: Side-by-side showing meaning-based search
3. **Context detection**: Project tags and grouping
4. **Settings panel**: Privacy features
5. **Comparison table**: vs other clipboard managers

Use macOS screenshot tools:
- `Cmd+Shift+4` for selection
- `Cmd+Shift+5` for window capture with shadow

## 📈 Success Metrics

Track these metrics:

**Week 1**:
- GitHub stars: Target 100+
- Landing page visits: Target 1,000+
- Downloads: Target 200+

**Month 1**:
- GitHub stars: Target 500+
- Landing page visits: Target 5,000+
- Downloads: Target 1,000+
- Press mentions: Target 3+

**Month 3**:
- GitHub stars: Target 1,000+
- Active users: Estimate 500+
- Contributors: Target 5+

## 🐛 Post-Launch Issues

Common issues and fixes:

**Landing page not loading**:
- Check DNS propagation (24-48 hours for custom domains)
- Clear browser cache
- Try incognito mode

**Images not showing**:
- Verify paths are relative, not absolute
- Check case sensitivity (GitHub Pages is case-sensitive)
- Ensure all assets are committed

**Mobile layout broken**:
- Test responsive breakpoints
- Check viewport meta tag
- Validate CSS media queries

**Slow loading**:
- Minify CSS/JS
- Optimize SVGs
- Enable CDN (automatic with Vercel/Netlify)

## 🔄 Continuous Improvement

### Weekly Tasks:
- Monitor feedback
- Update based on user requests
- A/B test headlines/CTAs
- Share progress updates

### Monthly Tasks:
- Review analytics
- Refresh content
- Add new screenshots
- Update comparison table

### Quarterly Tasks:
- Major landing page redesign if needed
- New feature announcements
- Case studies/testimonials
- Press outreach

## 📝 Legal Considerations

### Privacy Policy

If collecting analytics, add a simple privacy policy:

```markdown
# Privacy Policy

Clipso landing page uses [Analytics Provider] to understand traffic.

We collect:
- Anonymous page views
- Referral sources
- General location (country level)

We do NOT collect:
- Personal information
- IP addresses
- Browsing history

The app itself collects ZERO data and never phones home.
```

### Terms of Service

For open source, usually covered by your LICENSE file (MIT recommended).

## 🎉 Launch Day Timeline

**T-1 week**:
- Finalize landing page
- Test on all devices
- Prepare social media posts
- Contact bloggers

**T-1 day**:
- Deploy landing page
- Final testing
- Queue social posts
- Prepare Product Hunt submission

**Launch Day**:
- 12:01 AM PST: Submit to Product Hunt
- 8:00 AM PST: Post to Hacker News
- 9:00 AM PST: Post to Reddit
- 10:00 AM PST: Twitter thread
- Throughout day: Engage with comments
- Evening: LinkedIn post

**T+1 day**:
- Monitor metrics
- Respond to feedback
- Fix urgent issues
- Share early metrics

## 🚀 Ready to Launch?

1. Deploy landing page
2. Test everything
3. Follow promotion strategy
4. Engage with community
5. Iterate based on feedback

Good luck! 🎉

---

**Need help?** Open an issue on GitHub or reach out to the community.
