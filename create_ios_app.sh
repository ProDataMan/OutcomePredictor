#!/bin/bash

# Script to create iOS App Xcode project for NFL Predictor

echo "🏈 Creating NFL Predictor iOS App..."

# Create Xcode project directory
PROJECT_DIR="NFLPredictorApp"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "📱 Creating Xcode iOS App Project..."

cat > create_project.sh << 'EOF'
#!/bin/bash

# This script guides you through creating the iOS app in Xcode

echo "========================================="
echo "NFL Predictor iOS App - Setup Guide"
echo "========================================="
echo ""
echo "Since Swift Package Manager doesn't support iOS app bundles with @main,"
echo "you need to create the project in Xcode manually."
echo ""
echo "Follow these steps:"
echo ""
echo "1. Open Xcode"
echo "2. File > New > Project"
echo "3. Select 'iOS' > 'App'"
echo "4. Configure project:"
echo "   - Product Name: NFLPredictor"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo ""
echo "5. Save the project to: $(pwd)"
echo ""
echo "6. Add package dependency:"
echo "   - Select project in navigator"
echo "   - Select target"
echo "   - General tab"
echo "   - Frameworks section"
echo "   - Click '+' > Add Package Dependency"
echo "   - Add Local package"
echo "   - Select: $(dirname $(pwd))"
echo "   - Add 'OutcomePredictorAPI'"
echo ""
echo "7. Add source files:"
echo "   - Delete default ContentView.swift"
echo "   - Right-click project > Add Files"
echo "   - Navigate to: $(dirname $(pwd))/Sources/NFLPredictorApp/"
echo "   - Select all .swift files"
echo "   - Check 'Copy items if needed'"
echo "   - Click Add"
echo ""
echo "8. Fix @main conflict if needed:"
echo "   - Keep only NFLPredictorApp.swift with @main"
echo "   - Remove @main from template files"
echo ""
echo "9. Start the server:"
echo "   cd $(dirname $(pwd))"
echo "   swift run nfl-server"
echo ""
echo "10. Build and run in Xcode (Cmd+R)"
echo ""
echo "========================================="
echo "Need help? See XCODE_SETUP.md"
echo "========================================="

EOF

chmod +x create_project.sh
./create_project.sh

EOF

chmod +x "$PROJECT_DIR/create_project.sh"

echo "✅ Setup script created!"
echo ""
echo "However, there's a simpler way..."
echo ""
