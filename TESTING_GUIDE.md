# Testing Guide: Server + iOS App

This guide walks through running the NFL prediction server and building an iOS app to test it.

## Part 1: Running the Server

### Step 1: Start the Server

Open Terminal and run:

```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
export NEWS_API_KEY="168084c7268f48b48f2e4eec0ddca9cd"
.build/debug/nfl-server
```

You should see:
```
[ NOTICE ] Server starting on http://127.0.0.1:8080
```

Keep this terminal window open - the server needs to stay running.

### Step 2: Test Server Endpoints

Open a new terminal tab and test each endpoint:

```bash
# Health check
curl http://localhost:8080/health

# Get all teams (should return 32 teams)
curl http://localhost:8080/api/v1/teams | python3 -m json.tool

# Get Chiefs 2024 games
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

## Part 2: Creating the iOS App

### Step 1: Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose "App" template (under iOS)
4. Configuration:
   - Product Name: `NFLPredictor`
   - Team: (your team)
   - Organization Identifier: `com.yourcompany`
   - Interface: **SwiftUI**
   - Language: **Swift**
5. Save location: `/Users/baysideuser/GitRepos/NFLPredictor-iOS`

### Step 2: Add Package Dependency

1. In Xcode, select your project in the navigator
2. Select the target `NFLPredictor`
3. Go to "General" tab
4. Scroll to "Frameworks, Libraries, and Embedded Content"
5. Click the "+" button
6. Click "Add Package Dependency..."
7. In the search field, enter: `/Users/baysideuser/GitRepos/OutcomePredictor`
8. Click "Add Package"
9. Select **OutcomePredictorAPI** library
10. Click "Add Package"

### Step 3: Create API Client

Create a new Swift file: `Services/APIClient.swift`

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
        return try decoder.decode([TeamDTO].self, from: data)
    }

    func fetchGames(team: String, season: Int) async throws -> [GameDTO] {
        let url = URL(string: "\(baseURL)/games?team=\(team)&season=\(season)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode([GameDTO].self, from: data)
    }

    func fetchNews(team: String, limit: Int = 10) async throws -> [ArticleDTO] {
        let url = URL(string: "\(baseURL)/news?team=\(team)&limit=\(limit)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode([ArticleDTO].self, from: data)
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
        return try decoder.decode(PredictionDTO.self, from: data)
    }
}
```

### Step 4: Create Teams List View

Replace the contents of `ContentView.swift`:

```swift
import SwiftUI
import OutcomePredictorAPI

struct ContentView: View {
    @StateObject private var apiClient = APIClient()
    @State private var teams: [TeamDTO] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading teams...")
                } else if let error = error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.title)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            Task {
                                await loadTeams()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
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

### Step 5: Create Team Detail View

Create `Views/TeamDetailView.swift`:

```swift
import SwiftUI
import OutcomePredictorAPI

