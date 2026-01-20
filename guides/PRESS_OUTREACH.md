# Press & Media Outreach Guide

Email templates and outreach strategy for Clipso launch.

---

## Target Publications

### Tier 1: Major Mac/Tech Blogs

| Publication | Contact | Best Time | Notes |
|------------|---------|-----------|-------|
| **9to5Mac** | tips@9to5mac.com | Tue-Thu, 9AM ET | Big reach, covers new Mac apps |
| **MacRumors** | tips@macrumors.com | Mon-Wed, 10AM ET | News-focused, loves open source |
| **AppleInsider** | tips@appleinsider.com | Tue-Thu, 8AM ET | Technical audience |
| **MacStories** | tips@macstories.net | Wed-Fri, 11AM ET | Deep dives, Federico loves productivity |
| **The Sweet Setup** | team@thesweetsetup.com | Any day, 10AM ET | App recommendations |

### Tier 2: Productivity & Developer

| Publication | Contact | Best Time | Notes |
|------------|---------|-----------|-------|
| **Product Hunt** | Launch on site | 12:01AM PST | Community-driven |
| **Hacker News** | Show HN post | 8-9AM PST | Technical audience |
| **MacWorld** | www.macworld.com/about/contact | Tue-Thu | General Mac audience |
| **The Verge** | tips@theverge.com | Wed-Fri | Consumer tech |

### Tier 3: Niche/Community

| Publication | Contact | Best Time | Notes |
|------------|---------|-----------|-------|
| **iMore** | tips@imore.com | Any weekday | Apple ecosystem |
| **Cult of Mac** | tips@cultofmac.com | Mon-Thu | Apple enthusiasts |
| **MacG** (French) | web@macg.co | Any weekday | French Mac users |
| **Daring Fireball** | Twitter DM | - | Influencer, picky |

---

## Email Templates

### Template 1: Major Mac Blogs (Tier 1)

**Subject**: New open-source Mac app: Clipboard manager with AI semantic search

**Body**:

```
Hi [Publication] team,

I built Clipso, an open-source clipboard manager for macOS with a unique feature: semantic search powered by Apple's on-device ML.

What makes it newsworthy:

• **First clipboard with semantic search** - Find items by meaning, not keywords
  Example: Search "coffee recipes" → finds "espresso brewing guide"

• **Auto context detection** - Automatically organizes clipboard into projects
  No manual tagging needed

• **100% private** - All AI runs locally using Apple's NLEmbedding framework
  Zero network requests, zero cloud storage

• **Fair pricing** - Free tier + $7.99/year Premium (47% cheaper than Paste)
  Generous free tier with 10 AI searches/day, open source

Unlike competitors (Paste $15/year, Copied $10/year) that require cloud sync, Clipso keeps everything on-device at half the price while providing superior semantic search.

Technical details:
- Built with Swift + SwiftUI
- Uses NLEmbedding for 50-dimensional semantic vectors
- <50ms search on 1000 items
- macOS 13.0+

I think your readers would find this interesting, especially developers and privacy-conscious users.

Links:
- Website: https://dcrivac.github.io/Clipso/
- GitHub: https://github.com/dcrivac/Clipso
- Demo video: [URL when available]

Happy to provide:
- Screenshots
- Demo access
- Technical deep dive
- Interview

Let me know if you'd like more information!

Best,
[Your Name]
[Twitter/Email]
```

---

### Template 2: Developer/Technical Publications

**Subject**: Show HN: Clipboard manager with semantic search using Apple's NLEmbedding

**Body**:

```
Hi [Publication],

I'm launching Clipso, a clipboard manager for macOS that implements semantic search using Apple's on-device NLEmbedding framework.

Technical highlights:

**Semantic Search Implementation:**
- Uses NLEmbedding to generate 50-dimensional vectors
- Cosine similarity for semantic matching
- Hybrid ranking: 40% keyword + 30% semantic + 20% recency + 10% frequency
- <100ms embedding generation, <50ms search on 1000 items

**Context Detection Algorithms:**
- App pattern recognition (detects project clusters)
- Time-window clustering (30-minute sessions)
- Content similarity hierarchical clustering

**Privacy-First Architecture:**
- 100% local processing with Apple's frameworks
- Zero network requests (verifiable in source)
- Optional AES-256-GCM encryption
- No telemetry, no analytics

**Performance:**
- ~50MB RAM with 1000 items + embeddings
- ~2MB database for 1000 items
- Native Swift/SwiftUI, zero dependencies

Why this matters:

Most clipboard managers still do basic keyword matching. This demonstrates that on-device ML (specifically NLEmbedding) is powerful enough for semantic search without cloud APIs - giving users both intelligence AND privacy.

The code is fully open source, so developers can see exactly how it works and contribute.

Links:
- Source: https://github.com/dcrivac/Clipso
- Technical deep dive: [blog post URL]
- Architecture docs: README.md

I'd love to write a technical post about implementing semantic search with NLEmbedding if you're interested.

Thanks,
[Your Name]
[GitHub handle]
```

