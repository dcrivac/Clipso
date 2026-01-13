#!/bin/bash

# Create Product Images for Lemon Squeezy
# Converts existing SVG assets to PNG images in required sizes

echo "🎨 Creating Lemon Squeezy Product Images..."

# Create output directory
mkdir -p product-images

# Check if ImageMagick or rsvg-convert is installed
if command -v rsvg-convert &> /dev/null; then
    CONVERTER="rsvg-convert"
    echo "✅ Using rsvg-convert"
elif command -v convert &> /dev/null; then
    CONVERTER="imagemagick"
    echo "✅ Using ImageMagick"
else
    echo "❌ Neither rsvg-convert nor ImageMagick is installed."
    echo ""
    echo "Install one of these to convert SVG to PNG:"
    echo "  brew install librsvg          (for rsvg-convert)"
    echo "  brew install imagemagick      (for convert)"
    echo ""
    echo "Alternative: Use online converter at https://cloudconvert.com/svg-to-png"
    exit 1
fi

# Function to convert SVG to PNG
convert_svg_to_png() {
    local input=$1
    local output=$2
    local width=$3
    local height=$4

    if [ "$CONVERTER" = "rsvg-convert" ]; then
        rsvg-convert -w $width -h $height "$input" -o "$output"
    else
        convert -background none -resize ${width}x${height} "$input" "$output"
    fi

    if [ $? -eq 0 ]; then
        echo "  ✓ Created: $output"
    else
        echo "  ✗ Failed: $output"
    fi
}

echo ""
echo "Converting SVG assets to PNG..."
echo ""

# Product Card Images (1200x630)
echo "📸 Product Cards (1200x630)..."
convert_svg_to_png "assets/social-card.svg" "product-images/clipso-product-card.png" 1200 630
convert_svg_to_png "assets/social-pricing-comparison.svg" "product-images/clipso-pricing-card.png" 1200 630
convert_svg_to_png "assets/social-privacy-first.svg" "product-images/clipso-privacy-card.png" 1200 630

# Product Thumbnails (400x400)
echo ""
echo "🔲 Product Thumbnails (400x400)..."
convert_svg_to_png "assets/logo.svg" "product-images/clipso-thumbnail.png" 400 400

# Banner/Hero Images (1920x400)
echo ""
echo "🎯 Banners (1920x400)..."
convert_svg_to_png "assets/banner.svg" "product-images/clipso-banner.png" 1920 400

# Screenshots for product page (full size)
echo ""
echo "📱 Screenshots (1200x800)..."
convert_svg_to_png "assets/screenshot-hero.svg" "product-images/screenshot-hero.png" 1200 800
convert_svg_to_png "assets/screenshot-context.svg" "product-images/screenshot-context.png" 1200 800
convert_svg_to_png "assets/screenshot-search-comparison.svg" "product-images/screenshot-search.png" 1200 800

# Social media variants (for sharing)
echo ""
echo "📱 Social Media Sizes..."
convert_svg_to_png "assets/social-twitter-semantic-search.svg" "product-images/social-twitter.png" 1200 675
convert_svg_to_png "assets/social-instagram-features.svg" "product-images/social-instagram.png" 1080 1080
convert_svg_to_png "assets/social-linkedin-professional.svg" "product-images/social-linkedin.png" 1200 627

echo ""
echo "✅ Done! Product images created in: product-images/"
echo ""
echo "📦 Upload these to Lemon Squeezy:"
echo "  - Product Card: clipso-product-card.png (1200x630)"
echo "  - Thumbnail: clipso-thumbnail.png (400x400)"
echo "  - Banner: clipso-banner.png (1920x400)"
echo ""
echo "💡 Tip: You can also use the pricing and privacy cards for different product variants!"