struct TeamDetailView: View {
    let team: TeamDTO
    @StateObject private var apiClient = APIClient()
    @State private var games: [GameDTO] = []
    @State private var news: [ArticleDTO] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Team Header
                VStack(alignment: .leading) {
                    Text(team.name)
                        .font(.largeTitle)
                        .bold()
                    Text("\(team.conference.uppercased()) \(team.division.capitalized)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()

                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Recent Games
                    VStack(alignment: .leading) {
                        Text("Recent Games")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        ForEach(games.prefix(5), id: \.id) { game in
                            GameRowView(game: game, teamAbbr: team.abbreviation)
                        }
                    }

                    // Recent News
                    VStack(alignment: .leading) {
                        Text("Recent News")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                            .padding(.top)

                        ForEach(news.prefix(3), id: \.title) { article in
                            NewsRowView(article: article)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        error = nil

        do {
            async let gamesTask = apiClient.fetchGames(team: team.abbreviation, season: 2024)
            async let newsTask = apiClient.fetchNews(team: team.abbreviation, limit: 5)

            games = try await gamesTask
            news = try await newsTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct GameRowView: View {
    let game: GameDTO
    let teamAbbr: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(game.awayTeam.abbreviation) @ \(game.homeTeam.abbreviation)")
                    .font(.headline)
                if let homeScore = game.homeScore,
                   let awayScore = game.awayScore {
                    Text("\(awayScore) - \(homeScore)")
                        .font(.subheadline)
                        .foregroundColor(didWin ? .green : .red)
                }
                Text(game.scheduledDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let winner = game.winner {
                Image(systemName: didWin ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(didWin ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    var didWin: Bool {
        if game.homeTeam.abbreviation == teamAbbr {
            return game.winner == "home"
        } else {
            return game.winner == "away"
        }
    }
}

struct NewsRowView: View {
    let article: ArticleDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.headline)
            Text(article.source)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(article.publishedDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
```

### Step 6: Configure Network Permissions

iOS apps need permission to access localhost. Add this to your `Info.plist`:

1. In Xcode, select `Info.plist` (or Info tab of your target)
2. Add a new key: `App Transport Security Settings` (Dictionary)
3. Inside it, add: `Allow Arbitrary Loads in Web Content` (Boolean) = YES
4. Also add: `NSAllowsLocalNetworking` (Boolean) = YES

Or add this XML to Info.plist if editing as source code:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## Part 3: Running Everything

### Complete Test Flow

**Terminal 1: Run Server**
```bash
cd /Users/baysideuser/GitRepos/OutcomePredictor
export NEWS_API_KEY="168084c7268f48b48f2e4eec0ddca9cd"
.build/debug/nfl-server
```

**Xcode: Run iOS App**
1. Select iPhone simulator (iPhone 15 Pro recommended)
2. Press Cmd+R to build and run
3. App should launch and show list of 32 NFL teams

**Test the Flow:**
1. App loads → Shows "Loading teams..." → Shows team list
2. Tap "Kansas City Chiefs" → Shows games and news
3. Navigate back and try other teams

**Terminal 2: Watch Server Logs**
You'll see requests in the server terminal:
```
[ INFO ] GET /api/v1/teams
[ INFO ] GET /api/v1/games?team=KC&season=2024
[ INFO ] GET /api/v1/news?team=KC&limit=5
```

## Troubleshooting

### iOS App Shows "Error"

**Issue:** Connection refused or timeout

**Solutions:**
1. Check server is running: `curl http://localhost:8080/health`
2. Check Info.plist has network permissions
3. Simulator and server must be on same machine
4. Try restarting the simulator

### Server Won't Start

**Issue:** Port 8080 already in use

**Solution:**
```bash
# Find process using port 8080
lsof -i :8080

# Kill it
kill -9 <PID>
```

### "No such module 'OutcomePredictorAPI'"

**Issue:** Package dependency not added correctly

**Solution:**
1. Select project in Xcode
2. Select target
3. Go to "Build Phases"
4. Check "Link Binary With Libraries" has OutcomePredictorAPI
5. Clean build folder (Cmd+Shift+K) and rebuild

### Teams Load But No Games/News

**Issue:** ESPN or NewsAPI not responding

**Solution:**
1. Check server logs for API errors
2. Verify NEWS_API_KEY is set
3. Test endpoints directly with curl
4. ESPN might be rate limiting - wait and retry

## Next Steps

1. **Add Prediction View** - Create UI to select two teams and show prediction
2. **Add Vegas Odds Integration** - Get The Odds API key and replace mock data
3. **Add Caching** - Use SwiftData or CoreData to cache responses
4. **Add Error Handling** - Better error messages and retry logic
5. **Deploy Server** - Host on Heroku, AWS, or DigitalOcean for production
6. **Submit to App Store** - Polish UI and submit for review

## Architecture Summary

```
┌─────────────────────────┐
│   iOS App (Simulator)   │
│   - Teams List          │
│   - Team Details        │
│   - Games & News        │
│   http://localhost:8080 │
└────────────┬────────────┘
             │ REST API (JSON)
┌────────────▼────────────┐
│   Vapor Server          │
│   - /api/v1/teams       │
│   - /api/v1/games       │
│   - /api/v1/news        │
│   - /api/v1/predictions │
└────────┬────────────────┘
         │
    ┌────┼────┐
    ▼    ▼    ▼
  ESPN  News  Odds
         API
```

All data flows through the server, keeping API keys secure and enabling caching for better performance.