---

### Template 3: Privacy/Security Focused

**Subject**: Privacy-first clipboard manager with local AI (no cloud)

**Body**:

```
Hi [Contact Name],

Given [Publication's] focus on privacy, I thought you might be interested in Clipso - a clipboard manager that does AI-powered semantic search entirely on-device.

The privacy angle:

**Zero Cloud Dependency:**
- All AI processing uses Apple's NLEmbedding framework (local)
- No network requests (verifiable in source code)
- No telemetry, no analytics, no tracking
- Optional AES-256-GCM encryption with Keychain-backed keys

**Open Source Transparency:**
- Full source available on GitHub
- Security researchers can verify claims
- No proprietary "black box" components

**Contrast with Competitors:**
- Paste: Requires iCloud sync (data on Apple's servers)
- Copied: Cloud storage required
- Most AI clipboards: Send data to OpenAI/Anthropic APIs

Clipso proves you can have intelligent features (semantic search, context detection) without sacrificing privacy. It's all possible with Apple's on-device ML frameworks.

This challenges the narrative that AI features require cloud APIs.

Would you be interested in covering this as an example of privacy-preserving AI?

Links:
- Website: https://dcrivac.github.io/Clipso/
- Source: https://github.com/dcrivac/Clipso
- Privacy documentation: [README section]

I can provide a demo or answer any technical questions about the privacy architecture.

Best regards,
[Your Name]
```

---

### Template 4: Follow-Up (1 Week Later)

**Subject**: Re: Clipso - semantic clipboard for Mac

**Body**:

```
Hi [Contact Name],

Following up on my email from [date] about Clipso.

Quick update: Since launch, we've had:
- [X] GitHub stars
- [X] downloads
- Featured on Product Hunt [if applicable]
- [Any notable testimonials/tweets]

I wanted to make sure this reached you as I think it would resonate with your audience - especially the combination of AI features with 100% local processing.

Happy to provide:
- Review access
- Screenshots/demo video
- Technical interview
- Guest post about building privacy-first AI

Let me know if you'd like more information!

Thanks,
[Your Name]
```

---

## Outreach Strategy

### Week 1: Soft Launch

**Monday:**
- [ ] Product Hunt submission (12:01 AM PST)
- [ ] Hacker News (8 AM PST)
- [ ] Personal social media

**Tuesday:**
- [ ] Email Tier 2 publications
- [ ] Post to Reddit (r/MacApps, r/SideProject)

**Wednesday:**
- [ ] Email Tier 1 publications
- [ ] Twitter thread

**Thursday-Friday:**
- [ ] Respond to all comments/emails
- [ ] Monitor analytics
- [ ] Fix any reported bugs

### Week 2: Amplification

**Monday:**
- [ ] Follow up with non-responders
- [ ] Reach out to developers/influencers

**Tuesday-Wednesday:**
- [ ] Publish blog posts (Medium, Dev.to)
- [ ] Share to relevant communities

**Thursday-Friday:**
- [ ] Pitch Tier 3 publications
- [ ] Analyze what's working

### Week 3+: Long Tail

- Weekly blog posts
- Community engagement
- Feature updates
- User testimonials

---

## Email Best Practices

### Do's

✅ **Personalize**: Reference specific articles they've written
✅ **Be concise**: Journalists are busy
✅ **Lead with newsworthiness**: Why NOW?
✅ **Provide assets**: Make their job easy
✅ **Follow up once**: After 1 week, no more
✅ **Time it right**: Tuesday-Thursday, 9-11 AM their timezone

### Don'ts

❌ **Don't spam**: One email per publication
❌ **Don't be pushy**: Accept rejections gracefully
❌ **Don't send attachments**: Link instead
❌ **Don't mass BCC**: Personalize each email
❌ **Don't follow up multiple times**: Once is enough

---

## Press Kit

Create a folder with assets for journalists:

```
press-kit/
├── logo.png (high-res)
├── screenshots/
│   ├── hero-shot.png
│   ├── semantic-search-demo.png
│   └── context-detection.png
├── fact-sheet.md
├── founder-bio.md
└── demo-video.mp4
```

**Host on GitHub**: `https://github.com/dcrivac/Clipso/tree/main/press-kit`

---

## Sample Fact Sheet

