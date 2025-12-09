# Building the iOS App - Step by Step

The iOS app source files are complete, but Swift Package Manager doesn't support iOS app bundles. Follow these steps to create a working Xcode project.

## Quick solution: Use Xcode to create the project

### Step 1: Create new iOS app project

```bash
# Open Xcode
open -a Xcode
```

In Xcode:
1. File > New > Project (Cmd+Shift+N)
2. Select "iOS" tab at top
3. Select "App" template
4. Click "Next"

### Step 2: Configure project

Fill in:
- Product Name: `NFLPredictor`
- Team: (your team or leave default)
- Organization Identifier: `com.yourname` (or anything)
- Interface: **SwiftUI** (important!)
- Language: **Swift**
- Storage: **None**
- Uncheck "Include Tests" (optional)

Click "Next"

### Step 3: Save project

Save to: `/Users/baysideuser/GitRepos/`

This creates `/Users/baysideuser/GitRepos/NFLPredictor/`

### Step 4: Add package dependency

In Xcode:
1. Click on project name in left sidebar (blue icon)
2. Select "NFLPredictor" target (not project)
3. Click "General" tab
4. Scroll to "Frameworks, Libraries, and Embedded Content"
5. Click "+" button at bottom
6. Click "Add Other..." dropdown
7. Select "Add Package Dependency..."
8. In the dialog:
   - Click "Add Local..."
   - Navigate to `/Users/baysideuser/GitRepos/OutcomePredictor`
   - Click "Add Package"
9. In package products dialog:
   - Check "OutcomePredictorAPI"
   - Click "Add Package"

### Step 5: Remove default files

In project navigator:
1. Find `NFLPredictorApp.swift` (the one Xcode created)
2. Right-click > Delete
3. Choose "Move to Trash"
4. Find `ContentView.swift` (the default one)
5. Right-click > Delete
6. Choose "Move to Trash"

### Step 6: Add our source files

1. Right-click on "NFLPredictor" folder in project navigator
2. Select "Add Files to NFLPredictor..."
3. Navigate to: `/Users/baysideuser/GitRepos/OutcomePredictor/Sources/NFLPredictorApp/`
4. Select all 7 files:
   - NFLPredictorApp.swift
   - ContentView.swift
   - APIClient.swift
   - TeamBranding.swift
   - TeamDetailView.swift
   - PredictionView.swift
   - DTOExtensions.swift
5. **Important:** Check "Copy items if needed"
6. Ensure "NFLPredictor" target is checked
7. Click "Add"

### Step 7: Verify files

In project navigator, you should see:
```
NFLPredictor/
├── NFLPredictorApp.swift (our file)
├── ContentView.swift (our file)
├── APIClient.swift
├── TeamBranding.swift
├── TeamDetailView.swift
├── PredictionView.swift
├── DTOExtensions.swift
├── Assets.xcassets
└── Preview Content/
```

### Step 8: Start the server

Open Terminal:
```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift run nfl-server
```

Wait for: `Server starting on http://localhost:8080`

### Step 9: Build and run

In Xcode:
1. Select a simulator from device menu (iPhone 15 Pro)
2. Press Cmd+R or click Run button
3. App builds and launches
4. Teams load automatically

## Expected result

The app launches showing:
- Grid of 32 NFL teams with helmet logos
- Bottom tab bar with "Teams" and "Predict"
- Team colors and branding
- Tap teams to see details
- Switch to Predict tab to make predictions

## Troubleshooting

### Build error: "No such module 'OutcomePredictorAPI'"

**Solution:**
1. Click project in navigator
2. Select target
3. Build Phases tab
4. Expand "Link Binary With Libraries"
5. Ensure OutcomePredictorAPI is listed
6. If not, click "+" and add it
7. Clean: Cmd+Shift+K
8. Build: Cmd+B

### Build error: "Multiple @main attributes"

**Solution:**
1. Search project for `@main` (Cmd+Shift+F)
2. Should only appear in `NFLPredictorApp.swift`
3. If it appears elsewhere, remove those files
4. Clean and rebuild

### Runtime error: "Failed to connect"

**Solution:**
1. Verify server is running: `swift run nfl-server`
2. Test API: `curl http://localhost:8080/api/v1/teams`
3. Check server console for errors

### App launches but no teams

**Solution:**
1. Check Xcode console for error messages
2. Verify APIClient.swift has correct URL
3. Check network permissions in Info.plist (may need App Transport Security exception)

## Alternative: Use existing project

If you have build errors, create a minimal test:

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
```

Create `TestApp.swift`:
```swift
import SwiftUI
import OutcomePredictorAPI

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            Text("NFL Predictor")
                .task {
                    let client = APIClient()
                    do {
                        let teams = try await client.fetchTeams()
                        print("✅ Loaded \(teams.count) teams")
                    } catch {
                        print("❌ Error: \(error)")
                    }
                }
        }
    }
}

@MainActor
class APIClient: ObservableObject {
    func fetchTeams() async throws -> [TeamDTO] {
        let url = URL(string: "http://localhost:8080/api/v1/teams")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([TeamDTO].self, from: data)
    }
}
```

Then gradually add the full views.

## Success checklist

- ✅ Xcode project created
- ✅ OutcomePredictorAPI package added
- ✅ All 7 Swift files added to project
- ✅ Only one @main attribute exists
- ✅ Server running on port 8080
- ✅ App builds without errors
- ✅ App launches and shows teams

## Next steps

Once working:
1. Explore teams and details
2. Make predictions
3. Customize colors in TeamBranding.swift
4. Add features as needed

Need more help? Check:
- `XCODE_SETUP.md` - Detailed setup guide
- `iOS_COMPLETE_GUIDE.md` - Full feature documentation
- `QUICK_START_iOS.md` - Quick reference
