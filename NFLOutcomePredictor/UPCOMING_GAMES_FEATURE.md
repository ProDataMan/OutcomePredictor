# Auto-Loading Upcoming Games Feature

## Overview

The Prediction tab now automatically loads and displays upcoming NFL games when the app launches, with automatic prediction for the first upcoming game.

## What Changed

### Server-Side (NFLServer)

**New Endpoint: `GET /api/v1/upcoming`**

Location: `/Users/baysideuser/GitRepos/OutcomePredictor/Sources/NFLServer/main.swift:88-107`

```swift
api.get("upcoming") { req async throws -> [GameDTO] in
    guard let loader = req.application.storage[DataLoaderKey.self] else {
        throw Abort(.internalServerError, reason: "Data loader not initialized")
    }

    let games = try await loader.loadLiveScores()

    // Filter for upcoming games (not completed)
    let now = Date()
    let upcomingGames = games.filter { game in
        game.scheduledDate > now || (game.homeScore == nil && game.awayScore == nil)
    }

    // Sort by scheduled date
    let sortedGames = upcomingGames.sorted { $0.scheduledDate < $1.scheduledDate }
    let gameDTOs = sortedGames.map { GameDTO(from: $0) }

    return gameDTOs
}
```

This endpoint:
- Fetches live scoreboard data from ESPN
- Filters for games that haven't been played yet (no scores or future date)
- Sorts by scheduled date (soonest first)
- Returns as GameDTO array

### iOS App Changes

**1. APIClient.swift** - Added method to fetch upcoming games

Location: `/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor/APIClient.swift:22-27`

```swift
/// Fetches upcoming NFL games.
func fetchUpcomingGames() async throws -> [GameDTO] {
    let url = URL(string: "\(baseURL)/upcoming")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try decoder.decode([GameDTO].self, from: data)
}
```

**2. PredictionView.swift** - Major updates

Added state variables:
```swift
@State private var upcomingGames: [GameDTO] = []
@State private var selectedUpcomingGameIndex: Int?
```

Added upcoming games carousel at top of view:
```swift
// Upcoming games section
if !upcomingGames.isEmpty {
    VStack(alignment: .leading, spacing: 12) {
        Text("Upcoming Games")
            .font(.headline)
            .padding(.horizontal)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(upcomingGames.prefix(5).enumerated()), id: \.element.id) { index, game in
                    UpcomingGameCard(game: game, isSelected: selectedUpcomingGameIndex == index)
                        .onTapGesture {
                            selectUpcomingGame(at: index)
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    .padding(.top)
}
```

Added helper functions:
```swift
private func loadUpcomingGames() async {
    do {
        upcomingGames = try await apiClient.fetchUpcomingGames()
        // Auto-select and predict the first upcoming game
        if !upcomingGames.isEmpty {
            selectUpcomingGame(at: 0)
        }
    } catch {
        self.error = error.localizedDescription
    }
}

private func selectUpcomingGame(at index: Int) {
    guard index < upcomingGames.count else { return }
    selectedUpcomingGameIndex = index

    let game = upcomingGames[index]
    homeTeam = game.homeTeam
    awayTeam = game.awayTeam
    selectedSeason = game.season
    selectedWeek = game.week

    // Auto-predict this game
    Task {
        await makePrediction()
    }
}
```

**3. UpcomingGameCard Component** - New UI component

Location: `/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor/PredictionView.swift:619-670`

Displays:
- Game date and time
- Team helmets (away @ home)
- Team abbreviations
- Week number
- Visual selection indicator (blue border when selected)

## User Experience Flow

### On App Launch (Predictions Tab)

1. **Automatic Loading**:
   - App fetches list of upcoming games from server
   - Shows horizontal scrollable carousel of next 5 games
   - Each card shows: date, time, teams, week

2. **Auto-Prediction**:
   - First upcoming game is automatically selected (blue border)
   - Teams are auto-populated in home/away fields
   - Prediction is automatically generated
   - Full prediction results appear below

3. **User Interaction**:
   - Tap any upcoming game card to switch predictions
   - Selected game gets blue border highlight
   - Prediction updates automatically
   - Can still manually select teams if desired

### Visual Layout

```
┌─────────────────────────────────────┐
│      Upcoming Games (scroll →)      │
│  ┌────────┐ ┌────────┐ ┌────────┐  │
│  │ Dec 1  │ │ Dec 1  │ │ Dec 2  │  │
│  │ 1:00PM │ │ 4:25PM │ │ 8:20PM │  │
│  │ BUF @  │ │ KC @   │ │ DAL @  │  │
│  │ KC 🏈  │ │ LV 🏈  │ │ NYG 🏈 │  │
│  │ Week13 │ │ Week13 │ │ Week13 │  │
│  └────────┘ └────────┘ └────────┘  │
│     [SELECTED]                      │
├─────────────────────────────────────┤
│   Home Team: [Kansas City Chiefs]  │
│   Away Team: [Buffalo Bills]       │
│   Season: 2024  Week: 13           │
│   [Make Prediction] (auto-done)    │
├─────────────────────────────────────┤
│   Prediction Results...             │
│   Win Probability, Vegas Odds, etc. │
└─────────────────────────────────────┘
```

## Data Source

The upcoming games come from ESPN's live scoreboard API, which provides:
- Current week's games
- Game times and dates
- Team information
- Live scores (when games are in progress)

The server filters this data to show only:
- Games with future scheduled dates, OR
- Games without scores yet (scheduled but not started)

## Benefits

1. **Immediate Value**: User sees predictions for real upcoming games without any input
2. **Context Awareness**: App knows what games are happening based on current date/time
3. **Easy Navigation**: Quick tap to switch between multiple upcoming games
4. **Smart Defaults**: No need to manually select teams and dates for current week
5. **Manual Override**: Users can still manually select any teams if they want custom predictions

## Technical Notes

- Upcoming games load in parallel with teams list
- Auto-prediction happens after game selection
- Horizontal scroll supports 5+ games smoothly
- Selected game state persists when switching tabs (SwiftUI state)
- Error handling shows message if API unavailable

## Testing

1. **Start server**: `./run-server-8082.sh` from OutcomePredictor directory
2. **Run app** in Xcode
3. **Navigate to Predictions tab**
4. **Observe**: First upcoming game auto-loads and prediction appears
5. **Tap** different upcoming game cards to see predictions update

## Files Modified

1. `/Users/baysideuser/GitRepos/OutcomePredictor/Sources/NFLServer/main.swift`
   - Added `/api/v1/upcoming` endpoint

2. `/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor/APIClient.swift`
   - Added `fetchUpcomingGames()` method

3. `/Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor/PredictionView.swift`
   - Added upcoming games state
   - Added carousel UI
   - Added auto-load and auto-predict logic
   - Added `UpcomingGameCard` component

## Build Status

✅ iOS app builds successfully
✅ Server endpoint added
✅ Auto-loading implemented
✅ Auto-prediction working
