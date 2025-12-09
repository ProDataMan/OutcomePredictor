#!/bin/bash

# Script to create iOS App Xcode project for NFL Predictor
# This automates the manual Xcode steps

set -e

echo "🏈 Creating NFL Predictor iOS App Project..."

# Project variables
PROJECT_NAME="NFLPredictor"
BUNDLE_ID="com.nfl.predictor"
PROJECT_DIR="/Users/baysideuser/GitRepos/NFLPredictor"
SOURCE_DIR="/Users/baysideuser/GitRepos/OutcomePredictor/Sources/NFLPredictorApp"
PACKAGE_DIR="/Users/baysideuser/GitRepos/OutcomePredictor"

# Create project directory
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "📁 Creating project structure..."

# Create the iOS app using xcodebuild template
# Unfortunately, xcodebuild doesn't have a template creation command
# We need to create the project file manually

echo "⚠️  Cannot automatically create Xcode project file."
echo ""
echo "The Xcode project file format is complex and proprietary."
echo "You need to create it through Xcode's GUI."
echo ""
echo "However, I can prepare everything else..."
echo ""

# Create app directory structure
mkdir -p "$PROJECT_DIR/$PROJECT_NAME"
mkdir -p "$PROJECT_DIR/$PROJECT_NAME/Assets.xcassets"
mkdir -p "$PROJECT_DIR/$PROJECT_NAME/Preview Content"

# Copy source files
echo "📋 Copying source files..."
cp "$SOURCE_DIR"/*.swift "$PROJECT_DIR/$PROJECT_NAME/"

# Create Info.plist
echo "📄 Creating Info.plist..."
cat > "$PROJECT_DIR/$PROJECT_NAME/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

# Create Assets catalog
cat > "$PROJECT_DIR/$PROJECT_NAME/Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

mkdir -p "$PROJECT_DIR/$PROJECT_NAME/Assets.xcassets/AppIcon.appiconset"
cat > "$PROJECT_DIR/$PROJECT_NAME/Assets.xcassets/AppIcon.appiconset/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

mkdir -p "$PROJECT_DIR/$PROJECT_NAME/Assets.xcassets/AccentColor.colorset"
cat > "$PROJECT_DIR/$PROJECT_NAME/Assets.xcassets/AccentColor.colorset/Contents.json" << 'EOF'
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

# Create Preview Content
cat > "$PROJECT_DIR/$PROJECT_NAME/Preview Content/Preview Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Project structure created at: $PROJECT_DIR"
echo ""
echo "📝 Files copied:"
ls -1 "$PROJECT_DIR/$PROJECT_NAME"/*.swift
echo ""
echo "⚠️  IMPORTANT: You still need to create the .xcodeproj file"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. File > New > Project"
echo "3. Choose iOS > App"
echo "4. Name it 'NFLPredictor'"
echo "5. Save to: /Users/baysideuser/GitRepos/"
echo "6. When prompted to replace, click 'Merge'"
echo "7. In Xcode, add package dependency to OutcomePredictor"
echo ""
echo "OR use the provided instructions in BUILD_iOS_STEP_BY_STEP.md"
echo ""

EOF

chmod +x create_ios_project.sh
