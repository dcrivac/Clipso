# Make Your Demo Video in 30 Minutes

**Tools needed:** Just your Mac (everything is built-in)

---

## Step 1: Prepare (5 minutes)

### Clean Your Desktop
```bash
# Hide desktop icons temporarily
defaults write com.apple.finder CreateDesktop -bool false
killall Finder

# To undo later:
# defaults write com.apple.finder CreateDesktop -bool true
# killall Finder
```

### Set Up Sample Data

Open Clipso and copy these items in order:

```
1. "Neural networks are powerful for pattern recognition"
2. "TensorFlow makes machine learning accessible"
3. "Deep learning requires large datasets"
4. "Buy milk and eggs from the store"
5. "func calculateDistance(x: Double, y: Double) -> Double"
6. "Meeting at 3pm tomorrow with the team"
```

---

## Step 2: Record Screen (10 minutes)

### Start Recording

1. Press **⌘ + Shift + 5**
2. Click **"Record Entire Screen"** or **"Record Selected Portion"**
3. Click **"Options"** → Select **"None"** for mouse clicks (cleaner look)
4. Click **"Record"**

### Record These 5 Scenes

**Scene 1: The Problem (20 seconds)**
- Open Clipso with ⌘⇧V
- Type in search: "AI"
- Show: 0 results (because you have "neural networks", "TensorFlow", etc.)
- Pause for 2 seconds so viewers see the empty results

**Scene 2: The Solution (30 seconds)**
- Click the "Semantic Search" toggle
- Type in search: "AI" again
- Show: 3 results appear (neural networks, TensorFlow, deep learning)
- Click on each result to highlight it
- Pause for 2 seconds

**Scene 3: Context Detection (20 seconds)**
- Show your clipboard list with mixed items
- Click "Auto-detect contexts" or show the context groups
- Show items automatically sorted: Work, Shopping, Personal

**Scene 4: OCR Demo (20 seconds)**
- Have a screenshot with text ready
- Copy the screenshot
- Show Clipso extracting the text automatically
- Highlight the extracted text

**Scene 5: Call to Action (10 seconds)**
- Show the GitHub page: github.com/dcrivac/Clipso
- Show the "Download" or "Clone" button

### Stop Recording
- Press **⌘ + Ctrl + Esc** to stop
- Video saves to Desktop automatically

---

## Step 3: Edit (10 minutes)

### Open in iMovie

1. Open **iMovie**
2. Click **"Create New"** → **"Movie"**
3. Drag your screen recording from Desktop into iMovie

### Add Title Cards

**Opening Title (3 seconds):**
```
"Clipso"
The Intelligent Clipboard for Mac
```

**Add between scenes:**
- After Scene 1: "❌ Traditional Search: 0 Results"
- After Scene 2: "✅ Semantic Search: Found Everything"
- After Scene 3: "🎯 Auto-Organizes by Context"
- After Scene 4: "🖼️ Built-in OCR"

**To add titles in iMovie:**
1. Click **"Titles"** at top
2. Drag **"Lower Third"** or **"Centered"** to timeline
3. Double-click to edit text
4. Keep it on screen for 2-3 seconds

### Add Background Music (Optional)

1. Click **"Audio"** at top
2. Search **"Corporate"** or **"Tech"** in iMovie's sound effects
3. Drag to timeline below video
4. Lower volume to **15-20%** (so it doesn't overpower)

### Trim and Arrange

- Total target length: **90 seconds to 2 minutes**
- Trim dead space between actions
- Keep movements smooth and deliberate

---

## Step 4: Export (5 minutes)

1. Click **"Share"** button (top right)
2. Select **"File"**
3. Settings:
   - Resolution: **1080p**
   - Quality: **High**
   - Compress: **Faster**
4. Save as: `Clipso-Demo.mp4`
5. Click **"Next"** → **"Save"**

Wait 2-3 minutes for export to complete.

---

## Step 5: Upload

### To YouTube (Unlisted):
1. Go to studio.youtube.com
2. Click **"Create"** → **"Upload video"**
3. Upload `Clipso-Demo.mp4`
4. Set visibility: **Unlisted** (not public yet)
5. Copy the URL

### Add to Landing Page:
Open `index.html` and add after line 100:

```html
<!-- Demo Video Section -->
<section class="demo-video">
  <div class="container">
    <h2>See It In Action</h2>
    <div class="video-wrapper">
      <iframe width="800" height="450"
        src="https://www.youtube.com/embed/YOUR_VIDEO_ID"
        frameborder="0" allowfullscreen>
      </iframe>
    </div>
  </div>
</section>
```

Replace `YOUR_VIDEO_ID` with the ID from your YouTube URL.

---

## Even Faster: Silent Demo (15 minutes)

**Skip voiceover entirely:**

1. Record screen (5 min)
2. Add text overlays explaining each scene (5 min)
3. Add background music (2 min)
4. Export (3 min)

**Text overlays say:**
- "Search for 'AI' finds nothing with keyword search"
- "Same search finds everything with semantic search"
- "Automatically organizes into project contexts"
- "Free and open source"

This works great for social media where videos autoplay muted anyway.

---

## Quick Checklist

- [ ] Clean desktop, hide icons
- [ ] Add sample clipboard items
- [ ] Press ⌘⇧5 to start recording
- [ ] Record 5 scenes (each under 30 seconds)
- [ ] Stop recording (⌘ Ctrl Esc)
- [ ] Open video in iMovie
- [ ] Add title cards between scenes
- [ ] Add background music (optional)
- [ ] Export as 1080p MP4
- [ ] Upload to YouTube (unlisted)
- [ ] Add to landing page

**Total time:** 30 minutes
**Cost:** $0 (all built-in tools)
**Quality:** Professional enough for launch

---

## Pro Tips

**1. Record Multiple Takes**
- If you mess up, just start that scene again
- Record 2-3 takes of each scene
- Pick the best one in editing

**2. Slow Down**
- Move mouse slower than normal
- Pause after each action (1-2 seconds)
- Viewers need time to read text

**3. Use Keyboard Shortcuts**
- Don't fumble with menus
- Practice the actions before recording
- Smooth keyboard shortcuts look professional

**4. Keep It Short**
- 90 seconds is perfect for social media
- 2 minutes max for website
- People's attention spans are short

**5. No Voiceover Needed**
- Text overlays work great
- Easier than recording audio
- Works on muted autoplay

---

## Sample Timeline (90 seconds total)

```
0:00 - 0:03   Title card: "Clipso"
0:03 - 0:23   Scene 1: Problem (keyword search fails)
0:23 - 0:26   Text: "❌ Traditional Search: 0 Results"
0:26 - 0:56   Scene 2: Solution (semantic search works)
0:56 - 0:59   Text: "✅ Semantic Search: Found Everything"
0:59 - 1:19   Scene 3: Context detection
1:19 - 1:22   Text: "🎯 Auto-Organizes by Context"
1:22 - 1:27   Scene 4: Call to action
1:27 - 1:30   Final card: "github.com/dcrivac/Clipso"
```

---

## What You'll Have

- ✅ Professional demo video
- ✅ Under 2 minutes long
- ✅ Shows key features clearly
- ✅ Ready for YouTube, Twitter, Product Hunt
- ✅ Created in 30 minutes with free tools

**Now go make it!** 🎬
