# NFL Predictor - Complete iOS App Guide

iOS app with team helmet logos and visual game predictions for the NFL Outcome Predictor system.

## Overview

The iOS app provides an intuitive interface to:
- Browse all 32 NFL teams with custom helmet designs
- View team schedules and game results
- Read latest news for each team
- Generate AI-powered game predictions with detailed analysis

## Team helmet designs

Each team features a unique gradient design using official team colors:

### NFC Teams
**NFC East**
- Dallas Cowboys (Navy/Silver)
- Philadelphia Eagles (Midnight Green/Silver)
- New York Giants (Blue/Red)
- Washington Commanders (Burgundy/Gold)

**NFC North**
- Detroit Lions (Blue/Silver)
- Green Bay Packers (Green/Gold)
- Minnesota Vikings (Purple/Gold)
- Chicago Bears (Navy/Orange)

**NFC South**
- Tampa Bay Buccaneers (Red/Pewter)
- Atlanta Falcons (Red/Black)
- New Orleans Saints (Gold/Black)
- Carolina Panthers (Blue/Black)

**NFC West**
- San Francisco 49ers (Red/Gold)
- Seattle Seahawks (Navy/Action Green)
- Los Angeles Rams (Blue/Yellow)
- Arizona Cardinals (Cardinal/Yellow)

### AFC Teams
**AFC East**
- Buffalo Bills (Blue/Red)
- Miami Dolphins (Aqua/Orange)
- New York Jets (Green/White)
- New England Patriots (Navy/Red)

**AFC North**
- Baltimore Ravens (Purple/Gold)
- Pittsburgh Steelers (Black/Gold)
- Cincinnati Bengals (Orange/Black)
- Cleveland Browns (Brown/Orange)

**AFC South**
- Houston Texans (Navy/Red)
- Indianapolis Colts (Blue/White)
- Jacksonville Jaguars (Teal/Gold)
- Tennessee Titans (Navy/Light Blue)

**AFC West**
- Kansas City Chiefs (Red/Gold)
- Los Angeles Chargers (Powder Blue/Gold)
- Las Vegas Raiders (Silver/Black)
- Denver Broncos (Orange/Navy)

## App structure

```txt
Sources/NFLPredictorApp/
├── NFLPredictorApp.swift    # Main app entry point
├── ContentView.swift         # Tab bar with teams and predictions
├── APIClient.swift           # Server communication
├── TeamBranding.swift        # Team colors and helmet designs
├── TeamDetailView.swift      # Individual team information
├── PredictionView.swift      # Game prediction interface
└── DTOExtensions.swift       # UI-friendly data extensions
```

## Screenshots and features

### Home screen - Teams grid
- 32 NFL teams displayed in adaptive grid
- Team helmet logos with official colors
- Filter by conference (All, NFC, AFC)
- Tap any team to view details

### Team detail view
- Large team helmet display
- Season selector (2020-2024)
- Complete game schedule
- Win/loss records with scores
- Latest news articles

### Prediction view
- Select home and away teams
- Choose season and week
- Visual matchup display
- Win probability percentages
- Confidence score with progress bar
- Detailed AI reasoning

## Running the app

### Quick start
1. Start the backend server:
   ```bash
   swift run nfl-server
   ```

2. Open in Xcode:
   ```bash
   open Package.swift
   ```

3. Select iOS simulator and run

For detailed instructions, see [RUNNING_iOS_APP.md](RUNNING_iOS_APP.md).

## API integration

The app communicates with the backend server running on `http://localhost:8080`.

### Endpoints used
- `GET /api/v1/teams` - All NFL teams
- `GET /api/v1/games?team=ABBR&season=YEAR` - Team schedule
- `GET /api/v1/news?team=ABBR&limit=N` - Latest news
- `POST /api/v1/predictions` - Game predictions

## Team branding system

Each team has official colors defined in `TeamBranding.swift`:

```swift
TeamBranding.branding(for: "KC")
// Returns: TeamBranding(
//   primaryColor: Chiefs Red,
//   secondaryColor: Gold,
//   helmetImageName: "helmet_kc"
// )
```

The helmet view creates gradient circles with team abbreviations:

```swift
TeamHelmetView(teamAbbreviation: "KC", size: 80)
```

## Customization

### Change team colors
Edit `TeamBranding.swift` and update the color values for any team.

### Adjust helmet size
The `TeamHelmetView` accepts a `size` parameter:
```swift
TeamHelmetView(teamAbbreviation: "BUF", size: 120) // Larger
TeamHelmetView(teamAbbreviation: "MIA", size: 40)  // Smaller
```

### Modify server URL
For physical devices, update `APIClient.swift`:
```swift
private let baseURL = "http://192.168.1.100:8080/api/v1"
```

## Architecture patterns

### Protocol-oriented design
Following Swift best practices from the main project.

### State management
Uses `@StateObject` and `@State` for reactive UI updates.

### Async/await
All network calls use modern Swift concurrency.

### Error handling
Displays user-friendly error messages with retry options.

## Development workflow

### Adding new views
1. Create Swift file in `Sources/NFLPredictorApp/`
2. Import `SwiftUI` and `OutcomePredictorAPI`
3. Define view with preview
4. Add navigation from existing views

### Testing API changes
1. Update server endpoint
2. Restart server
3. Update `APIClient.swift` method
4. Rebuild and test app

### Styling consistency
Use existing patterns:
- `TeamHelmetView` for team logos
- `TeamBranding.branding(for:)` for colors
- Standard SwiftUI modifiers for consistency

## Next steps

### Enhancements to consider
- Add team statistics and standings
- Include player information
- Historical prediction tracking
- Offline mode with cached data
- Share predictions to social media
- Widget for quick game updates
- Push notifications for game times

### Performance improvements
- Image caching for team logos
- Pagination for long lists
- Background data refresh
- Optimistic UI updates

## Related documentation

- [iOS_APP.md](iOS_APP.md) - Detailed feature documentation
- [RUNNING_iOS_APP.md](RUNNING_iOS_APP.md) - Setup and troubleshooting
- [README.md](README.md) - Main project overview
- [SERVER_AND_IOS.md](SERVER_AND_IOS.md) - Server setup guide

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 6.1+
- Active backend server

## Support

For issues or questions:
1. Check [RUNNING_iOS_APP.md](RUNNING_iOS_APP.md) for troubleshooting
2. Verify server is running and accessible
3. Check Xcode console for error messages
4. Review API endpoint responses

Built with SwiftUI and modern Swift concurrency patterns.
