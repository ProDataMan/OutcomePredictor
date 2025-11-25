# Data Loading Guide

This guide explains how to load real NFL data, news articles, and social media posts for making predictions.

## Quick Start

### 1. Basic Setup (No API Keys Required)

Use ESPN's public API for NFL game data:

```swift
import OutcomePredictor

// Create data loader with ESPN
let loader = try DataLoaderBuilder()
    .withESPN()
    .build()

// Load games for a team
let chiefs = NFLTeams.team(abbreviation: "KC")!
let games = try await loader.loadGames(for: chiefs, season: 2024)

print("Loaded \(games.count) games for \(chiefs.name)")
```

### 2. Loading Complete Prediction Context

```swift
// Create upcoming game
let game = Game(
    homeTeam: NFLTeams.team(abbreviation: "SF")!,
    awayTeam: NFLTeams.team(abbreviation: "KC")!,
    scheduledDate: Date().addingTimeInterval(86400 * 3), // 3 days from now
    week: 11,
    season: 2024
)

// Load all available data
let context = try await loader.loadPredictionContext(for: game, lookbackDays: 7)

print("Historical games: \(context.homeTeamGames.count + context.awayTeamGames.count)")
print("Articles found: \(context.homeTeamArticles.count + context.awayTeamArticles.count)")
```

### 3. Making Predictions with Loaded Data

```swift
// Create predictor with loaded data
let gameRepo = InMemoryGameRepository(games: context.homeTeamGames + context.awayTeamGames)
let baseline = BaselinePredictor(gameRepository: gameRepo)

// Or use LLM with full context
let llmClient = ClaudeAPIClient(apiKey: "your-api-key")
let llmPredictor = LLMPredictor(llmClient: llmClient)
let prediction = try await llmPredictor.predict(context: context)

print("Prediction: \(prediction.homeWinProbability * 100)% home win")
```

## API Configuration

### ESPN (Free, No Key Required)

ESPN provides publicly accessible sports data. No registration required.

```swift
let loader = try DataLoaderBuilder()
    .withESPN()
    .build()
```

**Features:**
- Live scores
- Game schedules
- Team statistics
- Final scores

**Limitations:**
- No detailed player stats
- Limited historical data
- Rate limiting applies

### NewsAPI.org (Free Tier: 100 requests/day)

Get API key at: https://newsapi.org/

```swift
let loader = try DataLoaderBuilder()
    .withESPN()
    .withNewsAPI(apiKey: "YOUR_NEWSAPI_KEY")
    .build()
```

**Setup:**
1. Visit https://newsapi.org/
2. Sign up for free account
3. Copy API key from dashboard
4. Free tier: 100 requests/day, 1 month history

**Features:**
- 80,000+ news sources
- Article search by team name
- Publication date filtering
- English language content

### Reddit API (Free with Registration)

Register app at: https://www.reddit.com/prefs/apps

```swift
let loader = try DataLoaderBuilder()
    .withESPN()
    .withReddit(
        clientId: "YOUR_CLIENT_ID",
        clientSecret: "YOUR_CLIENT_SECRET",
        userAgent: "OutcomePredictor/1.0"
    )
    .build()
```

**Setup:**
1. Visit https://www.reddit.com/prefs/apps
2. Click "create application"
3. Select "script" application type
4. Note client ID and secret

**Features:**
- Team subreddit posts
- r/nfl community discussions
- Fan sentiment analysis
- Real-time reactions

**Rate Limits:**
- 60 requests per minute
- OAuth required for higher limits

### X (Twitter) API v2 (Paid: $100/month minimum)

Get access at: https://developer.x.com/

```swift
let loader = try DataLoaderBuilder()
    .withESPN()
    .withX(bearerToken: "YOUR_BEARER_TOKEN")
    .build()
```

**Setup:**
1. Visit https://developer.x.com/
2. Sign up for Basic tier ($100/month)
3. Create project and app
4. Generate bearer token

**Features:**
- Recent tweets search
- User timeline access
- Real-time updates
- Verified accounts

**Limitations:**
- Basic tier: 10,000 tweets/month
- Pro tier ($5,000/month) for higher limits
- No free tier available

### Complete Configuration Example

