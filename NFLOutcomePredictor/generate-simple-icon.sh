#!/bin/bash

# Simple App Icon Generator using SF Symbols
# This creates a basic icon using macOS built-in tools

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "ImageMagick not found. Installing via Homebrew..."
    brew install imagemagick
fi

# Create a simple icon with SF Symbol
# Football icon on gradient background

# Create gradient background
convert -size 1024x1024 gradient:'#1A3366-#0D1940' /tmp/icon_bg.png

# Add text overlay (since we can't easily use SF Symbols from command line)
convert /tmp/icon_bg.png \
    -gravity center \
    -pointsize 400 \
    -fill white \
    -annotate +0+0 "🏈" \
    /tmp/icon_1024.png

echo "Icon generated at: /tmp/icon_1024.png"
echo ""
echo "Next steps:"
echo "1. Open /tmp/icon_1024.png to verify it looks good"
echo "2. Upload to https://www.appicon.co to generate all sizes"
echo "3. Download the .zip file"
echo "4. Drag AppIcon.appiconset folder into Xcode Assets"
echo ""
echo "Or manually add to Xcode:"
echo "1. Open Xcode project"
echo "2. Navigate to Assets.xcassets"
echo "3. Click on AppIcon"
echo "4. Drag /tmp/icon_1024.png into the 1024x1024 slot"
