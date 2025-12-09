#!/usr/bin/osascript

# Create app icon using macOS built-in tools
# This creates a simple icon with SF Symbols

tell application "Shortcuts"
    activate
end tell

display dialog "To create the app icon:

1. Open the SwiftUI Playground code at:
   AppIconGenerator.swift

2. In Xcode: File → New → Playground

3. Paste the code and run it

4. Long-press the preview → Share → Save Image

5. Go to https://www.appicon.co

6. Upload the saved image

7. Download the .zip file

8. Unzip and drag AppIcon.appiconset into:
   Xcode → Assets.xcassets

OR use a simple SF Symbol icon temporarily:

1. Open 'Preview' app
2. Create a new document (1024x1024)
3. Add a sports-related emoji or symbol
4. Export as PNG
5. Use at https://www.appicon.co" buttons {"OK"} default button "OK"
