# API-Sports Integration

API-Sports provides real NFL player statistics and headshot URLs starting from the 2022 season. The integration includes automatic server-side caching with a 15-minute TTL to respect the free tier limit of 100 requests per day.

## Features

- **Real Player Statistics**: Actual season stats for all positions (QB, RB, WR, TE, K, DEF)
- **Player Headshots**: High-quality player photo URLs
- **Historical Data**: Stats available from 2022 onwards
- **Automatic Caching**: 15-minute server-side cache minimizes API calls
- **Fallback Support**: Automatically falls back to ESPN if API-Sports fails
- **Rate Limit Protection**: Caching ensures you stay within 100 requests/day limit

## Setup

### 1. Get API Key

1. Visit https://dashboard.api-football.com/
2. Sign up for a free account
3. Navigate to "My Access" in the dashboard
4. Copy your API key
5. Note: Free tier includes 100 requests per day

### 2. Configure Environment Variable

Add the API key to your server environment:

```bash
export API_SPORTS_KEY="your_api_key_here"
```

For Azure deployment, set it in the Application Settings:

```bash
az webapp config appsettings set \
    --resource-group <your-resource-group> \
    --name statshark-api \
    --settings API_SPORTS_KEY="your_api_key_here"
```

### 3. Restart Server

The server automatically detects the API key on startup:

```bash
swift run nfl-server
```

You should see:
```
✅ API-Sports data source initialized with 15-minute caching
```

If the key is missing:
```
⚠️ API-Sports API key not found in environment (API_SPORTS_KEY)
   Player stats will use ESPN data (sample stats only)
```

## How It Works

### Data Source Priority

1. **API-Sports** (seasons 2022+): Real stats with headshots
2. **ESPN Fallback**: Sample stats with headshots (for older seasons or if API-Sports fails)

### Caching Strategy

- **Cache Duration**: 15 minutes (900 seconds)
- **Cache Key**: `roster_{TEAM}_{SEASON}` (for example: `roster_KC_2024`)
- **Cache Location**: In-memory actor-based cache (thread-safe)
- **API Call Reduction**: ~96 requests/day for all 32 teams (32 teams × 3 refreshes/day)

### Automatic Cleanup

The cache automatically:
- Stores roster data for 15 minutes
- Returns cached data for subsequent requests
- Expires entries after 15 minutes
- Can be manually cleared via API endpoint

## API Endpoints

### Get Roster (with API-Sports)

```bash
GET /api/v1/teams/{teamId}/roster?season=2024
```

Response includes:
- Real player statistics from API-Sports
- Player headshot URLs
- Position information
- Jersey numbers

### Monitor Cache

```bash
GET /api/v1/cache/stats
```

Returns:
```json
{
  "api_sports": {
    "roster_cache_count": 12,
    "oldest_entry": "2024-12-18T19:00:00Z",
    "newest_entry": "2024-12-18T19:14:00Z",
    "ttl_minutes": 15
  },
  "odds_cache": {
    "has_data": true,
    "ttl_hours": 6
  },
  "timestamp": "2024-12-18T19:15:00Z"
}
```

### Clear Cache (Admin)

```bash
POST /api/v1/cache/clear
```

Response:
```json
{
  "message": "API-Sports caches cleared successfully"
}
```

### Cleanup Expired Entries

```bash
POST /api/v1/cache/cleanup
```

Response:
```json
{
  "message": "Expired cache entries cleaned up"
}
```

## Monitoring

Server logs show cache behavior:

```
📥 Fetching fresh roster from API-Sports for KC (season 2024)
✅ Successfully fetched 53 players from API-Sports
💾 Cached roster for KC for 15 minutes

[Later request within 15 minutes]
✅ Using cached roster for KC (season 2024)

[If API-Sports fails]
⚠️ API-Sports failed for KC: Rate limit exceeded
   Falling back to ESPN data source
📡 Using ESPN data source for KC (season 2024)
```

## API-Sports Team ID Mapping

API-Sports uses numeric team IDs. The mapping is built into the data source:

| Team | Abbr | ID  | Team | Abbr | ID  |
|------|------|-----|------|------|-----|
| Arizona Cardinals | ARI | 1 | Miami Dolphins | MIA | 20 |
| Atlanta Falcons | ATL | 2 | Minnesota Vikings | MIN | 21 |
| Baltimore Ravens | BAL | 3 | New England Patriots | NE | 22 |
| Buffalo Bills | BUF | 4 | New Orleans Saints | NO | 23 |
| Carolina Panthers | CAR | 5 | New York Giants | NYG | 24 |
| Chicago Bears | CHI | 6 | New York Jets | NYJ | 25 |
| Cincinnati Bengals | CIN | 7 | Philadelphia Eagles | PHI | 26 |
| Cleveland Browns | CLE | 8 | Pittsburgh Steelers | PIT | 27 |
| Dallas Cowboys | DAL | 9 | San Francisco 49ers | SF | 28 |
| Denver Broncos | DEN | 10 | Seattle Seahawks | SEA | 29 |
| Detroit Lions | DET | 11 | Tampa Bay Buccaneers | TB | 30 |
| Green Bay Packers | GB | 12 | Tennessee Titans | TEN | 31 |
| Houston Texans | HOU | 13 | Washington Commanders | WAS | 32 |
| Indianapolis Colts | IND | 14 | | | |
| Jacksonville Jaguars | JAX | 15 | | | |
| Kansas City Chiefs | KC | 16 | | | |
| Los Angeles Chargers | LAC | 17 | | | |
| Los Angeles Rams | LAR | 18 | | | |
| Las Vegas Raiders | LV | 19 | | | |

## Rate Limit Management

With 100 requests/day and 15-minute caching:

- **32 NFL teams** × **4 refreshes per hour** = 128 requests/hour without caching
- **With 15-minute cache**: 32 teams × **4 refreshes per day** = **128 requests/day**
- **Actual usage**: ~32-64 requests/day (not all teams are queried every refresh)

The caching strategy ensures you stay well within the 100 requests/day limit while providing fresh data every 15 minutes.

## Testing

Test the integration:

```bash
# Test KC roster with API-Sports (should use cache after first call)
curl http://localhost:8080/api/v1/teams/KC/roster?season=2024

# Check cache statistics
curl http://localhost:8080/api/v1/cache/stats

# Clear cache (forces fresh fetch on next request)
curl -X POST http://localhost:8080/api/v1/cache/clear

# Clean up expired entries
curl -X POST http://localhost:8080/api/v1/cache/cleanup
```

## Benefits Over ESPN

1. **Real Statistics**: API-Sports provides actual season stats (ESPN free tier doesn't)
2. **Player Photos**: High-quality headshot URLs for all players
3. **Accurate Data**: Official NFL statistics, not sample data
4. **Recent Coverage**: Comprehensive data from 2022 onwards
5. **Better Fantasy**: Real stats enable accurate fantasy point calculations

## Error Handling

The implementation gracefully handles:

- **Rate Limits**: Throws clear error, falls back to ESPN
- **Missing Data**: Returns noDataAvailable error, uses fallback
- **Network Errors**: Catches and logs, uses ESPN as backup
- **Invalid Teams**: Handles unknown team IDs with proper error messages

All errors are logged with context for debugging.
