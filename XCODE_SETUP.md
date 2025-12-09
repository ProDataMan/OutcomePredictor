# Creating iOS App with Xcode

The iOS app source files are ready, but need to be added to a proper Xcode iOS App project.

## Method 1: Create new Xcode project (Recommended)

### Step 1: Create iOS app project
1. Open Xcode
2. File > New > Project
3. Select "iOS" > "App"
4. Configure:
   - Product Name: `NFLPredictor`
   - Team: Your team
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
   - Include Tests: Optional

### Step 2: Add local package dependency
1. In Xcode, select the project in navigator
2. Select the app target
3. Go to "General" tab
4. Scroll to "Frameworks, Libraries, and Embedded Content"
5. Click "+" button
6. Click "Add Other..." > "Add Package Dependency..."
7. Click "Add Local..."
8. Navigate to `/Users/baysideuser/GitRepos/OutcomePredictor`
9. Click "Add Package"
10. Select "OutcomePredictorAPI" library
11. Click "Add Package"

### Step 3: Copy source files
Replace the default ContentView.swift and add files:

1. Delete default `ContentView.swift` from project
2. Right-click project, select "Add Files to NFLPredictor"
3. Navigate to `Sources/NFLPredictorApp/`
4. Select all 7 Swift files:
   - NFLPredictorApp.swift
   - ContentView.swift
   - APIClient.swift
   - TeamBranding.swift
   - TeamDetailView.swift
   - PredictionView.swift
   - DTOExtensions.swift
5. Ensure "Copy items if needed" is checked
6. Click "Add"

### Step 4: Update app entry point
1. In project settings, go to "Info" tab
2. If there's an existing `@main` attribute conflict:
   - Open the default app file (NFLPredictorApp.swift from Xcode template)
   - Remove the `@main` attribute or delete the file
   - Keep the one from our `NFLPredictorApp.swift`

### Step 5: Run the app
1. Start the server: `swift run nfl-server` (in terminal)
2. Select iOS simulator in Xcode
3. Press Cmd+R to build and run

## Method 2: Use Swift Package Manager (Advanced)

Since SPM doesn't directly support iOS app bundles with `@main`, you need to use Xcode to generate the app bundle.

### Alternative approach
Create an iOS app using the app manifest in Package.swift (requires Swift 5.9+):

This is experimental and not fully supported yet for iOS apps with SwiftUI.

## Method 3: Simple test harness

If you just want to test the UI components:

1. Create a Playground in Xcode
2. Import OutcomePredictorAPI
3. Copy the view code
4. Test individual views

## Recommended workflow

**For development:**
1. Use Method 1 (Create Xcode project)
2. This gives you full Xcode features:
   - Interface builder
   - Asset catalogs
   - App icons
   - Launch screens
   - Code signing
   - Device deployment

**For quick testing:**
1. Use Xcode previews in each Swift file
2. Each view has `#Preview` blocks

## Common issues

### "No such module 'OutcomePredictorAPI'"
- Ensure package dependency is added correctly
- Clean build folder: Cmd+Shift+K
- Rebuild: Cmd+B

### "@main attribute already exists"
- Only one file can have `@main`
- Remove from default Xcode template file
- Keep in `NFLPredictorApp.swift`

### "Cannot find type 'TeamDTO'"
- Import statement missing: `import OutcomePredictorAPI`
- Package dependency not added

### Server connection fails
- Start server: `swift run nfl-server`
- For physical device, update `APIClient.swift`:
  ```swift
  private let baseURL = "http://YOUR_IP:8080/api/v1"
  ```

## File checklist

Ensure all these files are in your Xcode project:
- ✅ NFLPredictorApp.swift (has `@main`)
- ✅ ContentView.swift
- ✅ APIClient.swift
- ✅ TeamBranding.swift
- ✅ TeamDetailView.swift
- ✅ PredictionView.swift
- ✅ DTOExtensions.swift

Import in each file:
```swift
import SwiftUI
import OutcomePredictorAPI  // Add this
```

## Next steps

1. Follow Method 1 above
2. Create Xcode iOS App project
3. Add package dependency
4. Copy Swift files
5. Build and run

The app source is ready - it just needs an iOS app bundle created by Xcode.