```swift
// Load environment variables or secure configuration
struct APIKeys {
    static let newsAPI = ProcessInfo.processInfo.environment["NEWS_API_KEY"] ?? ""
    static let xBearer = ProcessInfo.processInfo.environment["X_BEARER_TOKEN"] ?? ""
    static let redditClientId = ProcessInfo.processInfo.environment["REDDIT_CLIENT_ID"] ?? ""
    static let redditSecret = ProcessInfo.processInfo.environment["REDDIT_SECRET"] ?? ""
    static let claudeAPI = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? ""
}

// Build comprehensive data loader
let loader = try DataLoaderBuilder()
    .withESPN()
    .withNewsAPI(apiKey: APIKeys.newsAPI)
    .withReddit(
        clientId: APIKeys.redditClientId,
        clientSecret: APIKeys.redditSecret
    )
    .withX(bearerToken: APIKeys.xBearer) // Optional, expensive
    .build()
```

## Caching Strategy

The data loader automatically caches responses to minimize API calls:

```swift
// First call - fetches from API
let games1 = try await loader.loadGames(for: team, season: 2024)

// Second call - returns cached data (within 1 hour)
let games2 = try await loader.loadGames(for: team, season: 2024)

// Force refresh
let games3 = try await loader.loadGames(for: team, season: 2024, forceRefresh: true)

// Clear cache manually
await loader.clearCache()

// Clean up expired entries only
await loader.cleanupCache()
```

**Cache Duration:** 1 hour (3600 seconds) by default

**Cached Data:**
- Team game schedules
- News articles
- Social media posts

**Not Cached:**
- Live scores (always fresh)

## Error Handling

```swift
do {
    let context = try await loader.loadPredictionContext(for: game)
    // Use context for prediction
} catch DataSourceError.rateLimitExceeded {
    print("Rate limit exceeded. Wait before retrying.")
} catch DataSourceError.authenticationFailed {
    print("Check your API keys.")
} catch DataSourceError.httpError(let code) {
    print("HTTP error: \(code)")
} catch {
    print("Unexpected error: \(error)")
}
```

**Common Errors:**
- `rateLimitExceeded`: Wait and retry with exponential backoff
- `authenticationFailed`: Verify API keys
- `httpError(429)`: Rate limit hit
- `httpError(401)`: Invalid API key
- `httpError(500)`: Service temporarily unavailable

## Environment Variables Setup

### macOS/Linux

```bash
# Create .env file in project root
export NEWS_API_KEY="your_newsapi_key_here"
export REDDIT_CLIENT_ID="your_reddit_client_id"
export REDDIT_SECRET="your_reddit_secret"
export X_BEARER_TOKEN="your_x_bearer_token"
export CLAUDE_API_KEY="your_claude_api_key"

# Load environment
source .env

# Run your app
swift run nfl-predict --demo
```

### Xcode Configuration

1. Edit scheme (Product → Scheme → Edit Scheme)
2. Select "Run" → "Arguments"
3. Add environment variables:
   - `NEWS_API_KEY`: your_key_here
   - `REDDIT_CLIENT_ID`: your_id_here
   - etc.

## Cost Estimation

**Free Tier (Recommended for Development):**
- ESPN: Free, unlimited
- NewsAPI: Free, 100 requests/day
- Reddit: Free, 60 requests/minute
- **Monthly Cost: $0**

**With LLM Predictions:**
- Claude API: ~$15-30/month for moderate usage
- **Monthly Cost: $15-30**

**With Social Media (Full Featured):**
- X API Basic: $100/month
- NewsAPI Professional: $449/month (optional)
- **Monthly Cost: $115-579**

## Best Practices

1. **Start with Free Tier**: Use ESPN + Reddit for initial development
2. **Add News When Ready**: NewsAPI provides good value at 100 requests/day
3. **Skip X Initially**: Very expensive, limited value for prediction accuracy
4. **Cache Aggressively**: Minimize API calls with smart caching
5. **Handle Failures Gracefully**: Don't fail predictions if one source is down
6. **Monitor Usage**: Track API call counts to avoid surprise charges
7. **Use Mock Sources**: Test with mock data before burning API credits

## Production Deployment

```swift
// Production configuration with fallbacks
let loader: DataLoader

#if DEBUG
// Use mock data in development
loader = try DataLoaderBuilder()
    .withMockNFL(games: SampleDataGenerator.generateSeason())
    .build()
#else
// Use real data in production
loader = try DataLoaderBuilder()
    .withESPN()
    .withNewsAPI(apiKey: APIKeys.newsAPI)
    .withReddit(
        clientId: APIKeys.redditClientId,
        clientSecret: APIKeys.redditSecret
    )
    .build()
#endif
```

## Next Steps

1. Register for free APIs (NewsAPI, Reddit)
2. Test data loading with real APIs
3. Implement prediction pipeline with loaded data
4. Add persistence layer for historical tracking
5. Build evaluation framework to measure accuracy
