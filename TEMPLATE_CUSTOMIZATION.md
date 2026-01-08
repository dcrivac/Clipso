# Template Customization Guide

How to personalize all the marketing templates and materials for your launch.

---

## 🎯 What Needs Customization

All templates have placeholders you need to replace:

- `[Your Name]` → Your actual name
- `[Your Email]` → Contact email
- `[Twitter/GitHub handle]` → Your social handles
- `[Publication]` → Specific publication name
- `[Contact Name]` → Journalist's name
- `[Date]` → Actual dates
- `[URL when available]` → Final URLs

---

## ✏️ Step-by-Step Customization

### 1. Create Your Info Sheet

First, gather all your information in one place:

```markdown
# My Information

**Personal:**
- Name: John Doe
- Email: john@example.com
- Twitter: @johndoe
- GitHub: github.com/johndoe
- LinkedIn: linkedin.com/in/johndoe
- Website: johndoe.dev

**Project URLs:**
- Landing Page: https://dcrivac.github.io/Clipso/
- GitHub Repo: https://github.com/dcrivac/Clipso
- Demo Video: https://youtube.com/watch?v=xxxxx
- Blog: https://johndoe.dev/blog

**Launch Details:**
- Launch Date: January 15, 2025
- Product Hunt URL: https://producthunt.com/posts/clipboardmanager
- Time Zone: PST (UTC-8)

**Stats (update as available):**
- GitHub Stars: [check live]
- Downloads: [track weekly]
- Users: [estimate from analytics]
```

**Save this as**: `MY_INFO.md` (add to .gitignore)

---

### 2. Customize Press Templates

#### File: `PRESS_OUTREACH.md`

**Find and Replace:**

```bash
# In each email template, replace:

[Your Name] → John Doe
[Twitter/Email] → john@example.com
[GitHub handle] → @johndoe
```

**Example - Template 1 (Major Mac Blogs):**

**BEFORE:**
```
Let me know if you'd like more information!

Best,
[Your Name]
[Twitter/Email]
```

**AFTER:**
```
Let me know if you'd like more information!

Best,
John Doe
john@example.com
Twitter: @johndoe
```

**Personalization Tips:**

For each publication, add personal touch:

```markdown
Hi 9to5Mac team,

I'm a regular reader and loved your recent article on [specific article].

I built Clipso...
```

**How to find recent articles:**
1. Visit publication website
2. Search for "clipboard" or "productivity" or "Mac apps"
3. Reference a recent article (within 2-3 months)

**Example:**
```
Hi 9to5Mac team,

I loved your article last month about the best Mac productivity tools.
I built Clipso, which might interest your readers...
```

---

### 3. Customize Product Hunt Materials

#### File: `PRODUCT_HUNT_LAUNCH.md`

**Customize First Comment:**

**BEFORE:**
```markdown
👋 Hey Product Hunt! I'm [Your Name], and I built Clipso.
...
Ask me anything! I'll be here all day responding to comments.

Thanks for checking it out! 🚀

---

🌐 Website: [link]
💻 GitHub: [link]
📺 Demo: [link]
```

**AFTER:**
```markdown
👋 Hey Product Hunt! I'm John Doe, and I built Clipso.
...
Ask me anything! I'll be here all day responding to comments.

Thanks for checking it out! 🚀

---

🌐 Website: https://dcrivac.github.io/Clipso/
💻 GitHub: https://github.com/dcrivac/Clipso
📺 Demo: https://youtube.com/watch?v=xxxxx
```

**Add Personal Touch:**

Include a brief intro about yourself:

```markdown
👋 Hey Product Hunt! I'm John Doe, a software engineer from San Francisco.

I built Clipso because I was frustrated with...
[rest of template]
```

Or:

```markdown
👋 Hey Product Hunt! I'm John Doe, indie developer and privacy advocate.

After trying every clipboard manager and finding none that...
[rest of template]
```

---

### 4. Customize Blog Posts

#### File: `blog/product-launch.md`

**Add Author Bio:**

At the end, add:

```markdown
---

## About the Author

John Doe is a software engineer passionate about privacy-first development.
He previously worked at [Company] and contributes to several open-source projects.

Follow him on [Twitter](@johndoe) for updates on Clipso and other projects.
```

#### File: `blog/technical-deep-dive.md`

**Personalize Introduction:**

**BEFORE:**
```markdown
I built Clipso...
```

**AFTER:**
```markdown
I'm John Doe, and I built Clipso after years of frustration
with traditional clipboard managers. As a developer who copies hundreds
of code snippets daily, I needed something smarter.
```

---

### 5. Update Landing Page

#### File: `index.html`

**Footer Contact:**

**Line ~595 (footer):**

**BEFORE:**
```html
<p>&copy; 2025 Clipso. Open Source Project.</p>
```

**AFTER:**
```html
<p>&copy; 2025 Clipso by John Doe. Open Source Project.</p>
<p><a href="mailto:john@example.com">Contact</a> •
   <a href="https://twitter.com/johndoe">@johndoe</a></p>
```

