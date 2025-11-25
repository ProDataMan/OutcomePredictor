import Foundation

/// Actor-based cache for storing fetched data and minimizing API calls.
public actor DataCache {
    private var gameCache: [String: CachedGames] = [:]
    private var articleCache: [String: CachedArticles] = [:]
    private let cacheExpiration: TimeInterval

    private struct CachedGames {
        let games: [Game]
        let timestamp: Date
    }

    private struct CachedArticles {
        let articles: [Article]
        let timestamp: Date
    }

    /// Creates a data cache.
    ///
    /// - Parameter cacheExpiration: Time in seconds before cached data expires (default: 3600 = 1 hour).
    public init(cacheExpiration: TimeInterval = 3600) {
        self.cacheExpiration = cacheExpiration
    }

    /// Caches games for a specific key.
    ///
    /// - Parameters:
    ///   - games: Games to cache.
    ///   - key: Cache key.
    public func cacheGames(_ games: [Game], forKey key: String) {
        gameCache[key] = CachedGames(games: games, timestamp: Date())
    }

    /// Retrieves cached games if available and not expired.
    ///
    /// - Parameter key: Cache key.
    /// - Returns: Cached games if valid, nil otherwise.
    public func getCachedGames(forKey key: String) -> [Game]? {
        guard let cached = gameCache[key] else { return nil }

        let age = Date().timeIntervalSince(cached.timestamp)
        guard age < cacheExpiration else {
            gameCache.removeValue(forKey: key)
            return nil
        }

        return cached.games
    }

    /// Caches articles for a specific key.
    ///
    /// - Parameters:
    ///   - articles: Articles to cache.
    ///   - key: Cache key.
    public func cacheArticles(_ articles: [Article], forKey key: String) {
        articleCache[key] = CachedArticles(articles: articles, timestamp: Date())
    }

    /// Retrieves cached articles if available and not expired.
    ///
    /// - Parameter key: Cache key.
    /// - Returns: Cached articles if valid, nil otherwise.
    public func getCachedArticles(forKey key: String) -> [Article]? {
        guard let cached = articleCache[key] else { return nil }

        let age = Date().timeIntervalSince(cached.timestamp)
        guard age < cacheExpiration else {
            articleCache.removeValue(forKey: key)
            return nil
        }

        return cached.articles
    }

    /// Clears all cached data.
    public func clearCache() {
        gameCache.removeAll()
        articleCache.removeAll()
    }

    /// Clears expired cache entries.
    public func clearExpiredCache() {
        let now = Date()

        gameCache = gameCache.filter { _, cached in
            now.timeIntervalSince(cached.timestamp) < cacheExpiration
        }

        articleCache = articleCache.filter { _, cached in
            now.timeIntervalSince(cached.timestamp) < cacheExpiration
        }
    }
}

