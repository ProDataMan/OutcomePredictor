# NFL Prediction Server and iOS App

This guide explains how to run the NFL prediction system as a client-server architecture.

## Architecture Overview

```
┌─────────────────┐
│                 │
│   iOS App       │  (SwiftUI)
│   (Client)      │
│                 │
└────────┬────────┘
         │ HTTP REST API
         │
┌────────▼────────┐
│                 │
│  Vapor Server   │  (Swift Backend)
│   (Backend)     │
│                 │
└────────┬────────┘
         │
         ├──► ESPN API (Game Data)
         ├──► NewsAPI (Articles)
         └──► The Odds API (Vegas Odds)
```

## Benefits of This Architecture

- **Security**: API keys stay on server
- **Performance**: Server handles caching and rate limiting
- **Scalability**: Multiple iOS clients can share same server
- **Offline Support**: iOS app can cache server responses

## Running the Server

### 1. Build the Server

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
swift build --product nfl-server
```

### 2. Set Environment Variables

```bash
export NEWS_API_KEY="168084c7268f48b48f2e4eec0ddca9cd"
# Optional: export ODDS_API_KEY="your_odds_api_key"
```

### 3. Start the Server

```bash
swift run nfl-server
```

The server starts on `http://localhost:8080` by default.

### 4. Test the API

```bash
# Health check
curl http://localhost:8080/health

# Get all teams
curl http://localhost:8080/api/v1/teams

# Get Chiefs 2024 games
curl "http://localhost:8080/api/v1/games?team=KC&season=2024"

# Get Chiefs news
curl "http://localhost:8080/api/v1/news?team=KC&limit=5"

# Make a prediction
curl -X POST http://localhost:8080/api/v1/predictions \
  -H "Content-Type: application/json" \
  -d '{
    "home_team_abbreviation": "KC",
    "away_team_abbreviation": "BUF",
    "season": 2024,
    "week": 13
  }'
```

## API Endpoints

### GET /health
Health check endpoint.

**Response**: `"OK"`

### GET /api/v1/teams
List all NFL teams.

**Response**:
```json
{
  "data": [
    {
      "abbreviation": "KC",
      "name": "Kansas City Chiefs",
      "conference": "afc",
      "division": "west"
    }
  ],
  "timestamp": "2024-11-25T08:00:00Z",
  "cached": false
}
```

### GET /api/v1/games
Get games for a team.

**Parameters**:
- `team` (required): Team abbreviation (e.g., "KC")
- `season` (required): Season year (e.g., 2024)

**Response**:
```json
{
  "data": [
    {
      "id": "uuid",
      "home_team": {...},
      "away_team": {...},
      "scheduled_date": "2024-09-06T00:40:00Z",
      "week": 1,
      "season": 2024,
      "home_score": 27,
      "away_score": 20,
      "winner": "home"
    }
  ],
  "timestamp": "2024-11-25T08:00:00Z",
  "cached": true
}
```

### GET /api/v1/news
Get recent news for a team.

**Parameters**:
- `team` (required): Team abbreviation
- `limit` (optional): Max articles (default: 10)

**Response**:
```json
{
  "data": [
    {
      "title": "Chiefs Win Big",
      "content": "...",
      "source": "ESPN",
      "published_date": "2024-11-24T10:00:00Z",
      "team_abbreviations": ["KC"]
    }
  ],
  "timestamp": "2024-11-25T08:00:00Z",
  "cached": false
}
```

### POST /api/v1/predictions
Make a game prediction.

**Request Body**:
```json
{
  "home_team_abbreviation": "KC",
  "away_team_abbreviation": "BUF",
  "scheduled_date": "2024-12-01T20:00:00Z",
  "week": 13,
  "season": 2024
}
```

**Response**:
```json
{
  "data": {
    "game_id": "uuid",
    "home_team": {...},
    "away_team": {...},
    "scheduled_date": "2024-12-01T20:00:00Z",
    "location": "Kansas City",
    "week": 13,
    "season": 2024,
    "home_win_probability": 0.466,
    "away_win_probability": 0.534,
    "confidence": 0.90,
    "reasoning": "...",
    "vegas_odds": {
      "home_moneyline": -155,
      "away_moneyline": 135,
      "spread": -3.5,
      "total": 47.5,
      "home_implied_probability": 0.608,
      "away_implied_probability": 0.425,
      "bookmaker": "Mock (Demo)"
    }
  },
  "timestamp": "2024-11-25T08:00:00Z",
  "cached": false
}
```

