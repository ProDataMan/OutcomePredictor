# Weather API Integration

Weather conditions significantly impact NFL game outcomes. This integration adds weather analysis to predictions using the OpenWeatherMap API.

## Impact on Predictions

Weather affects games in multiple ways:
- **Wind** (>15mph): Reduces passing efficiency 20-30%, favors run-heavy teams
- **Temperature** (<32°F): Affects ball handling, increases fumbles
- **Precipitation**: Heavy rain/snow favors rushing attacks
- **Dome Teams**: Struggle more in harsh outdoor conditions

## Setup

### 1. Get an API Key

Sign up for a free OpenWeatherMap account:
- Visit: https://openweathermap.org/api
- Free tier includes 1,000 calls/day
- 5-day forecast with 3-hour intervals

### 2. Configure Environment Variable

```bash
export OPENWEATHER_API_KEY="your-api-key-here"
```

Or add to your `.env` file:
```
OPENWEATHER_API_KEY=your-api-key-here
```

### 3. Restart the Server

The server will automatically detect and use the weather service:

```
✅ OpenWeatherMap service initialized for weather-enhanced predictions
```

If the API key is not found:
```
⚠️ OpenWeatherMap API key not found in environment (OPENWEATHER_API_KEY)
   Predictions will not include weather impact analysis
```

## How It Works

### Weather Factors Analyzed

1. **Wind Speed**
   - >20mph: -10% to -15% for pass-heavy teams
   - 15-20mph: -5% to -10% for pass-heavy teams
   - <15mph: Neutral

2. **Temperature**
   - <20°F: -8% base, -14% for dome teams
   - 20-32°F: -4% base, -8% for dome teams
   - >32°F: Neutral

3. **Precipitation Probability**
   - >70%: -8% for pass-heavy, +6% for run-heavy
   - 50-70%: -4% for pass-heavy, +3% for run-heavy
   - <50%: Neutral

### Team Style Detection

The system estimates each team's pass/run ratio based on scoring:
- Higher scoring teams (~28+ ppg) → 60-70% pass ratio
- Average teams (~24 ppg) → 55% pass ratio (NFL average)
- Lower scoring teams (~20 ppg) → 40-50% pass ratio

### Dome Team Detection

Teams playing in climate-controlled stadiums:
- Atlanta Falcons, Dallas Cowboys, Detroit Lions
- Houston Texans, Indianapolis Colts, New Orleans Saints
- Las Vegas Raiders, Minnesota Vikings, Arizona Cardinals

## Weight in Prediction Model

Weather impact weight: **12%** of total prediction

This makes it comparable to:
- Home/away splits (12%)
- Injury impact (15%)
- News sentiment (8%)

## Example Weather Impact

### Scenario 1: High Wind Game
```
Buffalo (pass-heavy, 65%) vs Miami (balanced, 52%)
Weather: 25mph winds, 35°F
Impact: Buffalo -12%, Miami -3%
```

### Scenario 2: Dome Team in Cold
```
New Orleans (dome team) @ Green Bay (outdoor)
Weather: 18°F, light snow
Impact: New Orleans -14%, Green Bay -4%
```

### Scenario 3: Rain Favors Run Game
```
San Francisco (run-heavy, 45%) vs Seattle (pass-heavy, 62%)
Weather: 85% rain probability, 50°F
Impact: San Francisco +6%, Seattle -8%
```

## API Response

Weather details appear in the prediction reasoning:

```json
{
  "reasoning": "...\n\nWeather Conditions:\nStrong wind (22mph) - passing difficult; Likely precipitation (75%) - favors rush\n\n..."
}
```

## Caching

Weather forecasts are cached for 1 hour to minimize API calls:
- Indoor games: Cached indefinitely (always "Indoor")
- Outdoor games: 1-hour cache per location/time

## Limitations

1. **Forecast Window**: Only available for games within 5 days
2. **Estimation**: Team pass/run ratios estimated from scoring, not play-by-play
3. **Stadium Updates**: Requires manual updates if teams move/change stadiums
4. **API Limits**: Free tier = 1,000 calls/day

## Future Enhancements

Potential improvements:
1. Integrate play-by-play data for accurate pass/run ratios
2. Add historical weather performance (team records in cold/wind/rain)
3. Include humidity and visibility factors
4. Add snow accumulation depth analysis
5. Consider wind direction (crosswind vs headwind)

## Troubleshooting

### Weather not appearing in predictions

Check server logs for:
```
⚠️ OpenWeatherMap API key not found
```

Solution: Set `OPENWEATHER_API_KEY` environment variable

### API rate limit exceeded

Free tier = 1,000 calls/day. If exceeded:
- Predictions continue without weather analysis
- Error logged: "Weather forecast not available"
- Consider upgrading to paid tier or implementing more aggressive caching

### Invalid location errors

If a team location isn't recognized:
- Check `OpenWeatherMapService.swift` stadium locations
- Add missing team with coordinates
- Submit PR with updated stadium database

## Testing

Test weather integration locally:

```bash
# Set API key
export OPENWEATHER_API_KEY="your-key"

# Start server
swift run NFLServer

# Make prediction (will include weather if game is within 5 days)
curl -X POST http://localhost:8080/api/v1/predictions \
  -H "Content-Type: application/json" \
  -d '{
    "homeTeamAbbreviation": "GB",
    "awayTeamAbbreviation": "CHI",
    "season": 2024,
    "scheduledDate": "2024-12-30T13:00:00Z"
  }'
```

Look for weather details in the response reasoning field.
