import Vapor
import Fluent
import FluentSQLiteDriver
import OutcomePredictor
import OutcomePredictorAPI

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = try await Application.make(env)

do {
    try await configure(app)
    try await app.execute()
    try await app.asyncShutdown()
} catch {
    try await app.asyncShutdown()
    throw error
}

func configure(_ app: Application) async throws {
    // Enable static file serving from Public directory
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Configure database
    let databasePath = Environment.get("DATABASE_PATH") ?? "db.sqlite"
    app.databases.use(.sqlite(.file(databasePath)), as: .sqlite)

    // Add migrations
    app.migrations.add(CreateFeedback())

    // Run migrations automatically
    try await app.autoMigrate()

    // Configure JSON encoder/decoder
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.keyEncodingStrategy = .convertToSnakeCase

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Setup data loader with API keys from environment
    let newsAPIKey = Environment.get("NEWS_API_KEY") ?? "168084c7268f48b48f2e4eec0ddca9cd"

    let dataLoader = try DataLoaderBuilder()
        .withESPN()
        .withNewsAPI(apiKey: newsAPIKey)
        .build()

    // Store data loader in app storage for route access
    app.storage[DataLoaderKey.self] = dataLoader

    // Setup Odds API data source with cache
    // Uses API key from environment variable or defaults to the one in OddsDataSource.swift
    let oddsAPIKey = Environment.get("ODDS_API_KEY")
    let oddsDataSource = TheOddsAPIDataSource(apiKey: oddsAPIKey ?? "329088a703ba82a2103e7e7c6508500f")
    app.storage[OddsDataSourceKey.self] = oddsDataSource

    // Create odds cache (6 hour expiration)
    let oddsCache = OddsCache()
    app.storage[OddsCacheKey.self] = oddsCache

    // Setup API-Sports data source with caching (15 minute TTL)
    // Get API key from environment or use a default for testing
    let apiSportsKey = Environment.get("API_SPORTS_KEY")
    if let apiKey = apiSportsKey {
        let apiSportsDataSource = APISportsDataSource(apiKey: apiKey, cacheTTL: 900) // 15 minutes
        app.storage[APISportsDataSourceKey.self] = apiSportsDataSource
        print("✅ API-Sports data source initialized with 15-minute caching")
    } else {
        print("⚠️ API-Sports API key not found in environment (API_SPORTS_KEY)")
        print("   Player stats will use ESPN data (sample stats only)")
    }

    // Register routes
    try routes(app)
}

// Storage key for DataLoader
struct DataLoaderKey: StorageKey {
    typealias Value = DataLoader
}

// Storage key for Odds API DataSource
struct OddsDataSourceKey: StorageKey {
    typealias Value = TheOddsAPIDataSource
}

// Storage key for Odds Cache
struct OddsCacheKey: StorageKey {
    typealias Value = OddsCache
}

// Storage key for API-Sports DataSource
struct APISportsDataSourceKey: StorageKey {
    typealias Value = APISportsDataSource
}

