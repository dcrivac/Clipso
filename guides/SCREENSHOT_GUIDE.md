# Screenshot Capture Guide

How to take professional screenshots of Clipso for marketing materials.

---

## 🎯 What Screenshots You Need

### Priority 1: Must-Have (Replace SVG Mockups)

1. **Hero Shot** - Main window with search results
2. **Semantic Search Demo** - Search showing meaning-based results
3. **Context Detection** - Projects view with tags
4. **Settings Panel** - Configuration options

### Priority 2: Nice-to-Have

5. **Menu Bar Integration** - App in menu bar
6. **OCR in Action** - Screenshot with extracted text
7. **Encryption Feature** - Locked item indicator
8. **Category Filters** - Filtering UI

### Priority 3: Advanced

9. **Before/After Comparison** - Traditional vs AI search
10. **Feature Montage** - Multiple features in one shot
11. **Mobile Responsive** - Landing page on different devices

---

## 🛠️ Preparation

### 1. Set Up Demo Environment

**Clean Your Mac:**
```bash
# Hide desktop icons
defaults write com.apple.finder CreateDesktop false
killall Finder

# Re-enable later:
defaults write com.apple.finder CreateDesktop true
killall Finder
```

**Prepare Test Data:**

Copy these items beforehand (for semantic search demo):
```
1. "Machine learning with Swift and CoreML"
2. "Building neural networks with TensorFlow"
3. "Deep learning tutorial for beginners"
4. "Introduction to artificial intelligence"
5. "Chocolate chip cookie recipe" (as contrast)
6. "Git version control commands" (as contrast)
```

**Settings:**
- Turn off notifications (Do Not Disturb)
- Clean menu bar (hide unnecessary icons)
- Set wallpaper to clean gradient or solid color
- Close all other apps

### 2. Configure Screenshot Tool

**macOS Built-in (⌘⇧5):**
- Options → Uncheck "Show Floating Thumbnail"
- Options → Save to: Desktop (or specific folder)
- Options → Show Mouse Pointer (for tutorials)

**CleanShot X** (Recommended if you have it):
- Better annotations
- Scrolling capture
- Background removal
- Instant upload

**Xnapper** (Alternative):
- Automatic beautification
- Nice rounded corners
- Shadow effects

---

## 📸 Screenshot Capture Instructions

### Screenshot 1: Hero Shot

**Goal**: Show the main window with semantic search in action

**Setup:**
1. Press ⌘⇧V to open Clipso
2. Type in search: "machine learning"
3. Wait for results to appear
4. Make sure 3-4 ML-related items show at top

**Capture:**
```bash
# Method 1: Window capture (⌘⇧4, then Space)
- Press ⌘⇧4
- Press Space (cursor becomes camera)
- Click on Clipso window
- Result: window with shadow, transparent background

# Method 2: Selection (⌘⇧4)
- Press ⌘⇧4
- Drag to select window area
- Include some desktop for context
```

**Post-Processing:**
- Add annotation: Arrow pointing to search bar → "Semantic AI Search"
- Add annotation: Circle around top result → "Found by meaning"
- Optional: Add subtle drop shadow if using selection method

**File Name:** `screenshot-hero-real.png`

---

### Screenshot 2: Semantic Search Comparison

**Goal**: Show keyword vs semantic side-by-side

**Setup:**
1. **Left Side (Traditional)**:
   - Search for "artificial intelligence"
   - Clear all items except one with exact match
   - Take screenshot

2. **Right Side (Clipso)**:
   - Search for "artificial intelligence"
   - Show 4+ results (ML, neural networks, deep learning, etc.)
   - Take screenshot

**Capture:**
- Take both screenshots separately
- Combine in image editor (Photoshop, Figma, Pixelmator)

**Layout:**
```
┌─────────────────┬─────────────────┐
│  Traditional    │ Clipso│
│  Clipboard      │                 │
│                 │                 │
│  Search: "AI"   │  Search: "AI"   │
│  0 results ❌   │  4 results ✅   │
└─────────────────┴─────────────────┘
```