```markdown
# Clipso Fact Sheet

## What
Open-source clipboard manager for macOS with AI-powered semantic search and automatic context detection.

## Key Features
- Semantic search using Apple's NLEmbedding framework
- Automatic project organization via context detection
- 100% local processing (zero cloud/network requests)
- Built-in OCR, encryption, smart categorization
- Free tier + $7.99/year Premium (47% cheaper than Paste)

## Technical
- Built with Swift + SwiftUI
- Uses Apple's NaturalLanguage, Vision, Core Data, CryptoKit
- macOS 13.0+
- <50ms search on 1000 items
- ~50MB RAM usage

## Differentiation
- Only clipboard with semantic AI search
- Only one that's 100% private (competitors use cloud)
- $7.99/year Premium vs $10-15/year competitors (47% cheaper than Paste)
- Generous free tier with 10 AI searches/day

## Availability
- Free download: github.com/dcrivac/Clipso
- Open source under [License]
- Launch date: [Date]

## Contact
- Email: [your email]
- Twitter: @[handle]
- Website: [URL]

## Media Assets
- Screenshots: [link]
- Logo: [link]
- Demo video: [link]
```

---

## Influencer Outreach

### Twitter Developers/Influencers

**DM Template**:

```
Hi [Name]! I built an open-source clipboard manager for Mac with semantic search using Apple's NLEmbedding (no cloud!).

Thought you might find it interesting given your work on [their project/interest].

Free download: [link]

Would love your feedback!
```

### YouTube Creators

**Email Template**:

```
Subject: App review opportunity: AI clipboard manager

Hi [Creator Name],

I'm a fan of your Mac productivity videos, especially [specific video].

I built Clipso, a clipboard manager with AI semantic search that works completely offline. Generous free tier + $7.99/year Premium (47% cheaper than Paste). I think it would make a great video for your audience.

Unique angles for a video:
- First clipboard with semantic AI
- 100% private (no cloud)
- $7.99/year vs $10-15 competitors (better pricing + better privacy)

I can provide:
- Demo access
- Talking points
- Technical support
- Promotion on our channels

Let me know if you're interested!

Best,
[Your Name]
```

---

## Tracking Responses

Use a spreadsheet:

| Publication | Email Sent | Response? | Coverage? | Notes |
|------------|-----------|-----------|-----------|-------|
| 9to5Mac | 2025-01-15 | Yes | Pending | Interested, wants screenshots |
| MacRumors | 2025-01-15 | No | - | Follow up 1/22 |
| Product Hunt | 2025-01-15 | N/A | Featured | #3 of the day |

---

## Success Metrics

**Week 1 Goals:**
- 3+ publication mentions
- 100+ GitHub stars
- 500+ downloads

**Month 1 Goals:**
- 10+ publication mentions
- 500+ GitHub stars
- 2000+ downloads
- 1+ major publication feature

---

## Templates for Different Scenarios

### Podcast Interview Request

```
Subject: Podcast guest: Building privacy-first AI

Hi [Host],

Love your podcast, especially the episode on [topic].

I recently built Clipso, an open-source Mac app that does semantic AI search entirely on-device (no cloud). I think the privacy angle would resonate with your audience.

Potential discussion topics:
- How to build AI features without cloud APIs
- Privacy-first development practices
- Competing with paid apps as open source

I'm available [dates/times]. Let me know if you're interested!

[Your Name]
```

### Guest Post Pitch

```
Subject: Guest post idea: "Building Semantic Search with Apple's NLEmbedding"

Hi [Editor],

I enjoyed your article on [topic]. I recently implemented semantic search in a Mac app using Apple's on-device NLEmbedding framework.

Proposed article:
- Title: "How to Build Semantic Search Without Cloud APIs"
- Angle: Privacy-preserving AI using Apple's frameworks
- Length: 2000-2500 words
- Code examples included
- Audience: iOS/macOS developers

I've open-sourced the full implementation for reference.

Would this fit your editorial calendar?

Thanks,
[Your Name]
```

---

## Crisis Management

### If Someone Finds a Bug

**Response Template**:

```
Thank you for reporting this! I've reproduced the bug and will have a fix out within [24/48] hours.

In the meantime, here's a workaround: [if applicable]

I really appreciate you taking the time to test and report this.

[Your Name]
```

### If Someone Has Privacy Concerns

**Response Template**:

```
Great question! Privacy is our #1 priority.

Here's exactly what Clipso does:
- [Specific technical explanation]
- You can verify this in the source code: [link to relevant code]

We've also had [security researcher if applicable] review the code.

If you have any other concerns, I'm happy to address them!
```

---

## Final Checklist

Before sending outreach:

- [ ] Landing page is live
- [ ] Demo video uploaded
- [ ] Screenshots ready
- [ ] GitHub repo clean and documented
- [ ] Press kit assembled
- [ ] Personal social profiles updated
- [ ] Ready to respond to questions quickly
- [ ] Email signature has links

---

**Remember**: Be genuine, be helpful, and focus on what makes Clipso truly different. The privacy + AI angle is unique and newsworthy.

Good luck! 🚀
