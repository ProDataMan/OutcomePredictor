# iOS App Setup Instructions

All the Swift files for your NFL Predictor iOS app are ready. Follow these steps to add them to your Xcode project.

## Step 1: Add Swift Files to Xcode

1. Open your Xcode project: `NFLPredictor-iOS`

2. **Add APIClient.swift:**
   - Right-click on the `NFLPredictor` folder (blue folder icon, not yellow)
   - Select "Add Files to NFLPredictor..."
   - Navigate to: `/Users/baysideuser/GitRepos/OutcomePredictor/iOSAppFiles/`
   - Select `APIClient.swift`
   - Make sure "Copy items if needed" is checked
   - Click "Add"

3. **Replace ContentView.swift:**
   - In Xcode, find the existing `ContentView.swift` file
   - Delete it (right-click → Delete → Move to Trash)
   - Right-click on `NFLPredictor` folder → "Add Files to NFLPredictor..."
   - Navigate to: `/Users/baysideuser/GitRepos/OutcomePredictor/iOSAppFiles/`
   - Select `ContentView.swift`
   - Make sure "Copy items if needed" is checked
   - Click "Add"

4. **Add TeamDetailView.swift:**
   - Right-click on the `NFLPredictor` folder
   - Select "Add Files to NFLPredictor..."
   - Navigate to: `/Users/baysideuser/GitRepos/OutcomePredictor/iOSAppFiles/Views/`
   - Select `TeamDetailView.swift`
   - Make sure "Copy items if needed" is checked
   - Click "Add"

## Step 2: Configure Info.plist for Localhost Access

**Method A: Using Xcode UI (Recommended)**

1. In Xcode, select your project (blue icon at the top)
2. Select the `NFLPredictor` target
3. Go to the "Info" tab
4. Click the "+" button to add a new key
5. Type: `App Transport Security Settings`
6. It should appear as a Dictionary type
7. Click the disclosure triangle to expand it
8. Click the "+" next to "App Transport Security Settings"
9. Add key: `Allow Arbitrary Loads` → set to `YES` (Boolean)
10. Click the "+" again
11. Add key: `Allow Local Networking` → set to `YES` (Boolean)

**Method B: Edit Info.plist as Source Code**

1. In Xcode, find `Info.plist` in the project navigator
2. Right-click → "Open As" → "Source Code"
3. Add this inside the `<dict>` tag (before the closing `</dict>`):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## Step 3: Build and Run

1. Make sure your server is running in Terminal:
   ```bash
   cd /Users/baysideuser/GitRepos/OutcomePredictor
   export NEWS_API_KEY="168084c7268f48b48f2e4eec0ddca9cd"
   .build/debug/nfl-server
   ```

2. In Xcode:
   - Select "iPhone 15 Pro" simulator (or any iPhone)
   - Press `Cmd + R` to build and run

3. You should see:
   - "Loading teams..." spinner
   - Then a list of 32 NFL teams
   - Tap any team to see their games and news

## Troubleshooting

### Build Errors: "No such module 'OutcomePredictorAPI'"

1. Select your project (blue icon)
2. Select the target
3. Go to "General" tab
4. Under "Frameworks, Libraries, and Embedded Content"
5. Make sure `OutcomePredictorAPI` is listed
6. If not, click "+" and add it again

### Runtime Error: "The resource could not be loaded"

1. Check server is running: `curl http://localhost:8080/health`
2. Check Info.plist has network permissions (see Step 2)
3. Clean build folder: `Cmd + Shift + K`
4. Rebuild: `Cmd + B`
5. Run again: `Cmd + R`

### Simulator Shows Blank Screen

1. Check Xcode console (bottom panel) for error messages
2. Look for red errors in the Issue Navigator (left panel, red icon)
3. Make sure all files were added correctly

## Testing the Complete Flow

1. **Server running** → Terminal shows: `[ NOTICE ] Server starting on http://127.0.0.1:8080`
2. **App launches** → Shows "Loading teams..."
3. **Teams load** → Shows list of 32 teams
4. **Tap Chiefs** → Shows their 2024 games and recent news
5. **Server logs** → Terminal shows: `[ INFO ] GET /api/v1/games?team=KC&season=2024`

## Next Features to Add

1. **Prediction View** - Create a new view to select two teams and show win probabilities
2. **Pull to Refresh** - Add refresh control to reload data
3. **Search** - Add search bar to filter teams
4. **Dark Mode** - Test and adjust colors for dark mode
5. **Error Recovery** - Better error messages and retry logic

The basic app is now complete and functional!