/// Data loader that orchestrates fetching data from multiple sources with caching.
public actor DataLoader {
    private let nflSource: NFLDataSource
    private let newsSource: NewsDataSource?
    private let xSource: XDataSource?
    private let redditSource: RedditDataSource?
    private let cache: DataCache

    /// Creates a data loader.
    ///
    /// - Parameters:
    ///   - nflSource: NFL game data source.
    ///   - newsSource: Optional news data source.
    ///   - xSource: Optional X/Twitter data source.
    ///   - redditSource: Optional Reddit data source.
    ///   - cache: Data cache instance.
    public init(
        nflSource: NFLDataSource,
        newsSource: NewsDataSource? = nil,
        xSource: XDataSource? = nil,
        redditSource: RedditDataSource? = nil,
        cache: DataCache = DataCache()
    ) {
        self.nflSource = nflSource
        self.newsSource = newsSource
        self.xSource = xSource
        self.redditSource = redditSource
        self.cache = cache
    }

    /// Loads complete prediction context for a game with caching.
    ///
    /// - Parameters:
    ///   - game: Game to load data for.
    ///   - lookbackDays: Number of days to look back for articles.
    ///   - forceRefresh: Skip cache and fetch fresh data.
    /// - Returns: Complete prediction context.
    public func loadPredictionContext(
        for game: Game,
        lookbackDays: Int = 7,
        forceRefresh: Bool = false
    ) async throws -> PredictionContext {
        // Fetch historical games (with caching)
        let homeGames = try await loadGames(for: game.homeTeam, season: game.season, forceRefresh: forceRefresh)
        let awayGames = try await loadGames(for: game.awayTeam, season: game.season, forceRefresh: forceRefresh)

        // Fetch news and social media (with caching)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: game.scheduledDate) ?? game.scheduledDate

        let homeArticles = try await loadArticles(
            for: game.homeTeam,
            before: game.scheduledDate,
            after: cutoffDate,
            forceRefresh: forceRefresh
        )

        let awayArticles = try await loadArticles(
            for: game.awayTeam,
            before: game.scheduledDate,
            after: cutoffDate,
            forceRefresh: forceRefresh
        )

        return PredictionContext(
            game: game,
            homeTeamGames: homeGames,
            awayTeamGames: awayGames,
            homeTeamArticles: homeArticles,
            awayTeamArticles: awayArticles
        )
    }

    /// Loads games for a team with caching.
    ///
    /// - Parameters:
    ///   - team: Team to load games for.
    ///   - season: Season year.
    ///   - forceRefresh: Skip cache and fetch fresh data.
    /// - Returns: Array of games.
    public func loadGames(for team: Team, season: Int, forceRefresh: Bool = false) async throws -> [Game] {
        let cacheKey = "games_\(team.abbreviation)_\(season)"

        if !forceRefresh, let cached = await cache.getCachedGames(forKey: cacheKey) {
            return cached
        }

        let games = try await nflSource.fetchGames(for: team, season: season)
        await cache.cacheGames(games, forKey: cacheKey)

        return games
    }

    /// Loads articles about a team with caching.
    ///
    /// - Parameters:
    ///   - team: Team to load articles about.
    ///   - before: Fetch articles before this date.
    ///   - after: Fetch articles after this date (for cache key).
    ///   - forceRefresh: Skip cache and fetch fresh data.
    /// - Returns: Array of articles.
    public func loadArticles(
        for team: Team,
        before: Date,
        after: Date,
        forceRefresh: Bool = false
    ) async throws -> [Article] {
        let dateFormatter = ISO8601DateFormatter()
        let cacheKey = "articles_\(team.abbreviation)_\(dateFormatter.string(from: before))"

        if !forceRefresh, let cached = await cache.getCachedArticles(forKey: cacheKey) {
            return cached
        }

        var allArticles: [Article] = []

        // Fetch from news source
        if let newsSource = newsSource {
            do {
                let news = try await newsSource.fetchArticles(for: team, before: before)
                allArticles.append(contentsOf: news)
            } catch {
                print("Warning: News fetch failed: \(error)")
            }
        }

        // Fetch from X/Twitter
        if let xSource = xSource {
            do {
                let tweets = try await xSource.fetchTweets(about: team, limit: 50, before: before)
                allArticles.append(contentsOf: tweets)
            } catch {
                print("Warning: X fetch failed: \(error)")
            }
        }

        // Fetch from Reddit
        if let redditSource = redditSource {
            do {
                let posts = try await redditSource.fetchPosts(about: team, limit: 30, before: before)
                allArticles.append(contentsOf: posts)
            } catch {
                print("Warning: Reddit fetch failed: \(error)")
            }
        }

        // Filter by date range and cache
        let filteredArticles = allArticles.filter { $0.publishedDate >= after && $0.publishedDate < before }
        await cache.cacheArticles(filteredArticles, forKey: cacheKey)

        return filteredArticles
    }

    /// Loads live scores for all ongoing games.
    ///
    /// - Returns: Array of games with current scores.
    public func loadLiveScores() async throws -> [Game] {
        // Live scores shouldn't be cached
        return try await nflSource.fetchLiveScores()
    }

    /// Clears all cached data.
    public func clearCache() async {
        await cache.clearCache()
    }

    /// Clears expired cache entries to free memory.
    public func cleanupCache() async {
        await cache.clearExpiredCache()
    }
}

/// Configuration builder for setting up data sources.
public struct DataLoaderBuilder {
    private var nflSource: NFLDataSource?
    private var newsSource: NewsDataSource?
    private var xSource: XDataSource?
    private var redditSource: RedditDataSource?

    /// Creates a data loader builder.
    public init() {}

    /// Configures ESPN as the NFL data source.
    ///
    /// - Returns: Self for chaining.
    public func withESPN() -> DataLoaderBuilder {
        var builder = self
        builder.nflSource = ESPNDataSource()
        return builder
    }

    /// Configures mock NFL data source for testing.
    ///
    /// - Parameter games: Pre-populated games.
    /// - Returns: Self for chaining.
    public func withMockNFL(games: [Game] = []) -> DataLoaderBuilder {
        var builder = self
        builder.nflSource = MockNFLDataSource(games: games)
        return builder
    }

    /// Configures NewsAPI as the news source.
    ///
    /// - Parameter apiKey: NewsAPI.org API key.
    /// - Returns: Self for chaining.
    public func withNewsAPI(apiKey: String) -> DataLoaderBuilder {
        var builder = self
        builder.newsSource = NewsAPIDataSource(apiKey: apiKey)
        return builder
    }

    /// Configures X (Twitter) as a data source.
    ///
    /// - Parameter bearerToken: X API v2 bearer token.
    /// - Returns: Self for chaining.
    public func withX(bearerToken: String) -> DataLoaderBuilder {
        var builder = self
        builder.xSource = XAPIDataSource(bearerToken: bearerToken)
        return builder
    }

    /// Configures Reddit as a data source.
    ///
    /// - Parameters:
    ///   - clientId: Reddit app client ID.
    ///   - clientSecret: Reddit app secret.
    ///   - userAgent: User agent string.
    /// - Returns: Self for chaining.
    public func withReddit(clientId: String, clientSecret: String, userAgent: String = "OutcomePredictor/1.0") -> DataLoaderBuilder {
        var builder = self
        builder.redditSource = RedditAPIDataSource(
            clientId: clientId,
            clientSecret: clientSecret,
            userAgent: userAgent
        )
        return builder
    }

    /// Builds the data loader.
    ///
    /// - Returns: Configured data loader.
    /// - Throws: Error if NFL source is not configured.
    public func build() throws -> DataLoader {
        guard let nflSource = nflSource else {
            throw ConfigurationError.missingRequiredSource("NFL data source is required")
        }

        return DataLoader(
            nflSource: nflSource,
            newsSource: newsSource,
            xSource: xSource,
            redditSource: redditSource
        )
    }
}

/// Configuration errors.
public enum ConfigurationError: Error, LocalizedError {
    case missingRequiredSource(String)
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .missingRequiredSource(let message):
            return "Missing required source: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}