func routes(_ app: Application) throws {
    // Health check
    app.get("health") { req async -> String in
        return "OK"
    }

    // Static website routes
    app.get { req async throws -> Response in
        try await req.fileio.asyncStreamFile(at: "\(app.directory.publicDirectory)index.html")
    }

    app.get("privacy") { req async throws -> Response in
        try await req.fileio.asyncStreamFile(at: "\(app.directory.publicDirectory)privacy.html")
    }

    app.get("support") { req async throws -> Response in
        try await req.fileio.asyncStreamFile(at: "\(app.directory.publicDirectory)support.html")
    }

    // API v1 routes
    let api = app.grouped("api", "v1")

    // GET /api/v1/teams - List all teams
    api.get("teams") { req async throws -> [TeamDTO] in
        let teams = NFLTeams.allTeams.map { TeamDTO(from: $0) }
        return teams
    }

    // GET /api/v1/games?team=KC&season=2024 - Get games for a team
    api.get("games") { req async throws -> [GameDTO] in
        guard let teamAbbr = req.query[String.self, at: "team"],
              let season = req.query[Int.self, at: "season"] else {
            throw Abort(.badRequest, reason: "Missing required parameters: team and season")
        }

        guard let team = NFLTeams.team(abbreviation: teamAbbr) else {
            throw Abort(.notFound, reason: "Team not found: \(teamAbbr)")
        }

        guard let loader = req.application.storage[DataLoaderKey.self] else {
            throw Abort(.internalServerError, reason: "Data loader not initialized")
        }

        let games = try await loader.loadGames(for: team, season: season)
        let gameDTOs = games.map { GameDTO(from: $0) }

        return gameDTOs
    }

    // GET /api/v1/upcoming - Get upcoming games
    api.get("upcoming") { req async throws -> [GameDTO] in
        guard let loader = req.application.storage[DataLoaderKey.self] else {
            throw Abort(.internalServerError, reason: "Data loader not initialized")
        }

        let games = try await loader.loadLiveScores()

        // Filter for upcoming games (not completed) - manual filter to avoid Swift 6 Predicate issue
        let now = Date()
        var upcomingGames: [Game] = []
        for game in games {
            if game.scheduledDate > now || game.outcome == nil {
                upcomingGames.append(game)
            }
        }

        // Sort by scheduled date
        let sortedGames = upcomingGames.sorted { $0.scheduledDate < $1.scheduledDate }
        let gameDTOs = sortedGames.map { GameDTO(from: $0) }

        return gameDTOs
    }

    // GET /api/v1/news?team=KC&limit=10 - Get news for a team
    api.get("news") { req async throws -> [ArticleDTO] in
        guard let teamAbbr = req.query[String.self, at: "team"] else {
            throw Abort(.badRequest, reason: "Missing required parameter: team")
        }

        let limit = req.query[Int.self, at: "limit"] ?? 10

        guard let team = NFLTeams.team(abbreviation: teamAbbr) else {
            throw Abort(.notFound, reason: "Team not found: \(teamAbbr)")
        }

        guard let loader = req.application.storage[DataLoaderKey.self] else {
            throw Abort(.internalServerError, reason: "Data loader not initialized")
        }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let articles = try await loader.loadArticles(
            for: team,
            before: Date(),
            after: sevenDaysAgo
        )

        let articleDTOs = Array(articles.prefix(limit)).map { ArticleDTO(from: $0) }

        return articleDTOs
    }

    // GET /api/v1/teams/{teamId}/roster - Get team roster with player stats
    api.get("teams", ":teamId", "roster") { req async throws -> TeamRosterDTO in
        guard let teamAbbr = req.parameters.get("teamId") else {
            throw Abort(.badRequest, reason: "Missing team ID")
        }

        let season = req.query[Int.self, at: "season"] ?? Calendar.current.component(.year, from: Date())

        guard let team = NFLTeams.team(abbreviation: teamAbbr) else {
            throw Abort(.notFound, reason: "Team not found: \(teamAbbr)")
        }

        // Try API-Sports first (real stats and headshots from 2022+)
        if let apiSportsDataSource = req.application.storage[APISportsDataSourceKey.self],
           season >= 2022 {
            do {
                print("🏈 Fetching roster from API-Sports for \(teamAbbr) (season \(season))")
                let roster = try await apiSportsDataSource.fetchRoster(for: team, season: season)
                print("✅ Successfully fetched \(roster.players.count) players from API-Sports")
                return TeamRosterDTO(from: roster)
            } catch {
                print("⚠️ API-Sports failed for \(teamAbbr): \(error.localizedDescription)")
                print("   Falling back to ESPN data source")
                // Fall through to ESPN fallback
            }
        }

        // Fallback to ESPN (sample stats, but still has headshots for most players)
        print("📡 Using ESPN data source for \(teamAbbr) (season \(season))")
        let espnPlayerDataSource = ESPNPlayerDataSource()
        let roster = try await espnPlayerDataSource.fetchRoster(for: team, season: season)

        return TeamRosterDTO(from: roster)
    }

    // POST /api/v1/predictions - Make a prediction
    api.post("predictions") { req async throws -> PredictionDTO in
        let predictionReq = try req.content.decode(PredictionRequest.self)

        guard let homeTeam = NFLTeams.team(abbreviation: predictionReq.homeTeamAbbreviation) else {
            throw Abort(.notFound, reason: "Home team not found: \(predictionReq.homeTeamAbbreviation)")
        }

        guard let awayTeam = NFLTeams.team(abbreviation: predictionReq.awayTeamAbbreviation) else {
            throw Abort(.notFound, reason: "Away team not found: \(predictionReq.awayTeamAbbreviation)")
        }

        guard let loader = req.application.storage[DataLoaderKey.self] else {
            throw Abort(.internalServerError, reason: "Data loader not initialized")
        }

        // Load historical games for both teams
        let homeGames = try await loader.loadGames(for: homeTeam, season: predictionReq.season)
        let awayGames = try await loader.loadGames(for: awayTeam, season: predictionReq.season)

        var allGames = homeGames + awayGames

        // Remove duplicates
        var seenIds = Set<UUID>()
        allGames = allGames.filter { game in
            let isNew = !seenIds.contains(game.id)
            seenIds.insert(game.id)
            return isNew
        }

        let gameRepo = InMemoryGameRepository(games: allGames)

        // Setup enhanced predictor with injury tracking and news analysis
        let injuryDataSource = ESPNInjuryDataSource()
        let injuryTracker = InjuryTracker(dataSource: injuryDataSource)

        guard let dataLoader = req.application.storage[DataLoaderKey.self] else {
            throw Abort(.internalServerError, reason: "Data loader not initialized")
        }

        let newsDataSource = RealNewsDataSource(dataLoader: dataLoader)
        let newsAnalyzer = NewsAnalyzer(newsDataSource: newsDataSource)

        let predictor = EnhancedPredictor(
            gameRepository: gameRepo,
            injuryTracker: injuryTracker,
            newsAnalyzer: newsAnalyzer
        )

        // Create game to predict
        let scheduledDate = predictionReq.scheduledDate ?? Date().addingTimeInterval(86400 * 7)
        let week = predictionReq.week ?? 13

        let game = Game(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            scheduledDate: scheduledDate,
            week: week,
            season: predictionReq.season
        )

        let prediction = try await predictor.predict(game: game, features: [:])

        // Extract city for location
        let cityMap: [String: String] = [
            "SF": "San Francisco",
            "TB": "Tampa Bay",
            "LAR": "Los Angeles",
            "LAC": "Los Angeles",
            "NYG": "New York",
            "NYJ": "New York",
            "NE": "New England",
            "GB": "Green Bay",
            "KC": "Kansas City",
            "NO": "New Orleans"
        ]

        let location = cityMap[homeTeam.abbreviation] ??
                      homeTeam.name.components(separatedBy: " ").dropLast().joined(separator: " ")

        // Fetch real Vegas odds from The Odds API with caching
        var vegasOdds: VegasOddsDTO?
        if let oddsDataSource = req.application.storage[OddsDataSourceKey.self],
           let oddsCache = req.application.storage[OddsCacheKey.self] {
            do {
                // Try cache first
                var oddsMap = await oddsCache.getOdds()

                if oddsMap == nil {
                    // Cache miss or expired - fetch from API
                    req.logger.info("Odds cache miss - fetching from API")
                    oddsMap = try await oddsDataSource.fetchNFLOdds()
                    await oddsCache.setOdds(oddsMap!)
                    req.logger.info("Odds cached successfully")
                } else {
                    req.logger.info("Odds cache hit - using cached data")
                }

                // Try to match odds by team names
                let awayName = awayTeam.name
                let homeName = homeTeam.name
                let key = "\(awayName) @ \(homeName)"

                if let bettingOdds = oddsMap?[key] {
                    vegasOdds = VegasOddsDTO(
                        homeMoneyline: bettingOdds.homeMoneyline,
                        awayMoneyline: bettingOdds.awayMoneyline,
                        spread: bettingOdds.spread,
                        total: bettingOdds.total,
                        homeImpliedProbability: bettingOdds.homeMoneyline.map { BettingOdds.oddsToProbability($0) },
                        awayImpliedProbability: bettingOdds.awayMoneyline.map { BettingOdds.oddsToProbability($0) },
                        bookmaker: bettingOdds.bookmaker
                    )
                }
            } catch {
                // Log error but continue with prediction (odds are optional)
                req.logger.warning("Failed to fetch Vegas odds: \(error)")
            }
        }

        // Fall back to mock data if no real odds available
        if vegasOdds == nil {
            vegasOdds = VegasOddsDTO(
                homeMoneyline: -155,
                awayMoneyline: +135,
                spread: -3.5,
                total: 47.5,
                homeImpliedProbability: BettingOdds.oddsToProbability(-155),
                awayImpliedProbability: BettingOdds.oddsToProbability(+135),
                bookmaker: "Mock (Demo)"
            )
        }

        let predictionDTO = PredictionDTO(
            from: prediction,
            location: location,
            vegasOdds: vegasOdds
        )

        return predictionDTO
    }

    // GET /api/v1/cache/stats - Get cache statistics (for monitoring)
    api.get("cache", "stats") { req async throws -> CacheStatsResponse in
        var apiSportsStats: APISportsCacheStats?

        // API-Sports cache stats
        if let apiSportsDataSource = req.application.storage[APISportsDataSourceKey.self] {
            let cacheStats = await apiSportsDataSource.getCacheStats()
            apiSportsStats = APISportsCacheStats(
                rosterCacheCount: cacheStats.count,
                oldestEntry: cacheStats.oldestEntry?.ISO8601Format(),
                newestEntry: cacheStats.newestEntry?.ISO8601Format(),
                ttlMinutes: 15
            )
        }

        // Odds cache stats
        var oddsCacheHasData = false
        if let oddsCache = req.application.storage[OddsCacheKey.self] {
            oddsCacheHasData = await oddsCache.getOdds() != nil
        }

        return CacheStatsResponse(
            apiSports: apiSportsStats,
            oddsCache: OddsCacheStats(hasData: oddsCacheHasData, ttlHours: 6),
            timestamp: Date().ISO8601Format()
        )
    }

    // POST /api/v1/cache/clear - Clear API-Sports cache (admin endpoint)
    api.post("cache", "clear") { req async throws -> MessageResponse in
        if let apiSportsDataSource = req.application.storage[APISportsDataSourceKey.self] {
            await apiSportsDataSource.clearCaches()
            return MessageResponse(message: "API-Sports caches cleared successfully")
        }
        throw Abort(.notFound, reason: "API-Sports data source not configured")
    }

    // POST /api/v1/cache/cleanup - Clean up expired cache entries
    api.post("cache", "cleanup") { req async throws -> MessageResponse in
        if let apiSportsDataSource = req.application.storage[APISportsDataSourceKey.self] {
            await apiSportsDataSource.cleanupExpiredCache()
            return MessageResponse(message: "Expired cache entries cleaned up")
        }
        throw Abort(.notFound, reason: "API-Sports data source not configured")
    }

    // MARK: - Feedback Routes

    // POST /api/v1/feedback - Submit user feedback
    api.post("feedback") { req async throws -> FeedbackDTO in
        let submission = try req.content.decode(FeedbackSubmissionDTO.self)

        let feedback = Feedback(
            userId: submission.userId,
            page: submission.page,
            platform: submission.platform,
            feedbackText: submission.feedbackText,
            appVersion: submission.appVersion,
            deviceModel: submission.deviceModel,
            isRead: false
        )

        try await feedback.save(on: req.db)

        // Send push notification to admin (placeholder - to be implemented)
        Task {
            await sendAdminNotification(feedback: feedback)
        }

        return FeedbackDTO(
            id: feedback.id!.uuidString,
            userId: feedback.userId,
            page: feedback.page,
            platform: feedback.platform,
            feedbackText: feedback.feedbackText,
            appVersion: feedback.appVersion,
            deviceModel: feedback.deviceModel,
            createdAt: feedback.createdAt!,
            isRead: feedback.isRead
        )
    }

    // GET /api/v1/feedback - Get all feedback (admin only)
    api.get("feedback") { req async throws -> [FeedbackDTO] in
        // Simple admin check - in production, use proper authentication
        let adminUserId = Environment.get("ADMIN_USER_ID") ?? "admin"
        let requestUserId = req.query[String.self, at: "userId"]

        guard requestUserId == adminUserId else {
            throw Abort(.unauthorized, reason: "Admin access required")
        }

        let feedbacks = try await Feedback.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()

        return feedbacks.map { feedback in
            FeedbackDTO(
                id: feedback.id!.uuidString,
                userId: feedback.userId,
                page: feedback.page,
                platform: feedback.platform,
                feedbackText: feedback.feedbackText,
                appVersion: feedback.appVersion,
                deviceModel: feedback.deviceModel,
                createdAt: feedback.createdAt!,
                isRead: feedback.isRead
            )
        }
    }

    // GET /api/v1/feedback/unread - Get unread feedback count (admin only)
    api.get("feedback", "unread") { req async throws -> UnreadCountResponse in
        let adminUserId = Environment.get("ADMIN_USER_ID") ?? "admin"
        let requestUserId = req.query[String.self, at: "userId"]

        guard requestUserId == adminUserId else {
            throw Abort(.unauthorized, reason: "Admin access required")
        }

        let count = try await Feedback.query(on: req.db)
            .filter(\.$isRead == false)
            .count()

        return UnreadCountResponse(unreadCount: count)
    }

    // POST /api/v1/feedback/mark-read - Mark feedback as read
    api.post("feedback", "mark-read") { req async throws -> MessageResponse in
        let markRead = try req.content.decode(MarkFeedbackReadDTO.self)

        let feedbackIds = markRead.feedbackIds.compactMap { UUID(uuidString: $0) }

        try await Feedback.query(on: req.db)
            .filter(\.$id ~~ feedbackIds)
            .set(\.$isRead, to: true)
            .update()

        return MessageResponse(message: "Marked \(feedbackIds.count) feedback items as read")
    }

    // Catch-all route for 404 errors (must be last)
    app.get("**") { req async throws -> Response in
        try await req.fileio.asyncStreamFile(at: "\(req.application.directory.publicDirectory)404.html")
    }
}

// MARK: - Helper Functions

/// Send push notification to admin when feedback is received
func sendAdminNotification(feedback: Feedback) async {
    // TODO: Implement push notification using FCM or APNS
    // For now, just log
    print("📬 New feedback received from \(feedback.userId) on \(feedback.platform)")
    print("   Page: \(feedback.page)")
    print("   Feedback: \(feedback.feedbackText)")
}

// MARK: - Response Models

struct UnreadCountResponse: Content {
    let unreadCount: Int
}

struct CacheStatsResponse: Content {
    let apiSports: APISportsCacheStats?
    let oddsCache: OddsCacheStats
    let timestamp: String
}

struct APISportsCacheStats: Content {
    let rosterCacheCount: Int
    let oldestEntry: String?
    let newestEntry: String?
    let ttlMinutes: Int
}

struct OddsCacheStats: Content {
    let hasData: Bool
    let ttlHours: Int
}

struct MessageResponse: Content {
    let message: String
}

