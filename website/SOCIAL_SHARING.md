# Social Sharing Setup

This document explains the social sharing meta tags configured for the Clipso website and the images you need to create.

## What's Been Added

Social sharing meta tags have been added to both `website/index.html` and `docs/index.html` to ensure beautiful previews when your site is shared on social media platforms.

### Open Graph Tags (Facebook, LinkedIn, Slack, etc.)

```html
<meta property="og:type" content="website">
<meta property="og:url" content="https://clipso.app/">
<meta property="og:title" content="Clipso - The First Truly Intelligent Clipboard for Mac">
<meta property="og:description" content="Find clipboard items by meaning, not just keywords. AI-powered semantic search. 100% private, 100% local. Free to start, Pro from $7.99/year.">
<meta property="og:image" content="https://clipso.app/og-image.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:site_name" content="Clipso">
```

### Twitter Card Tags

```html
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:url" content="https://clipso.app/">
<meta name="twitter:title" content="Clipso - The First Truly Intelligent Clipboard for Mac">
<meta name="twitter:description" content="Find clipboard items by meaning, not just keywords. AI-powered semantic search. 100% private, 100% local. Free to start, Pro from $7.99/year.">
<meta name="twitter:image" content="https://clipso.app/twitter-card.png">
```

### Additional Tags

