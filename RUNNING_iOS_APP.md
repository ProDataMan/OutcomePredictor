# Running the iOS App

Follow these steps to run the NFL Predictor iOS app.

## Quick start

### Step 1: Start the server
The iOS app requires the backend server to be running.

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift run nfl-server
```

The server starts on `http://localhost:8080`.

### Step 2: Open in Xcode
1. Open `Package.swift` in Xcode:
   ```bash
   open Package.swift
   ```

2. Wait for Xcode to resolve package dependencies

3. In Xcode, create a new scheme for the iOS app:
   - Go to Product > Scheme > New Scheme
   - Name it "NFLPredictorApp"
   - Set the target to "NFLPredictorApp"

4. Select an iOS simulator (iPhone 15 Pro or similar)

5. Build and run (Cmd+R)

## Alternative: Create standalone Xcode project

For a better development experience, create a dedicated iOS app project:

### Using Xcode
1. File > New > Project
2. Choose "iOS" > "App"
3. Product Name: "NFLPredictor"
4. Interface: SwiftUI
5. Language: Swift

### Add package dependencies
1. In Xcode, go to File > Add Package Dependencies
2. Add local package:
   - Click "Add Local..."
   - Navigate to `/Users/baysideuser/GitRepos/OutcomePredictor`
   - Select the folder
3. Add the "OutcomePredictorAPI" package

### Copy source files
Copy all files from `Sources/NFLPredictorApp/` to the app target:
- `NFLPredictorApp.swift` (rename to match app name)
- `ContentView.swift`
- `APIClient.swift`
- `TeamBranding.swift`
- `TeamDetailView.swift`
- `PredictionView.swift`
- `DTOExtensions.swift`

## Testing the app

### Without server
The app displays an error message when the server is not running. This is expected behavior.

### With server
1. Start the server: `swift run nfl-server`
2. Run the iOS app
3. Teams should load automatically
4. Navigate through teams to see details
5. Use the Predict tab to make game predictions

## Troubleshooting

### "Failed to connect to server"
- Verify server is running on port 8080
- Check `APIClient.swift` has correct URL: `http://localhost:8080/api/v1`
- For iOS device (not simulator), use computer's local IP instead of localhost

### "No teams found"
- Check server logs for errors
- Verify API endpoints are working: `curl http://localhost:8080/api/v1/teams`

### Build errors
- Clean build folder: Product > Clean Build Folder (Cmd+Shift+K)
- Reset package caches: File > Packages > Reset Package Caches
- Ensure all dependencies are resolved

## Features to explore

### Teams view
- Browse all 32 NFL teams
- Filter by conference
- Tap team to see details

### Team details
- View team games by season
- Read latest news
- See win/loss records

### Predictions
- Select home and away teams
- Choose week and season
- Get AI-powered prediction with analysis

## Configuration

### Server URL
To change the server URL (for example, when running on device):

Edit `Sources/NFLPredictorApp/APIClient.swift`:
```swift
private let baseURL = "http://YOUR_COMPUTER_IP:8080/api/v1"
```

Replace `YOUR_COMPUTER_IP` with the actual IP address of the machine running the server.

### API timeouts
URLSession uses default timeouts. To customize, modify `APIClient.swift`:
```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30.0
config.timeoutIntervalForResource = 60.0
let session = URLSession(configuration: config)
```

## Development workflow

### Making changes
1. Edit Swift files in `Sources/NFLPredictorApp/`
2. Build in Xcode (Cmd+B)
3. Run to test (Cmd+R)

### Adding features
- New views: Create Swift files in `NFLPredictorApp/`
- API endpoints: Update `APIClient.swift`
- UI styling: Modify `TeamBranding.swift`

### Testing API changes
1. Update server code
2. Restart server
3. Reload app data (pull to refresh)
