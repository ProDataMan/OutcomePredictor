# StatShark - NFL Outcome Predictor

StatShark predicts NFL game outcomes using AI and comprehensive data analysis. This project implements a production-ready
system combining traditional statistics with natural language processing through server-side Swift and native iOS
application.

## Project Status

### ✅ Completed Features

**Server-Side (Swift Vapor)**
- REST API with comprehensive endpoints (teams, games, predictions, odds, news)
- AsyncHTTPClient integration for optimal Linux performance
- Actor-based HTTP caching system (configurable TTL)
- ESPN API integration for live scores and schedules
- The Odds API integration for betting lines
- LLM-based predictions using Claude AI
- Docker containerization with multi-platform support (linux/amd64, linux/arm64)
- Environment variable configuration for production deployment

**iOS Application (SwiftUI)**
- Native iOS app with modern SwiftUI interface
- Team browsing and detailed schedules
- Live upcoming games display
- AI-powered game predictions with confidence scores
- Vegas odds integration
- Manual prediction for any team matchup
- Season selector (2020-2025)
- Current week status display with auto-refresh
- Custom error handling with "Bull Shark" character
- Production API integration

**Performance Optimizations**
- HTTP caching reduces API calls by 70-90%
- AsyncHTTPClient provides 5-10x faster networking on Linux
- Cache TTL tuning: Odds (6h), Schedules (1h), Live scores (no cache)
- Generic HTTPCache actor for thread-safe caching

### 🚧 In Progress

**Azure Deployment**
- Container Registry: statsharkregistry.azurecr.io (configured)
- App Service: statshark-api.azurewebsites.net (created, B1 Basic tier)
- Managed Identity: Enabled with AcrPull role assigned
- **Blocker**: Docker image rebuilt for linux/amd64 platform required
- Multi-platform build configured for Apple Silicon + Azure compatibility

**Next Steps**
1. Rebuild Docker image for multi-platform (linux/amd64 + linux/arm64)
2. Push to Azure Container Registry
3. Restart App Service to pull updated image
4. Verify production API functionality
5. Update iOS app for App Store submission

See [DEPLOYMENT_STATUS.md](DEPLOYMENT_STATUS.md) for detailed deployment tracking.

## Data architecture

### Structured data foundation

- Historical game results, player statistics, team performance metrics
- Weather conditions, injury reports, betting lines
- Schedule strength, home/away splits, rest days

### Unstructured text sources

- News articles (ESPN, team sites, beat reporters)
- Social media (Twitter/X, Reddit, player accounts)
- Injury reports and press conferences
- Expert analysis and podcasts (transcribed)

### Time-series alignment

- Timestamp all data relative to game kickoff
- Handle recency bias (recent news vs. historical patterns)
- Account for information cascades and rumor correction

## Model strategies

### Option 1: Traditional ML with LLM-extracted features

1. Use foundation models to extract sentiment, injury severity, team morale signals from text
2. Convert to numeric features (sentiment scores, entity mentions, topic distributions)
3. Combine with structured features in gradient boosting models (XGBoost, LightGBM)
4. Train on historical outcomes with proper train/test splits by season

### Option 2: Direct LLM prediction

1. Construct prompts with game context, recent news, and historical data
2. Ask LLM to reason about matchup and provide prediction
3. Calibrate confidence scores against actual outcomes
4. Ensemble multiple LLM calls with different prompts

### Option 3: Hybrid ensemble

- Traditional models for base prediction rates
- LLM-based adjustments for narrative-driven factors (coaching changes, rivalries, momentum)
- Weighted combination based on validation performance

## Critical challenges

### Information quality

- Social media contains noise, jokes, and misinformation
- News articles have bias toward popular teams
- Insider information leaks are rare and hard to verify
- Player statements may be strategic misdirection

### Prediction accuracy ceiling

- NFL has high randomness (any team can win on any given Sunday)
- Vegas lines already incorporate most public information efficiently
- Beating ~52.4% accuracy (break-even against spread) is difficult
- Foundation models lack real-time game state understanding

### Data leakage risks

- Avoid using post-game analysis in training data
- Careful with retroactive injury reports
- Betting line movements may incorporate information you're trying to extract

## Protocol-oriented architecture

Core protocols define the system boundaries:

```swift
protocol NewsDataSource {
    func fetchArticles(for team: Team, before date: Date) async throws -> [Article]
}

protocol SentimentAnalyzer {
    func analyzeSentiment(_ text: String) async throws -> SentimentScore
}

protocol FeatureExtractor {
    func extractFeatures(from articles: [Article]) async throws -> [String: Double]
}

protocol GamePredictor {
    func predict(homeTeam: Team, awayTeam: Team, features: [String: Double]) async throws -> Prediction
}

struct Prediction {
    let homeWinProbability: Double
    let confidence: Double
    let reasoning: String
}
```

