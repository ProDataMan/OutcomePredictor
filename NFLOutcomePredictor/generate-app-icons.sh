#!/bin/bash

# App Icon Generator Script
# Converts SVG to all required iOS app icon sizes

set -e

echo "🎨 Generating App Icons"
echo "======================"
echo ""

# Check for required tools
if ! command -v rsvg-convert &> /dev/null; then
    echo "Installing librsvg (for SVG conversion)..."
    brew install librsvg
fi

# Paths
SVG_FILE="/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/AppIcon.svg"
OUTPUT_DIR="/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/AppIcons"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Icon sizes needed for iOS
declare -A SIZES=(
    ["1024"]="App Store"
    ["180"]="iPhone @3x"
    ["120"]="iPhone @2x  "
    ["167"]="iPad Pro @2x"
    ["152"]="iPad @2x"
    ["76"]="iPad"
)

echo "Converting SVG to PNG sizes..."
echo ""

for size in "${!SIZES[@]}"; do
    output_file="$OUTPUT_DIR/AppIcon-${size}.png"
    description="${SIZES[$size]}"

    echo "  Generating ${size}x${size} - ${description}"

    rsvg-convert \
        -w $size \
        -h $size \
        "$SVG_FILE" \
        -o "$output_file"
done

echo ""
echo "✅ All icons generated in: $OUTPUT_DIR"
echo ""
echo "📱 Next Steps:"
echo "1. Open Xcode project:"
echo "   open /Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor.xcodeproj"
echo ""
echo "2. In Xcode:"
echo "   - Select Assets.xcassets in the navigator"
echo "   - Click on AppIcon"
echo "   - Drag each PNG file to its matching size slot:"
echo ""
for size in "${!SIZES[@]}"; do
    echo "     AppIcon-${size}.png  →  ${size}x${size} (${SIZES[$size]})"
done
echo ""
echo "3. Build and run to see the new icon!"
echo ""
