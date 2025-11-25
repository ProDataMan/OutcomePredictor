import Foundation

/// External data source protocols for fetching NFL information.

/// Fetches NFL game schedules and scores.
public protocol NFLDataSource: Sendable {
    /// Fetches games for a specific week and season.
    ///
    /// - Parameters:
    ///   - week: Week number (1-18 for regular season).
    ///   - season: Season year.
    /// - Returns: Array of games for that week.
    /// - Throws: Network or parsing errors.
    func fetchGames(week: Int, season: Int) async throws -> [Game]

    /// Fetches all games for a specific team in a season.
    ///
    /// - Parameters:
    ///   - team: Team to fetch games for.
    ///   - season: Season year.
    /// - Returns: Array of games.
    /// - Throws: Network or parsing errors.
    func fetchGames(for team: Team, season: Int) async throws -> [Game]

    /// Fetches live scores for games in progress.
    ///
    /// - Returns: Array of games with current scores.
    /// - Throws: Network or parsing errors.
    func fetchLiveScores() async throws -> [Game]
}

/// Fetches social media posts from X/Twitter.
public protocol XDataSource: Sendable {
    /// Fetches recent tweets mentioning a team.
    ///
    /// - Parameters:
    ///   - team: Team to search for.
    ///   - limit: Maximum number of tweets to fetch.
    ///   - before: Fetch tweets before this date.
    /// - Returns: Array of tweets as articles.
    /// - Throws: Network or API errors.
    func fetchTweets(about team: Team, limit: Int, before date: Date) async throws -> [Article]

    /// Fetches tweets from specific accounts (beat reporters, team accounts).
    ///
    /// - Parameters:
    ///   - usernames: X usernames to fetch from.
    ///   - limit: Maximum number of tweets.
    /// - Returns: Array of tweets as articles.
    /// - Throws: Network or API errors.
    func fetchTweets(from usernames: [String], limit: Int) async throws -> [Article]
}

/// Fetches posts from Reddit.
public protocol RedditDataSource: Sendable {
    /// Fetches recent posts from team-specific subreddits.
    ///
    /// - Parameters:
    ///   - team: Team to fetch posts about.
    ///   - limit: Maximum number of posts.
    ///   - before: Fetch posts before this date.
    /// - Returns: Array of Reddit posts as articles.
    /// - Throws: Network or API errors.
    func fetchPosts(about team: Team, limit: Int, before date: Date) async throws -> [Article]

    /// Fetches posts from specific subreddits.
    ///
    /// - Parameters:
    ///   - subreddits: Subreddit names (e.g., "nfl", "eagles").
    ///   - limit: Maximum number of posts.
    /// - Returns: Array of posts as articles.
    /// - Throws: Network or API errors.
    func fetchPosts(from subreddits: [String], limit: Int) async throws -> [Article]
}

/// Aggregates data from multiple sources for a game prediction.
public struct DataAggregator: Sendable {
    private let nflData: NFLDataSource
    private let newsData: NewsDataSource
    private let xData: XDataSource?
    private let redditData: RedditDataSource?

    /// Creates a data aggregator with multiple sources.
    ///
    /// - Parameters:
    ///   - nflData: NFL game data source.
    ///   - newsData: News article source.
    ///   - xData: Optional X/Twitter data source.
    ///   - redditData: Optional Reddit data source.
    public init(
        nflData: NFLDataSource,
        newsData: NewsDataSource,
        xData: XDataSource? = nil,
        redditData: RedditDataSource? = nil
    ) {
        self.nflData = nflData
        self.newsData = newsData
        self.xData = xData
        self.redditData = redditData
    }

    /// Aggregates all available data for a game prediction.
    ///
    /// - Parameters:
    ///   - game: Game to predict.
    ///   - lookbackDays: Number of days to look back for articles (default: 7).
    /// - Returns: Aggregated data context for prediction.
    /// - Throws: Data fetching errors.
    public func aggregateData(for game: Game, lookbackDays: Int = 7) async throws -> PredictionContext {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: game.scheduledDate) ?? game.scheduledDate

        // Fetch historical games
        async let homeGames = nflData.fetchGames(for: game.homeTeam, season: game.season)
        async let awayGames = nflData.fetchGames(for: game.awayTeam, season: game.season)