**Annotations:**
- Left: Red "X" or "0 results"
- Right: Green checkmark or "4 results"
- Title: "The Difference AI Makes"

**File Name:** `screenshot-comparison-real.png`

---

### Screenshot 3: Context Detection

**Goal**: Show automatic project organization

**Setup:**
1. Make sure you have items from 2-3 different "projects"
2. Items should have different colored tags
3. Open main window showing tagged items

**Capture:**
- Full window capture
- Show at least 6-8 items with visible tags
- Include category filters at top

**Annotations:**
- Circle different project tags in different colors
- Add label: "Automatically organized"
- Optional: Arrow pointing to related items count

**File Name:** `screenshot-context-real.png`

---

### Screenshot 4: Settings Panel

**Goal**: Show configuration options

**Setup:**
1. Open Settings (from menu bar icon)
2. Make sure all sections visible
3. Scroll to show key features (encryption, OCR, semantic search)

**Capture:**
- If scrolling needed, use scrolling screenshot tool
- Or take 2 screenshots and stitch together

**What to Show:**
- History retention settings
- Encryption toggle (ON)
- OCR toggle (ON)
- Semantic search toggle (ON)
- Excluded apps list

**Annotations:**
- Minimal - settings speak for themselves
- Maybe highlight "Encryption: ON"

**File Name:** `screenshot-settings-real.png`

---

### Screenshot 5: Menu Bar Integration

**Goal**: Show Clipso in menu bar

**Setup:**
1. Clean up menu bar (hide unnecessary icons)
2. Click on Clipso icon
3. Show dropdown menu if any

**Capture:**
```bash
# Menu bar screenshot
- ⌘⇧4
- Select just the menu bar area
- Include Clipso icon + a few others for context
```

**Annotations:**
- Arrow pointing to icon: "Always accessible"
- Optional: Show hotkey reminder "⌘⇧V"

**File Name:** `screenshot-menubar-real.png`

---

### Screenshot 6: OCR Demo

**Goal**: Show OCR extracting text from image

**Setup:**
1. Copy a screenshot with text (e.g., tweet, code snippet)
2. Open Clipso
3. Show the image item with extracted text visible

**Capture:**
- Show clipboard history with image thumbnail
- Show OCR text extracted below it
- Make sure it's clear the text came from image

**Annotations:**
- Label: "Text extracted automatically"
- Arrow from image → extracted text

**File Name:** `screenshot-ocr-real.png`

---

## 🎨 Professional Polish

### Editing Tools

**Free:**
- **Preview** (Mac built-in): Basic annotations
- **GIMP**: Full Photoshop alternative
- **Pixelmator** ($40): Mac-native, professional

**Paid:**
- **CleanShot X** ($29): Screenshot + annotations
- **Photoshop** ($10/month): Industry standard
- **Sketch** ($99/year): Design tool

### Annotation Guidelines