## Practical recommendations

### Start simple

1. Establish baseline with structured data only (historical win rates, power ratings)
2. Add one text source at a time and measure marginal improvement
3. Track Brier scores and log-loss for probability calibration
4. Compare against Vegas closing lines as benchmark

### Text processing pipeline

1. Collect news/social media with timestamps
2. Filter for relevance (player mentions, injury keywords, game previews)
3. Run sentiment analysis and named entity recognition
4. Aggregate signals by team and time window
5. Join with structured features

### Model evaluation

- Use walk-forward validation (train on past seasons, test on future)
- Track accuracy, AUC, calibration curves
- Measure edge over betting market consensus
- A/B test different feature combinations

## Realistic expectations

Most sophisticated prediction systems (including professional sports betting operations) achieve:

- ~55-58% accuracy on spread predictions (if profitable)
- Minimal edge that degrades as market adjusts
- Better performance on niche markets (player props, alternate spreads)

Foundation models add value primarily in:

- Rapid information synthesis from multiple sources
- Detecting narrative shifts humans might miss
- Explaining predictions in natural language

They struggle with:

- True causal understanding of game dynamics
- Real-time injury impact assessment
- Distinguishing signal from noise in social media
- Accounting for unmeasurable factors (locker room chemistry, motivation)

## MVP Implementation

The MVP focuses on:

1. Core domain models (Team, Game, Prediction)
2. Protocol definitions for extensibility
3. Baseline predictor using historical data
4. Test suite for validation
5. Foundation for future enhancements

## Development approach

Following test-driven development principles:

- Define protocols first
- Write tests before implementation
- Use value types where appropriate
- Handle errors explicitly
- Document public APIs

## Getting started

### Prerequisites

- Swift 6.1+ (for server development)
- Xcode 16+ (for iOS development)
- Docker Desktop (for containerization)
- Azure CLI (for deployment)

### Server Development

```bash
# Build the project
swift build

# Run tests
swift test --no-parallel

# Run local server
swift run nfl-server serve --hostname 0.0.0.0 --port 8085

# Build Docker image (multi-platform)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t statsharkregistry.azurecr.io/statshark-server:latest \
  --push \
  .
```

### iOS Development

```bash
# Open Xcode project
open /Users/baysideuser/GitRepos/OutcomePredictor/NFLOutcomePredictor/NFLOutcomePredictor.xcodeproj

# Run in simulator (Cmd+R in Xcode)
# Or build from command line
xcodebuild -project NFLOutcomePredictor/NFLOutcomePredictor.xcodeproj \
  -scheme NFLOutcomePredictor \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Environment Variables

Server requires these environment variables:

```bash
export ODDS_API_KEY="your-odds-api-key"          # Required for betting odds
export CLAUDE_API_KEY="your-anthropic-api-key"   # Required for AI predictions
export PORT="8080"                                # Server port (default: 8080)
export ENV="production"                           # Environment mode
```

iOS app uses environment variable for server URL override:

```bash
export SERVER_BASE_URL="http://localhost:8085/api/v1"  # Override production URL
```

## Deployment

### Azure Container Registry + App Service

The project deploys to Azure using:
- **Container Registry**: statsharkregistry.azurecr.io
- **App Service**: statshark-api.azurewebsites.net
- **Authentication**: Managed Identity with AcrPull role

**Multi-Platform Docker Build**

Supports both Apple Silicon development and Azure linux/amd64 deployment:

```bash
# Login to ACR
az acr login --name statsharkregistry

# Build and push multi-platform image
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t statsharkregistry.azurecr.io/statshark-server:latest \
  --push \
  .

# Restart App Service to pull new image
az webapp restart --name statshark-api --resource-group ProDataMan
```

See [AZURE_DEPLOYMENT_STEPS.md](AZURE_DEPLOYMENT_STEPS.md) for detailed deployment instructions.

### iOS App Store

iOS app configured for production API:
- **Production URL**: https://statshark-api.azurewebsites.net/api/v1
- **Bundle ID**: Update in Xcode project settings
- **Team**: Configure in Signing & Capabilities

See [APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md) for submission requirements.

## Architecture

### Server Architecture

```
┌─────────────────┐
│   Vapor REST    │  HTTP Server (Port 8080/8085)
│      API        │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Routes  │  /api/v1/{teams,games,predictions,odds,news}
    └────┬────┘
         │
    ┌────┴──────────┐
    │  Controllers  │  TeamController, GameController, PredictionController
    └───────┬───────┘
            │
    ┌───────┴───────────┐
    │  Data Sources     │  ESPNDataSource, OddsDataSource (with HTTPCache)
    │  + HTTPClient     │  AsyncHTTPClient (Linux optimized)
    └───────┬───────────┘
            │
    ┌───────┴───────┐
    │  External     │  ESPN API, The Odds API, Claude AI
    │     APIs      │
    └───────────────┘
