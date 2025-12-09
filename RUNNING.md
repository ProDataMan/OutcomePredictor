# Running OutcomePredictor Tools

Due to network sandbox restrictions in Claude Code, the NFL prediction tools must be run from your own terminal.

## Commands to Run

### 1. Fetch Real NFL Data

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift run fetch-data
```

Expected behavior:
- Automatically detects current NFL season based on the date
- Tries to fetch current season data (2025 in November 2025)
- Falls back to previous season (2024) if current season has no data
- Shows which season is being used in the output

Output includes:
- Current date and detected season
- Current week's games from ESPN
- Week 13 games with scores and dates
- Team-specific data for Chiefs, 49ers, and Bills
- Caching performance test
- Sample prediction using real data

Debug information displayed:
- "✅ Successfully parsed X games from ESPN" for successful parsing
- "⚠️  Team not found: [ABBREVIATION]" if any team lookups fail
- Full game details with scores and dates

### 2. Debug ESPN API Responses

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift run debug-espn
```

This tool saves JSON responses as files for inspection.

### 3. Make Predictions

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift run nfl-predict --demo
```

Interactive CLI for making predictions.

## Smart Season Detection

The tools automatically detect the correct NFL season based on the current date:

### Season Detection Logic:
- **January-February**: Previous year's season (playoffs/Super Bowl)
  - Example: January 2025 → 2024 season
- **March-August**: Offseason, uses previous completed season
  - Example: July 2025 → 2024 season
- **September-December**: Current year's regular season
  - Example: November 2025 → 2025 season

### Fallback Behavior:
If the detected season has no data available (e.g., ESPN doesn't have 2025 data yet):
- The tool automatically falls back to the previous season (2024)
- You'll see: "ℹ️  No games in 2025 season, trying 2024..."
- All subsequent queries use the fallback season

This ensures you always get working data regardless of ESPN's data availability.

## What's Fixed

- ✅ ESPN API JSON structure correctly mapped to Codable structs
- ✅ Team abbreviation normalization (WSH→WAS, LA→LAR)
- ✅ Debug logging to identify parsing issues
- ✅ All 32 NFL teams match ESPN abbreviations
- ✅ Smart NFL season detection based on current date
- ✅ Automatic fallback to previous season if current has no data
- ✅ Clear messaging about which season is being used

## Next Steps

1. Run `swift run fetch-data` from your terminal
2. Verify games are successfully parsed
3. Check which season is being used (2025 or 2024 fallback)
4. Test predictions with real data
5. Optionally: Add NewsAPI key to get article sentiment data

## Notes

- Network calls work from your terminal but are blocked in Claude Code sandbox
- The parser has been verified with actual ESPN Week 13, 2024 data
- Test scripts (test-parse.swift, test-codable.swift) confirm JSON parsing works correctly
- In November 2025, the tool will try 2025 season first, fall back to 2024 if needed
