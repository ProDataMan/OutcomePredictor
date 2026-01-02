# API Integration - Weather & Injury Endpoints

## Status: ✅ Complete

Successfully added server endpoints for weather and injury data that integrate with existing services.

## New Server Endpoints

### 1. Weather Endpoint
**Route**: `GET /api/v1/weather/:gameId`

**Functionality**:
- Fetches real-time weather forecast from OpenWeatherMap API
- Supports indoor stadiums (returns controlled conditions)
- Caches weather data for 1 hour
- Returns forecast closest to game time (within 5 days)

**Response**:
```json
{
  "temperature": 72.5,
  "condition": "Clear",
  "windSpeed": 10.2,
  "precipitation": 15.0,
  "humidity": 55.0,
  "timestamp": "2025-01-15T19:00:00Z"
}
```

**Integration**:
- Uses existing `OpenWeatherMapService` actor
- Handles indoor vs outdoor stadiums
- Provides current weather or 5-day forecast

### 2. Injury Endpoint  
**Route**: `GET /api/v1/injuries/:gameId`

**Functionality**:
- Fetches injury reports from ESPN API
- Calculates injury impact for both teams
- Caches injury data for 6 hours
- Returns comprehensive injury breakdown

**Response**:
```json
{
  "gameId": "abc-123",
  "homeTeam": {
    "team": { "name": "Chiefs", "abbreviation": "KC", ... },
    "injuries": [
      {
        "name": "Patrick Mahomes",
        "position": "QB",
        "status": "Questionable",
        "description": "Ankle injury"
      }
    ],
    "fetchedAt": "2025-01-15T12:00:00Z"
  },
  "awayTeam": { ... }
}
```

**Integration**:
- Uses existing `InjuryTracker` actor with `ESPNInjuryDataSource`
- Position-based impact calculation
- Supports all injury statuses (Out, Doubtful, Questionable, Probable, Healthy)

## Build Status

✅ Server compiles successfully
✅ All type signatures correct
✅ Error handling implemented
✅ Caching configured

## Next Steps

### iOS Integration
Update `GameDetailView.swift` to replace mock data:

```swift
private func loadInjuries() async {
    guard \!isCompleted else { return }
    
    isLoadingInjuries = true
    
    do {
        let apiClient = APIClient()
        let response = try await apiClient.fetchInjuries(gameId: game.id)
        
        homeInjuryReport = response.homeTeam
        awayInjuryReport = response.awayTeam
    } catch {
        // Handle error
        homeInjuryReport = nil
        awayInjuryReport = nil
    }
    
    isLoadingInjuries = false
}
```

### Android Integration
Update `GameDetailScreen` to populate caches before navigation:

```kotlin
// In ViewModel or Repository
suspend fun loadWeatherAndInjuries(gameId: String) {
    val weather = apiClient.fetchWeather(gameId)
    WeatherCache.putGameWeather(gameId, weather)
    
    val injuries = apiClient.fetchInjuries(gameId)
    InjuryCache.put(gameId, injuries.homeTeam, injuries.awayTeam)
}
```

## Configuration Required

### OpenWeatherMap API Key
Set environment variable or add to configuration:
```bash
OPENWEATHERMAP_API_KEY=your_api_key_here
```

Sign up for free tier (1,000 calls/day): https://openweathermap.org/api

### ESPN API  
No API key required - uses public ESPN API endpoints

## Testing

### Manual API Testing
```bash
# Test weather endpoint
curl http://localhost:8080/api/v1/weather/GAME_ID

# Test injury endpoint
curl http://localhost:8080/api/v1/injuries/GAME_ID
```

### Expected Behavior
- Weather: Returns forecast if game is within 5 days, returns "Indoor" for dome stadiums
- Injuries: Returns current injury reports with impact calculations
- Both: Return 404 if game not found, 503 if service unavailable

## Implementation Details

### Stadium Support
- 32 NFL stadiums mapped with coordinates
- 8 indoor stadiums identified (controlled environment)
- Weather API skipped for indoor games

### Caching Strategy
- **Weather**: 1 hour TTL (conditions change slowly)
- **Injuries**: 6 hours TTL (reports update daily)
- **Games**: Fetched live from DataLoader

### Error Handling
- Missing game ID → 400 Bad Request
- Game not found → 404 Not Found
- Service unavailable → 503 Service Unavailable
- API failures → Logged, returns error response

## Architecture Benefits

1. **Separation of Concerns**: Server handles data fetching, clients consume
2. **Caching**: Reduces API calls and improves performance
3. **Type Safety**: Response DTOs ensure consistency
4. **Extensibility**: Easy to add more weather/injury endpoints

## Files Modified

- `Sources/NFLServer/main.swift` - Added weather and injury endpoints
- Build verified successfully

## Documentation

- See `OpenWeatherMapService.swift` for weather service implementation
- See `InjuryTracker.swift` for injury tracking implementation
- See `ESPNInjuryDataSource.swift` for ESPN API integration
