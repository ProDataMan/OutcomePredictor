# NFL Predictor iOS App

iOS app for visualizing NFL game predictions and team data.

## Features

### Team browsing
- Grid view of all 32 NFL teams with team helmet logos
- Filter by conference (AFC, NFC, or All)
- Team branding with official colors
- Navigate to detailed team views

### Team details
- View team information and branding
- Browse games by season (2020-2024)
- See game results with scores
- Latest news articles for the team
- Visual representation of home and away games

### Game predictions
- Select home and away teams
- Choose season and week
- Get AI-powered predictions with:
  - Win probability for each team
  - Confidence score
  - Detailed reasoning and analysis
  - Visual presentation of matchup

## Architecture

### SwiftUI views
- `ContentView`: Main tab bar interface
- `TeamsListView`: Grid of all teams with filtering
- `TeamDetailView`: Individual team information and games
- `PredictionView`: Game prediction interface
- `TeamHelmetView`: Reusable team logo component

### API integration
- `APIClient`: Manages all API communication
- Connects to local server at `http://localhost:8080/api/v1`
- Supports teams, games, news, and prediction endpoints

### Team branding
- `TeamBranding`: Official team colors for all 32 teams
- Gradient-based helmet designs
- Team abbreviation overlays

## Running the app

### Prerequisites
1. Start the NFL prediction server:
   ```bash
   swift run nfl-server
   ```
   Server runs on `http://localhost:8080`

2. The iOS app can be run in:
   - Xcode (open Package.swift)
   - Simulator
   - Physical iOS device (requires code signing)

### Building
Since this uses Swift Package Manager, the app can be opened in Xcode:
1. Open `Package.swift` in Xcode
2. Select the NFLPredictorApp scheme
3. Choose a simulator or device
4. Run (Cmd+R)

## API endpoints used

### GET /api/v1/teams
Returns all 32 NFL teams with conference and division information.

### GET /api/v1/games?team=ABBR&season=YEAR
Returns games for a specific team in a given season.

### GET /api/v1/news?team=ABBR&limit=N
Returns recent news articles for a team.

### POST /api/v1/predictions
Makes a prediction for a game between two teams.
Request body:
```json
{
  "homeTeamAbbreviation": "KC",
  "awayTeamAbbreviation": "BUF",
  "week": 13,
  "season": 2024
}
```

## Team helmet designs

Each team has a custom gradient design using official team colors:
- Primary color: Main team brand color
- Secondary color: Accent or alternate color
- Team abbreviation displayed on helmet
- Consistent sizing across all views

## Data models

### TeamDTO
- `abbreviation`: Team code (e.g., "KC")
- `name`: Full team name
- `conference`: "AFC" or "NFC"
- `division`: "North", "South", "East", or "West"

### GameDTO
- Game details with home/away teams
- Scheduled date and time
- Week and season information
- Scores (if game completed)

### PredictionDTO
- Win probabilities for both teams
- Confidence score
- Detailed reasoning
- Vegas odds (optional)

## Future enhancements

- Add team statistics and standings
- Historical prediction accuracy tracking
- Push notifications for game predictions
- Offline mode with cached data
- Share predictions to social media
- Customize favorite teams
- Watch integration for quick predictions
