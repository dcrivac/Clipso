# Landing Page

This directory contains the marketing landing page for Clipso.

## Files

- `index.html` - Main landing page
- `styles.css` - Styling and responsive design
- `script.js` - Interactive features and animations
- `assets/` - Logos, banners, and social media cards

## Quick Start

### View Locally

Simply open `index.html` in your browser:

```bash
open index.html
# or
python3 -m http.server 8000
# then visit http://localhost:8000
```

### Deploy

**GitHub Pages** (easiest):
1. Push to GitHub
2. Enable Pages in repo Settings
3. Done! URL: `https://dcrivac.github.io/Clipso/`

**Vercel/Netlify** (best performance):
```bash
# Vercel
vercel

# Netlify
netlify deploy
```

See [LAUNCH_GUIDE.md](LAUNCH_GUIDE.md) for detailed deployment instructions.

## Customization

### Update Links

Replace GitHub URLs in:
- `index.html` - All `href` attributes
- Update repository owner if needed

### Change Colors

Edit CSS variables in `styles.css`:

```css
:root {
    --primary: #6366F1;      /* Main brand color */
    --secondary: #8B5CF6;    /* Accent color */
    --accent: #10B981;       /* Success/highlight */
}
```

### Modify Content

All content is in `index.html`:
- Hero section: Lines 30-80
- Features: Lines 150-350
- Comparison table: Lines 400-500

## Marketing Assets

Located in `assets/`:

- `logo.svg` - App logo (256x256)
- `banner.svg` - GitHub README banner (1280x320)
- `social-card.svg` - Social media share card (1200x630)

### Using Assets

**GitHub README**:
```markdown
![Clipso](assets/banner.svg)
```

**Social Media**:
Upload `social-card.svg` as OpenGraph image

**Favicon**:
Convert `logo.svg` to ICO/PNG and add to `<head>`:
```html
<link rel="icon" type="image/svg+xml" href="assets/logo.svg">
```

## Features

### Responsive Design
- Mobile-first approach
- Breakpoints: 480px, 768px, 968px
- Touch-friendly on mobile

### Performance
- Minimal dependencies (no frameworks)
- Optimized animations
- Fast loading (<1s on 3G)

### Accessibility
- Semantic HTML
- ARIA labels where needed
- Keyboard navigation
- Screen reader friendly

### SEO
- Meta tags configured
- OpenGraph/Twitter cards ready
- Structured headings
- Fast page speed

## Analytics (Optional)

Add to `<head>` in `index.html`:

```html
<!-- Plausible (privacy-friendly) -->
<script defer data-domain="yourdomain.com"
  src="https://plausible.io/js/script.js"></script>

<!-- Google Analytics -->
<script async
  src="https://www.googletagmanager.com/gtag/js?id=GA_ID"></script>
```

## Testing Checklist

- [ ] All links work
- [ ] Mobile responsive
- [ ] Animations smooth
- [ ] Search bar animation works
- [ ] Hover effects work
- [ ] No console errors
- [ ] Fast loading
- [ ] Cross-browser (Safari, Chrome, Firefox)

## Browser Support

- Safari 13+
- Chrome 90+
- Firefox 88+
- Edge 90+

Modern browsers with CSS Grid, Flexbox, and ES6 support.

## License

Same as main project. See [LICENSE](LICENSE).

## Support

Questions? Open an issue on GitHub.

---

Built with ❤️ for the Clipso project