**Colors:**
- **Highlights**: Use brand purple (#6366F1)
- **Arrows**: Use green (#10B981) for positive
- **Text**: Use dark gray (#111827) on white background

**Typography:**
- **Font**: Inter or SF Pro (match landing page)
- **Size**: 16-20px for labels, 14-16px for descriptions
- **Weight**: 600 (semibold) for emphasis

**Arrows & Shapes:**
- **Rounded corners**: 4-8px radius
- **Stroke width**: 2-3px
- **Shadow**: Subtle (2px blur, 20% opacity)

### Consistency Checklist

- [ ] All screenshots same scale/DPI
- [ ] Consistent window shadows
- [ ] Same annotation style across all
- [ ] Uniform text size and font
- [ ] Brand colors used correctly
- [ ] No personal info visible
- [ ] No distracting background elements

---

## 📐 Technical Specs

### Resolution & Format

**For Web:**
- **Format**: PNG (for quality)
- **Resolution**: 2x retina (e.g., 2880×1800 for display at 1440×900)
- **Compression**: TinyPNG or ImageOptim before upload

**For Print:**
- **Format**: PNG or TIFF
- **Resolution**: 300 DPI
- **Color Space**: RGB (for digital) or CMYK (if printing)

### File Sizes

Target sizes:
- **Hero shot**: <500KB
- **Comparison**: <600KB
- **Settings**: <400KB
- **Menu bar**: <200KB

Use compression:
```bash
# Install ImageOptim
brew install imageoptim-cli

# Compress all screenshots
imageoptim screenshots/*.png
```

---

## 🎬 Video Screenshots (GIFs/MP4)

### Tools

**Screen Recording:**
- **QuickTime** (free, built-in)
- **ScreenFlow** ($169, professional)
- **Kap** (free, open source)

**GIF Creation:**
- **Gifski** (free, best quality)
- **GIPHY Capture** (free)
- **Photoshop** (from video)

### Recording Tips

**Settings:**
- **Frame rate**: 30 or 60 fps
- **Resolution**: 1440×900 or 1920×1080
- **Cursor**: Show cursor, enlarge if needed

**Scenarios to Record:**

1. **Semantic Search in Action** (10 seconds)
   - Type search query
   - Show results appearing
   - Highlight relevant items

2. **Context Detection** (15 seconds)
   - Copy a few items from different apps
   - Open Clipso
   - Show items auto-grouped into projects

3. **Quick Access** (5 seconds)
   - Press ⌘⇧V
   - Window appears
   - Select item, paste

### Converting to GIF

```bash
# Using Gifski (best quality)
gifski --fps 30 --quality 90 --width 1000 input.mp4 -o output.gif

# Optimize file size
gifsicle -O3 --lossy=80 output.gif -o output-optimized.gif
```

**Target GIF size**: <5MB for social media

---

## 📱 Responsive Screenshots (Landing Page)

### Device Sizes to Capture

**Desktop:**
- 1920×1080 (Full HD)
- 1440×900 (MacBook Pro 16")
- 1280×720 (Smaller display)

**Tablet:**
- 768×1024 (iPad)
- 834×1194 (iPad Pro 11")

**Mobile:**
- 375×667 (iPhone SE)
- 390×844 (iPhone 13)
- 428×926 (iPhone 13 Pro Max)

### How to Capture

**Method 1: Browser DevTools**

```bash
# Chrome/Safari DevTools
1. Open landing page
2. Press ⌘⌥I (DevTools)
3. Click device toggle (⌘⇧M)
4. Select device size
5. Take screenshot (⌘⇧4)
```

**Method 2: Real Devices**
- Use iPhone/iPad to visit landing page
- Take screenshots
- AirDrop to Mac

**Method 3: Online Tools**
- Browserstack.com (screenshots on multiple devices)
- Responsive Screenshot Generator

---

## 🔄 Replacing Mockups

### Update Landing Page

Once you have real screenshots:

```html
<!-- Replace in index.html -->

<!-- OLD (mockup) -->
<img src="assets/screenshot-hero.svg" alt="Hero">

<!-- NEW (real screenshot) -->
<img src="assets/screenshots/hero-real.png" alt="Clipso semantic search in action">
```

### Update README

```markdown
<!-- Replace in README.md -->

<!-- OLD -->
![Semantic Search Demo](assets/screenshot-hero.svg)

<!-- NEW -->
![Semantic Search Demo](assets/screenshots/hero-real.png)
```

### Organize Files

```
assets/
├── screenshots/           ← NEW folder
│   ├── hero-real.png
│   ├── comparison-real.png
│   ├── context-real.png
│   ├── settings-real.png
│   ├── menubar-real.png
│   └── ocr-real.png
├── mockups/              ← Move SVG mockups here
│   ├── screenshot-hero.svg
│   ├── screenshot-context.svg
│   └── screenshot-search-comparison.svg
└── ... (other assets)
```

---

## ✅ Screenshot Checklist

Before publishing:

**Quality:**
- [ ] High resolution (2x retina minimum)
- [ ] No blur or artifacts
- [ ] Proper lighting (not too dark/bright)
- [ ] Clear, readable text

**Content:**
- [ ] No personal information visible
- [ ] No sensitive clipboard data
- [ ] Demo data looks professional
- [ ] UI is clean and uncluttered

**Consistency:**
- [ ] Same app version across all screenshots
- [ ] Consistent theme/appearance
- [ ] Same annotation style
- [ ] Matching brand colors

**Technical:**
- [ ] PNG format for web
- [ ] Optimized file size (<500KB each)
- [ ] Correct dimensions
- [ ] Descriptive filenames

**Legal:**
- [ ] No copyrighted content in clipboard items
- [ ] No trademarks of other apps (or used fairly)
- [ ] No private/confidential information

---

## 🎯 Using Screenshots Effectively

### Landing Page
- Hero shot above the fold
- Comparison in "Why It's Better" section
- Settings at bottom (optional)

### GitHub README
- Hero shot near top
- Comparison in features section
- Context detection in AI section

### Product Hunt
- Hero shot as main image
- 3-4 additional screenshots in gallery
- Settings/features as supporting images

### Social Media
- Hero shot for Twitter cards
- Comparison for "before/after" posts
- Short GIFs for maximum engagement

### Press Kit
- All screenshots in high resolution
- Include captions for each
- Provide both light and dark mode if applicable

---

## 💡 Pro Tips

### Taking Great Screenshots

1. **Use Real Data**: But make it demo-appropriate
   - ✅ "Machine learning tutorial"
   - ❌ "My secret API key: sk-..."

2. **Show Context**: Don't crop too tight
   - Include menu bar for realism
   - Show enough UI to understand the flow

3. **Highlight Actions**: Use annotations sparingly
   - Arrow to key feature
   - Circle important element
   - Don't over-annotate

4. **Consistent Lighting**: All screenshots should match
   - Same theme (light/dark)
   - Same time of day (if showing menubar clock)
   - Same window shadows

5. **Tell a Story**: Screenshots should flow
   - Screenshot 1: Open app
   - Screenshot 2: Search for something
   - Screenshot 3: See results
   - Screenshot 4: Success!

### Common Mistakes to Avoid

❌ **Too much clutter** - Clean desktop, minimal menu bar
❌ **Low resolution** - Always 2x retina minimum
❌ **Inconsistent styling** - Keep annotations uniform
❌ **Dark screenshots** - Ensure good lighting/contrast
❌ **Personal data** - Double-check before publishing
❌ **Outdated UI** - Re-take if app UI changes

---

## 🚀 Quick Start

**Minimum Viable Screenshots** (30 minutes):

1. **Clean your Mac** (5 min)
   - Hide desktop icons
   - Close unnecessary apps
   - Enable Do Not Disturb

2. **Prepare demo data** (5 min)
   - Copy 6-8 test items
   - Mix semantic search-friendly items

3. **Take 3 core screenshots** (15 min)
   - Hero shot (main window)
   - Search results
   - Settings panel

4. **Basic editing** (5 min)
   - Add 1-2 arrows/labels
   - Save as PNG
   - Optimize file size

**Done!** You now have enough to replace mockups.

---

## 📚 Resources

**Tutorials:**
- [Mac screenshot shortcuts guide](https://support.apple.com/en-us/HT201361)
- [How to take great product screenshots](https://www.julian.com/guide/growth/screenshots)

**Tools:**
- [CleanShot X](https://cleanshot.com) - Screenshot tool
- [ImageOptim](https://imageoptim.com) - Compression
- [Figma](https://figma.com) - Annotations and editing

**Inspiration:**
- Dribbble.com/tags/screenshot
- Product Hunt featured products
- Apple.com product pages

---

**Ready to take professional screenshots! Start with the hero shot and build from there.** 📸