- **Keywords**: For SEO
- **Theme color**: Brand color (#6366F1) shown in mobile browsers
- **Canonical URL**: Helps prevent duplicate content issues
- **Favicons**: App icons for browsers and bookmarks

---

## Images You Need to Create

### 1. Open Graph Image (`og-image.png`)

**Dimensions:** 1200 x 630 pixels
**Format:** PNG or JPG
**Location:** `/website/og-image.png` and `/docs/og-image.png`

**Used by:** Facebook, LinkedIn, Slack, iMessage, WhatsApp, and most social platforms

**Design Recommendations:**
- Use your brand gradient (purple #6366F1 to #8B5CF6)
- Feature the Clipso logo prominently
- Include tagline: "The First Truly Intelligent Clipboard for Mac"
- Add a visual mockup of the app interface
- Keep text large and readable (avoid small fonts)
- Leave safe margins (at least 80px on all sides)

**Example Layout:**
```
┌─────────────────────────────────────────┐
│                                         │
│   [Clipso Logo]                         │
│                                         │
│   The First Truly Intelligent          │
│   Clipboard for Mac                     │
│                                         │
│   [App Screenshot/Mockup]               │
│                                         │
│   AI-Powered • 100% Private • Free      │
│                                         │
└─────────────────────────────────────────┘
```

### 2. Twitter Card Image (`twitter-card.png`)

**Dimensions:** 1200 x 628 pixels (slightly different aspect ratio)
**Format:** PNG or JPG
**Location:** `/website/twitter-card.png` and `/docs/twitter-card.png`

**Used by:** Twitter/X exclusively

**Design Recommendations:**
- Can be identical to OG image or slightly adjusted for Twitter's style
- Ensure text is readable on mobile (Twitter is primarily mobile)
- Consider adding a subtle pattern or texture
- Test with Twitter Card Validator

### 3. Favicons

You'll need several sizes for different use cases:

**favicon-32x32.png** (32 x 32 pixels)
- Standard browser tab icon
- Location: `/website/favicon-32x32.png` and `/docs/favicon-32x32.png`

**favicon-16x16.png** (16 x 16 pixels)
- Smaller browser tab icon
- Location: `/website/favicon-16x16.png` and `/docs/favicon-16x16.png`

**apple-touch-icon.png** (180 x 180 pixels)
- iOS home screen icon
- Location: `/website/apple-touch-icon.png` and `/docs/apple-touch-icon.png`

**Design Tips for Favicons:**
- Simplify your logo for small sizes
- Use high contrast
- Test at actual size to ensure legibility
- Consider using just the gradient square with clipboard icon

---

## Creating Social Share Images

### Option 1: Design Tools

**Figma / Sketch / Adobe XD**
1. Create artboard with exact dimensions (1200x630)
2. Export as PNG at 2x resolution for retina displays
3. Optimize with TinyPNG or ImageOptim

**Canva (Easy)**
1. Use "Facebook Post" or "LinkedIn Post" template
2. Customize with brand colors and Clipso branding
3. Download as PNG

### Option 2: Code-Based Generation

Use a service like:
- **og-image.vercel.app** - Generate OG images from HTML/CSS
- **Cloudinary** - Dynamic image generation
- **Placid.app** - Template-based social images

### Option 3: Automated Tools

- **Bannerbear** - API for generating social images
- **Airtable + Zapier + Placid** - Automated workflows

---

## Quick Start: Temporary Placeholder Images

Until you create final images, you can use placeholder services:

```html
<!-- Temporary OG image -->
<meta property="og:image" content="https://placehold.co/1200x630/6366F1/FFFFFF/png?text=Clipso+%7C+Intelligent+Clipboard+for+Mac&font=Inter">

<!-- Temporary Twitter image -->
<meta name="twitter:image" content="https://placehold.co/1200x628/6366F1/FFFFFF/png?text=Clipso+%7C+AI+Clipboard&font=Inter">
```

But replace these with real images as soon as possible for professional branding.

---

## Testing Your Social Sharing

### Facebook Debugger
https://developers.facebook.com/tools/debug/

1. Enter your URL: `https://clipso.app/`
2. Click "Scrape Again" to refresh cache
3. View how your link preview will look

### Twitter Card Validator
https://cards-dev.twitter.com/validator

1. Enter your URL
2. Preview how it will appear on Twitter
3. Check for any warnings

### LinkedIn Post Inspector
https://www.linkedin.com/post-inspector/

1. Enter your URL
2. Refresh cache if needed
3. See LinkedIn preview

### Generic OG Preview
https://www.opengraph.xyz/

Quick way to see how your OG tags render

---

## Best Practices

### Image Guidelines

✅ **DO:**
- Use high-quality images (at least 72 DPI)
- Keep file sizes under 5MB (ideally under 1MB)
- Use PNG for images with text
- Use JPG for photographic backgrounds
- Test on both light and dark backgrounds
- Include your logo

❌ **DON'T:**
- Use tiny text (minimum 40px font size)
- Overcrowd with information
- Use low-resolution images
- Forget to test on mobile
- Use images with text cut off at edges

### Text Guidelines

✅ **DO:**
- Keep titles under 60 characters
- Keep descriptions under 155 characters
- Use action-oriented language
- Highlight key benefits ("AI-Powered", "100% Private")
- Match your brand voice

❌ **DON'T:**
- Write generic descriptions
- Use all caps
- Include URLs in descriptions
- Repeat the same text in title and description

---

## Image File Structure

Once created, organize your images like this:

```
website/
├── og-image.png          (1200x630 - main social share image)
├── twitter-card.png      (1200x628 - Twitter-specific)
├── favicon-32x32.png     (32x32 - browser tab)
├── favicon-16x16.png     (16x16 - smaller browser tab)
├── apple-touch-icon.png  (180x180 - iOS home screen)
└── SOCIAL_SHARING.md     (this file)

docs/
├── og-image.png
├── twitter-card.png
├── favicon-32x32.png
├── favicon-16x16.png
└── apple-touch-icon.png
```

---

## Advanced: Dynamic Social Images

For blog posts or dynamic content, consider generating unique OG images per page:

```html
<!-- Per-page customization -->
<meta property="og:title" content="<?= $page_title ?>">
<meta property="og:description" content="<?= $page_description ?>">
<meta property="og:image" content="https://clipso.app/og/<?= $page_slug ?>.png">
```

---

## Monitoring Social Shares

Track how your links are being shared:

1. **Google Analytics** - Track social referral traffic
2. **Bitly** - Create branded short links with analytics
3. **SharedCount** - See share counts across platforms
4. **BuzzSumo** - Analyze content performance

---

## Next Steps

1. **Create og-image.png** (1200x630) - Priority #1
2. **Create twitter-card.png** (1200x628) - Priority #2
3. **Generate favicons** - Use favicon.io for quick generation
4. **Test with validators** - Facebook, Twitter, LinkedIn
5. **Deploy images** to your website
6. **Clear social media caches** using debugging tools

---

## Need Help?

- **Favicon Generator**: https://favicon.io/
- **Image Optimization**: https://tinypng.com/
- **OG Image Templates**: https://www.canva.com/ (search "Open Graph")
- **Testing Tool**: https://www.opengraph.xyz/

---

**Last Updated:** 2026-01-20
**Meta Tags Added:** Open Graph, Twitter Card, Favicons, SEO keywords