**Add Newsletter Signup (Optional):**

Before footer, add:

```html
<!-- Newsletter Signup -->
<section class="newsletter">
  <div class="container">
    <h2>Get Updates</h2>
    <p>Be the first to know about new features and updates</p>
    <form action="https://yourlist.com/subscribe" method="post">
      <input type="email" placeholder="your@email.com" required>
      <button type="submit" class="btn-primary">Subscribe</button>
    </form>
  </div>
</section>
```

---

### 6. Customize Demo Video Script

#### File: `DEMO_VIDEO_SCRIPT.md`

**Voiceover Personalization:**

**BEFORE (Scene 2):**
```
Meet Clipso - the first clipboard for Mac with true AI intelligence.
And it's completely free.
```

**AFTER:**
```
Hey, I'm John Doe. I built Clipso - the first clipboard for Mac
with true AI intelligence. And it's completely free.
```

**End Card:**

Add your info to the end card:

```
Clipso
By John Doe

Download: github.com/dcrivac/Clipso
Follow: @johndoe
```

---

### 7. Add Personal Touch to Social Posts

#### Twitter Launch Thread

**Template in MARKETING.md:**

**BEFORE:**
```
Introducing Clipso: the first clipboard for Mac
with true AI intelligence 🤖
```

**AFTER:**
```
After months of building, I'm launching Clipso! 🚀

As a developer, I copy 100+ things daily. Finding them later was
a nightmare - until now.

The first clipboard for Mac with true AI intelligence 🤖

Thread 🧵
```

**Add Personal Story:**

```
2/ The lightbulb moment:

I was working on a ML project, copied snippets about "neural networks"
and "TensorFlow".

Later, I searched my clipboard for "AI" → 0 results.

That's when I knew clipboard managers needed to evolve.
```

---

## 🎨 Brand Customization

### Update Colors (Optional)

If you want different brand colors:

#### File: `styles.css`

**Lines 1-12 (CSS variables):**

**CURRENT:**
```css
:root {
    --primary: #6366F1;        /* Indigo */
    --primary-dark: #4F46E5;
    --secondary: #8B5CF6;      /* Purple */
    --accent: #10B981;         /* Green */
    ...
}
```

**CUSTOM EXAMPLE:**
```css
:root {
    --primary: #3B82F6;        /* Blue */
    --primary-dark: #2563EB;
    --secondary: #06B6D4;      /* Cyan */
    --accent: #10B981;         /* Keep green */
    ...
}
```

**Then update SVG graphics** to match in:
- `assets/logo.svg`
- `assets/banner.svg`
- `assets/social-*.svg`

---

## 📧 Email Signature

Create a consistent email signature for outreach:

```
--
John Doe
Creator of Clipso
https://github.com/dcrivac/Clipso
@johndoe on Twitter
```

Or professional version:

```
--
John Doe
Software Engineer & Open Source Developer
john@example.com
Clipso: https://dcrivac.github.io/Clipso/
```

---

## 🔗 URL Management

### Create Short Links (Optional)

For easier sharing, create short URLs:

**Tools:**
- **Bitly**: bit.ly/clipboardmanager
- **TinyURL**: tinyurl.com/clipboard-ai
- **Custom domain**: clip.yourdomain.com

**Use Cases:**
- Social media posts (character limit)
- Print materials (QR codes)
- Verbal mentions (podcasts/videos)

**Example:**
```
Instead of: https://dcrivac.github.io/Clipso/
Use: clip.ai (if you own domain)
```

---

## 📋 Customization Checklist

Use this to track what you've customized:

### Email Templates
- [ ] PRESS_OUTREACH.md - all 4 templates updated
- [ ] Added your name/email to each template
- [ ] Personalized for top 5 publications
- [ ] Created email signature

### Product Hunt
- [ ] First comment customized with your name
- [ ] Added personal intro/story
- [ ] Updated all URLs (website, GitHub, demo)
- [ ] Prepared response templates with your voice

### Blog Posts
- [ ] Added author bio to product-launch.md
- [ ] Added author bio to technical-deep-dive.md
- [ ] Personalized introductions
- [ ] Updated all [Your Name] placeholders

### Landing Page
- [ ] Updated footer with your info
- [ ] Added contact links (email, Twitter)
- [ ] Optional: Added newsletter signup
- [ ] Optional: Customized brand colors

### Social Media
- [ ] Prepared Twitter bio update
- [ ] Created profile images (if needed)
- [ ] Personalized launch tweets
- [ ] Added personal story elements

### Video Script
- [ ] Added personal intro to voiceover
- [ ] Updated end card with your info
- [ ] Customized "About" section if uploading to YouTube

### General
- [ ] Created MY_INFO.md with all details
- [ ] All [placeholder] text replaced
- [ ] URLs confirmed working
- [ ] Email address monitored
- [ ] Social profiles updated

