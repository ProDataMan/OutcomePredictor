# Quick Start - iOS App

Get the NFL Predictor iOS app running in 3 steps.

## Step 1: Start the server

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift run nfl-server
```

Wait for the message: `Server starting on http://localhost:8080`

## Step 2: Open in Xcode

```bash
open Package.swift
```

Xcode opens and resolves package dependencies automatically.

## Step 3: Run the app

1. Select an iOS simulator from the device menu (iPhone 15 Pro recommended)
2. Press Cmd+R or click the Run button
3. App launches and loads all 32 NFL teams

## What you can do

### Browse teams
- Scroll through teams in grid layout
- Filter by conference using segmented control
- Tap any team to see details

### View team details
- See team helmet and colors
- Browse games by season
- View scores and results
- Read latest news

### Make predictions
- Tap "Predict" tab at bottom
- Select home team
- Select away team
- Choose season and week
- Tap "Make Prediction"
- See win probabilities and analysis

## Troubleshooting

### Server not running
Error: "Failed to connect"
Solution: Start server with `swift run nfl-server`

### Xcode build errors
Solution: Product > Clean Build Folder (Cmd+Shift+K)

### No teams showing
Solution: Check server logs and verify `curl http://localhost:8080/api/v1/teams` works

## Team helmet designs

All 32 NFL teams have custom gradient designs with official colors:

**Example teams:**
- Kansas City Chiefs: Red and gold gradient
- Buffalo Bills: Blue and red gradient
- San Francisco 49ers: Red and gold gradient
- Dallas Cowboys: Navy and silver gradient

**Features:**
- Team abbreviation displayed on helmet
- Official team colors
- Consistent sizing across app
- Shadow effects for depth

## App structure

```txt
Main tabs:
├── Teams (list icon)
│   ├── Grid of all 32 teams
│   ├── Conference filter
│   └── Team details pages
│
└── Predict (chart icon)
    ├── Home team picker
    ├── Away team picker
    ├── Season/week selector
    └── Prediction results
```

## Files created

**Source code:**
- `Sources/NFLPredictorApp/*.swift` (7 files)

**Documentation:**
- `iOS_COMPLETE_GUIDE.md` - Full documentation
- `RUNNING_iOS_APP.md` - Detailed setup
- `iOS_APP.md` - Features and architecture
- `iOS_SUMMARY.md` - Technical summary
- `QUICK_START_iOS.md` - This file

## Next steps

### Customize team colors
Edit `Sources/NFLPredictorApp/TeamBranding.swift`

### Add new features
Create new Swift files in `Sources/NFLPredictorApp/`

### Deploy to device
1. Connect iPhone/iPad
2. Select device in Xcode
3. Configure signing in project settings
4. Update server URL to use computer IP
5. Build and run

## Requirements

- macOS with Xcode 15+
- iOS Simulator or physical device
- Backend server running

## Support

See documentation:
- `RUNNING_iOS_APP.md` for troubleshooting
- `iOS_COMPLETE_GUIDE.md` for features
- `iOS_APP.md` for architecture

Success! The app runs and displays all teams with custom helmet designs.