        // Fetch news articles
        async let homeNews = newsData.fetchArticles(for: game.homeTeam, before: game.scheduledDate)
        async let awayNews = newsData.fetchArticles(for: game.awayTeam, before: game.scheduledDate)

        // Fetch social media (optional)
        let homeTweets = try? await xData?.fetchTweets(about: game.homeTeam, limit: 50, before: game.scheduledDate)
        let awayTweets = try? await xData?.fetchTweets(about: game.awayTeam, limit: 50, before: game.scheduledDate)

        let homeReddit = try? await redditData?.fetchPosts(about: game.homeTeam, limit: 30, before: game.scheduledDate)
        let awayReddit = try? await redditData?.fetchPosts(about: game.awayTeam, limit: 30, before: game.scheduledDate)

        // Combine all data
        let allHomeArticles = try await homeNews + (homeTweets ?? []) + (homeReddit ?? [])
        let allAwayArticles = try await awayNews + (awayTweets ?? []) + (awayReddit ?? [])

        // Filter to lookback window
        let recentHomeArticles = allHomeArticles.filter { $0.publishedDate >= cutoffDate }
        let recentAwayArticles = allAwayArticles.filter { $0.publishedDate >= cutoffDate }

        return PredictionContext(
            game: game,
            homeTeamGames: try await homeGames,
            awayTeamGames: try await awayGames,
            homeTeamArticles: recentHomeArticles,
            awayTeamArticles: recentAwayArticles
        )
    }
}

/// Complete context for making a game prediction.
public struct PredictionContext: Sendable {
    /// Game to predict.
    public let game: Game

    /// Historical games for home team.
    public let homeTeamGames: [Game]

    /// Historical games for away team.
    public let awayTeamGames: [Game]

    /// Recent articles about home team.
    public let homeTeamArticles: [Article]

    /// Recent articles about away team.
    public let awayTeamArticles: [Article]

    /// Total number of data points.
    public var totalDataPoints: Int {
        homeTeamGames.count + awayTeamGames.count + homeTeamArticles.count + awayTeamArticles.count
    }

    /// Creates a prediction context.
    public init(
        game: Game,
        homeTeamGames: [Game],
        awayTeamGames: [Game],
        homeTeamArticles: [Article],
        awayTeamArticles: [Article]
    ) {
        self.game = game
        self.homeTeamGames = homeTeamGames
        self.awayTeamGames = awayTeamGames
        self.homeTeamArticles = homeTeamArticles
        self.awayTeamArticles = awayTeamArticles
    }
}

/// Configuration for data source API keys and endpoints.
public struct DataSourceConfiguration: Sendable {
    /// NFL data API configuration.
    public struct NFLConfig: Sendable {
        public let apiKey: String?
        public let baseURL: String

        public init(apiKey: String? = nil, baseURL: String = "https://api.espn.com/v2/sports/football/nfl") {
            self.apiKey = apiKey
            self.baseURL = baseURL
        }
    }

    /// X/Twitter API configuration.
    public struct XConfig: Sendable {
        public let apiKey: String
        public let apiSecret: String
        public let bearerToken: String

        public init(apiKey: String, apiSecret: String, bearerToken: String) {
            self.apiKey = apiKey
            self.apiSecret = apiSecret
            self.bearerToken = bearerToken
        }
    }

    /// Reddit API configuration.
    public struct RedditConfig: Sendable {
        public let clientId: String
        public let clientSecret: String
        public let userAgent: String

        public init(clientId: String, clientSecret: String, userAgent: String = "OutcomePredictor/1.0") {
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.userAgent = userAgent
        }
    }

    /// News API configuration.
    public struct NewsConfig: Sendable {
        public let apiKey: String?
        public let sources: [String]

        public init(apiKey: String? = nil, sources: [String] = ["espn", "nfl"]) {
            self.apiKey = apiKey
            self.sources = sources
        }
    }

    public let nfl: NFLConfig
    public let x: XConfig?
    public let reddit: RedditConfig?
    public let news: NewsConfig

    /// Creates a data source configuration.
    public init(nfl: NFLConfig, x: XConfig? = nil, reddit: RedditConfig? = nil, news: NewsConfig) {
        self.nfl = nfl
        self.x = x
        self.reddit = reddit
        self.news = news
    }
}