---

## 🎯 Quick Replace Script

For faster customization, use find-and-replace:

### macOS/Linux:

```bash
# Replace all instances of [Your Name] in markdown files
find . -name "*.md" -type f -exec sed -i '' 's/\[Your Name\]/John Doe/g' {} +

# Replace email
find . -name "*.md" -type f -exec sed -i '' 's/\[your email\]/john@example.com/g' {} +

# Replace Twitter
find . -name "*.md" -type f -exec sed -i '' 's/@\[handle\]/@johndoe/g' {} +
```

**WARNING**: Test on one file first! Make a backup:
```bash
cp PRESS_OUTREACH.md PRESS_OUTREACH.md.backup
```

### VS Code (Find and Replace):

1. Open project folder in VS Code
2. Press `⌘⇧F` (Find in Files)
3. Enter: `[Your Name]`
4. Enter replacement: `John Doe`
5. Click "Replace All" (or review each one)

Repeat for:
- `[your email]`
- `[Twitter handle]`
- `[GitHub handle]`
- `[Date]`

---

## 💡 Personalization Tips

### Make It Yours

**Don't just fill in blanks** - add personality:

**Generic:**
```
I built Clipso because I needed it.
```

**Personal:**
```
I built Clipso after losing an important API key for the third
time in a week. As a developer with ADHD, I copy dozens of things and
completely forget where they went. Sound familiar?
```

### Share Your Why

People connect with stories:

**Template:**
```
I built this because [specific problem].

I tried [competitors] but [what was missing].

So I built [your solution] with [unique approach].

The result: [benefit you experienced].
```

**Example:**
```
I built this because I was tired of losing important code snippets.

I tried Paste and Copied, but they still used basic keyword search
and sent my data to the cloud.

So I built Clipso with true semantic AI that runs 100% locally.

The result: I haven't lost a single clipboard item in 3 months.
```

### Add Personality to Templates

**Press email** - mention specific articles:
```
Hi [Publication],

I loved your piece on [specific article]. You mentioned [point from article].

That's actually what inspired me to solve this problem with Clipso...
```

**Product Hunt** - share the journey:
```
Fun fact: I built the first version in a weekend during a hackathon.
Then spent 3 months refining it based on feedback from 50 beta testers.

The semantic search algorithm went through 12 iterations before I got
it right. Happy to share what I learned!
```

---

## 📝 Sample Fully Customized Email

**Before (Template):**
```
Subject: New open-source Mac app: Clipboard manager with AI semantic search

Hi [Publication] team,

I built Clipso, an open-source clipboard manager for macOS...

Let me know if you'd like more information!

Best,
[Your Name]
[Twitter/Email]
```

**After (Personalized):**
```
Subject: Clipboard manager with local AI (no cloud) - thought you'd be interested

Hi Michael,

I'm a long-time 9to5Mac reader - loved your recent article on the best
Mac productivity apps of 2024. You mentioned clipboard managers briefly,
which is perfect timing.

I just launched Clipso, an open-source clipboard manager that
does something none of the ones you covered do: semantic AI search that
runs 100% locally.

What makes it newsworthy for your readers:

• First clipboard with on-device semantic search (using Apple's NLEmbedding)
• Auto context detection - organizes itself into projects
• 100% private - zero cloud/network (unlike Paste/Copied)
• Free forever - no $15/year subscription

As a developer working on multiple projects, I was frustrated that searching
my clipboard for "AI" wouldn't find items about "machine learning" or
"neural networks". That's what inspired building this.

Technical specs:
- Native Swift + SwiftUI
- NLEmbedding for 50-dimensional semantic vectors
- <50ms search on 1000 items
- macOS 13.0+
- Fully open source for verification

Links:
- Live demo: https://dcrivac.github.io/Clipso/
- GitHub: https://github.com/dcrivac/Clipso
- Demo video: https://youtube.com/watch?v=xxxxx

I think this would resonate with your readers who care about privacy
and productivity. Happy to provide a review build, additional screenshots,
or answer any questions.

Best regards,
John Doe
john@example.com
@johndoe

PS: The source code shows exactly how the privacy works - no hidden
telemetry or tracking. Everything verifiable.
```

**What changed:**
✅ Personalized greeting (Michael vs "team")
✅ Referenced specific article
✅ Added personal motivation
✅ Explained technical details clearly
✅ Included all contact info
✅ Added personal touch (PS)

---

## 🚀 Ready to Customize!

**Time investment**: 2-3 hours to properly customize all templates

**Priority order:**
1. Create MY_INFO.md (15 min)
2. Customize press emails (45 min)
3. Customize Product Hunt (30 min)
4. Update landing page footer (15 min)
5. Personalize blog posts (30 min)
6. Everything else (30 min)

**Remember**: Authentic personalization beats perfect templates.
Your story, your voice, your passion - that's what connects with people.

Good luck! 🎉