```

### iOS Architecture

```
┌──────────────────┐
│   SwiftUI Views  │  ContentView, PredictionsView, TeamDetailView
└────────┬─────────┘
         │
    ┌────┴─────────┐
    │  ViewModels  │  @StateObject, @Published properties
    └────┬─────────┘
         │
    ┌────┴─────────┐
    │  APIClient   │  URLSession-based HTTP client
    └────┬─────────┘
         │
    ┌────┴──────────┐
    │  Azure API    │  statshark-api.azurewebsites.net
    └───────────────┘
```

### Performance Optimizations

**HTTP Caching with Actor Pattern**
- Generic `HTTPCache<T: Codable & Sendable>` actor
- Thread-safe dictionary storage
- Configurable TTL per data source:
  - Betting odds: 6 hours (500 API calls/month limit)
  - Schedules: 1 hour (changes infrequently)
  - Live scores: No cache (real-time data)

**AsyncHTTPClient Benefits**
- 5-10x faster HTTP on Linux vs URLSession
- Better concurrent request handling
- Native Swift Concurrency integration
- Production-tested by Vapor framework

See [ASYNCHTTPCLIENT_MIGRATION.md](ASYNCHTTPCLIENT_MIGRATION.md) for migration details.

## Documentation

### Quick Start Guides
- [QUICK_START_SERVER.md](QUICK_START_SERVER.md) - Server setup and running
- [QUICK_START_iOS.md](QUICK_START_iOS.md) - iOS app setup

### Development Guides
- [RUNNING.md](RUNNING.md) - Running server and iOS app
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - Test suite documentation
- [DATA_LOADING.md](DATA_LOADING.md) - Data sources and API setup

### Deployment Guides
- [AZURE_DEPLOYMENT_STEPS.md](AZURE_DEPLOYMENT_STEPS.md) - Azure deployment
- [APP_STORE_CHECKLIST.md](APP_STORE_CHECKLIST.md) - App Store submission
- [DEPLOYMENT_STATUS.md](DEPLOYMENT_STATUS.md) - Current deployment status

### Design Documents
- [ASYNCHTTPCLIENT_MIGRATION.md](ASYNCHTTPCLIENT_MIGRATION.md) - HTTP client migration
- [STATSHARK_BRANDING.md](STATSHARK_BRANDING.md) - Brand identity
- [PRIVACY_POLICY_TEMPLATE.md](PRIVACY_POLICY_TEMPLATE.md) - Privacy policy

## API Endpoints

Base URL: `https://statshark-api.azurewebsites.net/api/v1`

### Teams
- `GET /teams` - List all NFL teams
- `GET /teams/{abbreviation}` - Get team details

### Games
- `GET /games?team={abbreviation}&season={year}` - Team schedule
- `GET /upcoming` - Upcoming games across league

### Predictions
- `POST /predictions` - Generate AI prediction for matchup
  ```json
  {
    "home_team_abbreviation": "KC",
    "away_team_abbreviation": "BUF",
    "season": 2024,
    "week": 13
  }
  ```

### Odds
- `GET /odds` - Current betting lines for all games

### News
- `GET /news?team={abbreviation}&limit={count}` - Recent news articles

## Loading Real Data

The system supports multiple data sources for comprehensive predictions. See [DATA_LOADING.md](DATA_LOADING.md) for complete
setup instructions.

### Quick Start

```swift
// ESPN (free, no API key required)
let loader = try DataLoaderBuilder()
    .withESPN()
    .build()

// Load games for a team
let chiefs = NFLTeams.team(abbreviation: "KC")!
let games = try await loader.loadGames(for: chiefs, season: 2024)

// Load complete prediction context
let context = try await loader.loadPredictionContext(for: game, lookbackDays: 7)
```

### Supported Data Sources

**ESPN API** (Free, Public)
- Live scores and game schedules
- Team statistics and final scores
- No API key required

**NewsAPI.org** (Free tier: 100 requests/day)
- 80,000+ news sources
- Article search by team name
- Register at https://newsapi.org/

**Reddit API** (Free with registration)
- Team subreddit posts
- Community discussions and fan sentiment
- Register at https://reddit.com/prefs/apps

**X (Twitter) API v2** (Paid: $100/month)
- Recent tweets and real-time updates
- Beat reporters and verified accounts
- Register at https://developer.x.com/

### Configuration Example

```swift
// Set environment variables
export NEWS_API_KEY="your_key"
export CLAUDE_API_KEY="your_key"

// Build comprehensive loader
let loader = try DataLoaderBuilder()
    .withESPN()
    .withNewsAPI(apiKey: newsKey)
    .withReddit(clientId: id, clientSecret: secret)
    .build()
```

See [DATA_LOADING.md](DATA_LOADING.md) for detailed setup instructions, API costs, and best practices.
