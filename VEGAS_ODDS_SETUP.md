# Vegas Odds Integration Guide

This guide explains how to integrate real-time Vegas betting odds from The Odds API.

## Overview

The app now supports real-time betting odds from The Odds API, showing:
- **Moneylines** (home and away)
- **Point spreads**
- **Over/under totals**
- **Implied probabilities**
- **Bookmaker information**

When odds are available, they appear in the prediction view alongside your AI predictions.

## Getting an API Key

1. Go to **https://the-odds-api.com/**
2. Click "Get a Free API Key"
3. Sign up with your email
4. Verify your email
5. Copy your API key from the dashboard

### Free Tier Limits
- **500 requests/month**
- Perfect for development and testing
- Each prediction request uses 1 API call

## Configuring the Server

### Method 1: Environment Variable (Recommended)

Set the `ODDS_API_KEY` environment variable before starting the server:

```bash
export ODDS_API_KEY="your_api_key_here"
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift run nfl-server serve --hostname 0.0.0.0 --port 8085
```

### Method 2: Launch Script

Update your server launch script:

```bash
#!/bin/bash
export ODDS_API_KEY="your_api_key_here"
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift run nfl-server serve --hostname 0.0.0.0 --port 8085
```

### Method 3: .env File (Not Yet Implemented)

Create a `.env` file in the project root:

```
ODDS_API_KEY=your_api_key_here
NEWS_API_KEY=168084c7268f48b48f2e4eec0ddca9cd
```

## How It Works

### Server Behavior

1. **With API Key**: Server fetches real odds from The Odds API for each prediction
2. **Without API Key**: Server falls back to mock odds (bookmaker shows "Mock (Demo)")

### Team Name Matching

The Odds API returns team names in full format (e.g., "Kansas City Chiefs"), so the server matches:
- API format: `"Kansas City Chiefs @ Buffalo Bills"`
- Our format: Team abbreviations (KC, BUF) → Full names

### Caching (Not Yet Implemented)

To reduce API calls:
- Cache odds for 15 minutes
- Reuse cached odds for same matchup
- Could add caching in future update

## Testing the Integration

### 1. Verify Server Configuration

```bash
# Check if API key is set
echo $ODDS_API_KEY

# Should output your API key (or nothing if not set)
```

### 2. Make a Test Prediction

From the iOS app:
1. Select two teams (e.g., Kansas City vs Buffalo)
2. Tap "Make Prediction"
3. Check the Vegas Odds section:
   - If bookmaker shows "Mock (Demo)" → Using fake odds
   - If bookmaker shows "DraftKings", "FanDuel", etc. → Real odds!

### 3. Monitor API Usage

Check your usage at: https://the-odds-api.com/account/

The dashboard shows:
- Requests made today
- Requests remaining this month
- Request history

## API Response Example

The Odds API returns data like this:

```json
{
  "id": "abc123",
  "sport_key": "americanfootball_nfl",
  "commence_time": "2024-12-01T18:00:00Z",
  "home_team": "Kansas City Chiefs",
  "away_team": "Buffalo Bills",
  "bookmakers": [
    {
      "title": "DraftKings",
      "markets": [
        {
          "key": "h2h",
          "outcomes": [
            {"name": "Kansas City Chiefs", "price": -155},
            {"name": "Buffalo Bills", "price": 135}
          ]
        },
        {
          "key": "spreads",
          "outcomes": [
            {"name": "Kansas City Chiefs", "price": -110, "point": -3.5},
            {"name": "Buffalo Bills", "price": -110, "point": 3.5}
          ]
        },
        {
          "key": "totals",
          "outcomes": [
            {"name": "Over", "price": -110, "point": 47.5},
            {"name": "Under", "price": -110, "point": 47.5}
          ]
        }
      ]
    }
  ]
}
```

## Troubleshooting

### Odds Show "Mock (Demo)"

**Cause**: API key not set or invalid

**Fix**:
1. Verify `ODDS_API_KEY` environment variable is set
2. Check API key is correct (no extra spaces)
3. Restart the server after setting the variable

### Error: "Failed to fetch Vegas odds"

**Cause**: API request failed (network, invalid key, or rate limit)

**Fix**:
1. Check internet connection
2. Verify API key at https://the-odds-api.com/account/
3. Check if you've exceeded 500 requests/month
4. Review server logs for detailed error

### Odds Don't Match Game

**Cause**: Team name mismatch between our system and The Odds API

**Fix**:
- The Odds API uses full team names
- Our system converts abbreviations to full names
- Check `/Users/baysideuser/GitRepos/OutcomePredictor/Sources/NFLServer/main.swift` lines 222-224 for matching logic

## Code References

### Server Integration
- **Main configuration**: `/Sources/NFLServer/main.swift:43-47`
- **Odds fetching**: `/Sources/NFLServer/main.swift:215-241`
- **Team matching**: `/Sources/NFLServer/main.swift:222-224`

### Odds Data Source
- **API client**: `/Sources/OutcomePredictor/OddsDataSource.swift`
- **BettingOdds model**: Lines 4-37
- **TheOddsAPIDataSource**: Lines 39-140

### iOS Display
- **VegasOddsView**: `/NFLOutcomePredictor/PredictionView.swift:429-543`
- **Odds DTO**: `/NFLOutcomePredictor/DTOs.swift:134-163`

## Future Enhancements

Potential improvements:
1. **Odds caching** - Reduce API calls by caching for 15 minutes
2. **Multiple bookmakers** - Show odds from DraftKings, FanDuel, BetMGM
3. **Odds comparison** - Find best lines across bookmakers
4. **Line movement** - Track how odds change over time
5. **Opening lines** - Show where odds started vs current
6. **Sharp money indicators** - Detect when pros are betting

## Resources

- **The Odds API Docs**: https://the-odds-api.com/liveapi/guides/v4/
- **API Dashboard**: https://the-odds-api.com/account/
- **Pricing**: https://the-odds-api.com/pricing/
