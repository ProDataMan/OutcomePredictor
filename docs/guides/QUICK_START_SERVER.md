# Quick Start: Run NFL Predictions as Server + iOS App

## What I've Built

I've transformed the OutcomePredictor into a **client-server architecture**:

1. **Vapor Swift Server** - Backend that handles all API calls
2. **iOS App Integration** - Lightweight client that fetches data from server
3. **Shared API Models** - DTOs that work with both server and iOS

## Key Benefits

✅ **News IS being fetched** - But not yet used in predictions (baseline predictor only uses win rates)
✅ **Vegas odds comparison** - Side-by-side display with our model
✅ **API keys on server** - Secure, not exposed in iOS app
✅ **Caching** - Server caches data, multiple clients can share
✅ **iOS-ready** - API designed for SwiftUI apps

## Running the Server (From Your Terminal)

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor

# Resolve dependencies (first time only)
swift package resolve

# Build the server
swift build --product nfl-server

# Run the server
swift run nfl-server
```

Server starts on **http://localhost:8080**

## Testing the API

```bash
# Health check
curl http://localhost:8080/health

# Get all teams
curl http://localhost:8080/api/v1/teams | python3 -m json.tool

# Get Chiefs games
curl "http://localhost:8080/api/v1/games?team=KC&season=2024" | python3 -m json.tool

# Get Chiefs news
curl "http://localhost:8080/api/v1/news?team=KC&limit=3" | python3 -m json.tool

# Make a prediction
curl -X POST http://localhost:8080/api/v1/predictions \
  -H "Content-Type: application/json" \
  -d '{
    "home_team_abbreviation": "KC",
    "away_team_abbreviation": "BUF",
    "season": 2024,
    "week": 13
  }' | python3 -m json.tool
```

## What's Included

### New Files Created

1. **Sources/OutcomePredictorAPI/DTOs.swift** - API models (TeamDTO, GameDTO, PredictionDTO, etc.)
2. **Sources/OutcomePredictorAPI/Mappers.swift** - Convert domain models to DTOs
3. **Sources/NFLServer/main.swift** - Vapor server with REST endpoints
4. **Sources/OutcomePredictor/OddsDataSource.swift** - Vegas odds integration
5. **SERVER_AND_IOS.md** - Complete documentation

### API Endpoints

- `GET /health` - Health check
- `GET /api/v1/teams` - List all NFL teams
- `GET /api/v1/games?team=KC&season=2024` - Team games
- `GET /api/v1/news?team=KC&limit=10` - Team news
- `POST /api/v1/predictions` - Make prediction

### Updated Files

- **Package.swift** - Added Vapor dependency, server target, API library
- **RUNNING.md** - Would need updating with new server instructions

## Building the iOS App

See **SERVER_AND_IOS.md** for complete instructions. Quick summary:

1. Create new iOS project in Xcode
2. Add `OutcomePredictorAPI` package dependency
3. Create `APIClient` class to call server
4. Build SwiftUI views to display data
5. Run iOS app (connects to local server)

## Next Steps

### To Answer Your Questions:

**Q: Is news being used in predictions?**
A: **No, not yet.** News is being fetched and cached, but the `BaselinePredictor` only uses historical win rates. You'll see this warning in the output. The infrastructure exists for sentiment analysis, but it's not wired up to the predictor yet.

**Q: Can we show Vegas odds comparison?**
A: **Yes, done!** The prediction endpoint now returns a side-by-side comparison:
```
                              Our Model   Vegas Odds
Home Win (KC)                     46.6%        60.8%
Away Win (BUF)                    53.4%        42.5%
Spread                              N/A         -3.5
```

Currently using mock odds. To get real odds, sign up at https://the-odds-api.com/ and set `ODDS_API_KEY` environment variable.

### To Continue Development:

1. **Test the server** - Run from terminal and test all endpoints
2. **Build iOS app** - Follow SERVER_AND_IOS.md guide
3. **Add sentiment analysis** - Wire up news articles to predictor
4. **Real Vegas odds** - Get The Odds API key and integrate
5. **Deploy server** - Heroku, AWS, or DigitalOcean

## Architecture Diagram

```
┌─────────────────────────┐
│                         │
│   iOS App (SwiftUI)     │  ← You build this in Xcode
│   - Teams list          │
│   - Games view          │
│   - Predictions view    │
│   - News feed           │
│                         │
└───────────┬─────────────┘
            │ HTTP REST
            │ (JSON)
┌───────────▼─────────────┐
│                         │
│   Vapor Server          │  ← swift run nfl-server
│   - Caching             │
│   - Rate limiting       │
│   - API orchestration   │
│                         │
└────┬──────┬──────┬──────┘
     │      │      │
     ▼      ▼      ▼
   ESPN  NewsAPI  Odds
```

## Files Summary

- **Package.swift** - Added Vapor, server target, iOS platform support
- **Sources/OutcomePredictorAPI/** - Shared models between server/iOS
- **Sources/NFLServer/** - Vapor web server
- **Sources/OutcomePredictor/OddsDataSource.swift** - Vegas odds support
- **SERVER_AND_IOS.md** - Full documentation

All existing CLI tools (`swift run fetch-data`, etc.) still work!