## Creating the iOS App

### 1. Create a New iOS Project

In Xcode:
1. File → New → Project
2. Choose "App" template
3. Product Name: "NFLPredictor"
4. Interface: SwiftUI
5. Save location: `/Users/baysideuser/GitRepos/NFLPredictor-iOS`

### 2. Add Package Dependency

In Xcode:
1. File → Add Package Dependencies
2. Enter: `/Users/baysideuser/GitRepos/OutcomePredictor`
3. Select "OutcomePredictorAPI" library

### 3. Create Network Service

Create `Services/APIClient.swift`:

```swift
import Foundation
import OutcomePredictorAPI

@MainActor
class APIClient: ObservableObject {
    private let baseURL = "http://localhost:8080/api/v1"
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func fetchTeams() async throws -> [TeamDTO] {
        let url = URL(string: "\(baseURL)/teams")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(APIResponse<[TeamDTO]>.self, from: data)
        return response.data
    }

    func fetchGames(team: String, season: Int) async throws -> [GameDTO] {
        let url = URL(string: "\(baseURL)/games?team=\(team)&season=\(season)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(APIResponse<[GameDTO]>.self, from: data)
        return response.data
    }

    func fetchNews(team: String, limit: Int = 10) async throws -> [ArticleDTO] {
        let url = URL(string: "\(baseURL)/news?team=\(team)&limit=\(limit)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(APIResponse<[ArticleDTO]>.self, from: data)
        return response.data
    }

    func makePrediction(
        home: String,
        away: String,
        season: Int,
        week: Int? = nil
    ) async throws -> PredictionDTO {
        let url = URL(string: "\(baseURL)/predictions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PredictionRequest(
            homeTeamAbbreviation: home,
            awayTeamAbbreviation: away,
            scheduledDate: nil,
            week: week,
            season: season
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try decoder.decode(APIResponse<PredictionDTO>.self, from: data)
        return response.data
    }
}
```

### 4. Create SwiftUI Views

Create `Views/TeamsListView.swift`:

```swift
import SwiftUI
import OutcomePredictorAPI

struct TeamsListView: View {
    @StateObject private var apiClient = APIClient()
    @State private var teams: [TeamDTO] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    List(teams, id: \.abbreviation) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            VStack(alignment: .leading) {
                                Text(team.name)
                                    .font(.headline)
                                Text("\(team.conference.uppercased()) \(team.division.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("NFL Teams")
            .task {
                await loadTeams()
            }
        }
    }

    private func loadTeams() async {
        isLoading = true
        error = nil

        do {
            teams = try await apiClient.fetchTeams()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
```

### 5. Run the App

1. Start the Vapor server: `swift run nfl-server`
2. Build and run the iOS app in Xcode
3. The app will fetch data from your local server

## Production Deployment

### Server Deployment

Deploy the Vapor server to:
- **Heroku**: Easy deployment with free tier
- **AWS EC2/Lambda**: Scalable cloud hosting
- **DigitalOcean**: Simple VPS option
- **Vapor Cloud**: Specialized Vapor hosting

Update `baseURL` in iOS app to your production server:
```swift
private let baseURL = "https://your-app.herokuapp.com/api/v1"
```

### iOS App Configuration

For production:
1. Add proper error handling
2. Implement caching with CoreData or SwiftData
3. Add loading indicators
4. Handle network failures gracefully
5. Submit to App Store

## Next Steps

1. ✅ Server is ready to run
2. Create iOS app in Xcode
3. Add more SwiftUI views (games list, prediction view, news feed)
4. Implement proper error handling
5. Add offline support with local caching
6. Deploy server to production

## Troubleshooting

### Server won't start
- Check port 8080 is not in use: `lsof -i :8080`
- Verify Vapor installed: `swift package resolve`

### iOS app can't connect
- Ensure server is running: `curl http://localhost:8080/health`
- Check Info.plist allows localhost connections
- For simulator: use `http://localhost:8080`
- For device: use your Mac's IP address

### API returns errors
- Check server logs in terminal
- Verify API keys are set correctly
- Test endpoints with curl first
