# OutcomePredictor

Predicting NFL game outcomes using foundation models and text data involves several interconnected challenges. This
project implements a structured approach to game prediction combining traditional statistics with natural language
processing.

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

```bash
# Build the project
swift build

# Run tests
swift test --no-parallel

# Run CLI demo
.build/debug/nfl-predict --demo

# Load real data (see DATA_LOADING.md for setup)
swift run DataLoadingExample
```

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
