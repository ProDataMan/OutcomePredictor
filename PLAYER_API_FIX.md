# Player Details API Fix

## Problem

The Android app expected additional player bio fields (height, weight, age, college, experience) in the PlayerDTO that were not being provided by the API. These fields are displayed in the Android PlayerDetailScreen but were missing from the server response.

## Solution

Updated the Player model, PlayerDTO, and data sources to include and extract player bio data.

### Changes Made

#### 1. Player Model (Sources/OutcomePredictor/Player.swift)

Added bio fields to the Player struct:
- `height: String?` - Player height (e.g., "6' 3\"")
- `weight: Int?` - Player weight in pounds
- `age: Int?` - Player age
- `college: String?` - College name
- `experience: Int?` - Years of NFL experience

#### 2. PlayerDTO (Sources/OutcomePredictorAPI/DTOs.swift)

Added the same bio fields to PlayerDTO to expose them in API responses.

#### 3. Mapper (Sources/OutcomePredictorAPI/Mappers.swift)

Updated the PlayerDTO mapper to include the new bio fields when converting from Player to PlayerDTO.

#### 4. ESPN Data Source (Sources/OutcomePredictor/ESPNPlayerDataSource.swift)

Updated ESPNAthlete structure to include:
- `age: Int?`
- `displayHeight: String?`
- `displayWeight: String?`
- `weight: Double?`
- `debutYear: Int?`
- `college: ESPNCollege?`

Updated parseRoster to extract these fields from ESPN API responses:
- Height from `displayHeight`
- Weight parsed from `displayWeight` (e.g., "215 lbs")
- Age from `age`
- College from `college.name`
- Experience calculated from `debutYear` (season - debutYear)

#### 5. API-Sports Data Source (Sources/OutcomePredictor/APISportsDataSource.swift)

Updated parseRoster to extract bio data:
- Height from `player.height.US`
- Weight parsed from `player.weight.US`
- Age from `player.age`
- College: Not available from API-Sports (set to nil)
- Experience: Not available from API-Sports (set to nil)

## API Response Format

The roster endpoint now returns player data with bio fields:

```json
{
  "team": { ... },
  "season": 2024,
  "players": [
    {
      "id": "123",
      "name": "Patrick Mahomes",
      "position": "QB",
      "jersey_number": "15",
      "photo_url": "https://...",
      "height": "6' 3\"",
      "weight": 230,
      "age": 28,
      "college": "Texas Tech",
      "experience": 7,
      "stats": { ... }
    }
  ]
}
```

## Data Sources

### ESPN API

Provides:
- ✅ Height (displayHeight)
- ✅ Weight (displayWeight, weight)
- ✅ Age
- ✅ College (college.name)
- ✅ Experience (calculated from debutYear)

### API-Sports

Provides:
- ✅ Height (height.US)
- ✅ Weight (weight.US)
- ✅ Age
- ❌ College (not available)
- ❌ Experience (not available)

## Testing

The changes were verified using:
1. Swift build - All modules compile successfully
2. JSON encoding/decoding test - Confirms snake_case conversion works correctly
3. ESPN API live test - Confirms bio data is available from ESPN

## Next Steps

To test the full integration:
1. Start the server: `swift run nfl-server`
2. Query roster: `curl http://localhost:8080/api/v1/teams/KC/roster?season=2024`
3. Verify player objects include bio fields
4. Test with mobile apps (iOS and Android)
