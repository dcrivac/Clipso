#!/bin/bash

# Quick script to update Formspree form ID in landing page
# Usage: ./update-formspree-id.sh YOUR_FORM_ID

if [ -z "$1" ]; then
    echo "❌ Error: Please provide your Formspree form ID"
    echo ""
    echo "Usage: ./update-formspree-id.sh YOUR_FORM_ID"
    echo ""
    echo "Example: ./update-formspree-id.sh xwkgpqyw"
    echo ""
    echo "Get your form ID from: https://formspree.io/forms"
    exit 1
fi

FORM_ID=$1

echo "🔄 Updating Formspree form ID to: $FORM_ID"
echo ""

# Update docs/index.html
sed -i "s|action=\"https://formspree.io/f/YOUR_FORM_ID\"|action=\"https://formspree.io/f/$FORM_ID\"|g" docs/index.html

# Check if it worked
if grep -q "formspree.io/f/$FORM_ID" docs/index.html; then
    echo "✅ Successfully updated docs/index.html"
    echo ""
    echo "📝 Next steps:"
    echo "1. Test locally: cd docs/ && python3 -m http.server 8000"
    echo "2. Open: http://localhost:8000"
    echo "3. Test the waitlist form"
    echo "4. Commit: git add docs/index.html && git commit -m 'Add Formspree form ID'"
    echo "5. Deploy following GITHUB_PAGES_DEPLOYMENT.md"
    echo ""
else
    echo "❌ Error: Could not update form ID"
    echo "Please manually edit docs/index.html line 696"
fi
