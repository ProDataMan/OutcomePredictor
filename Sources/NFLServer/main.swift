import Vapor
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

func routes(_ app: Application) throws {
    // Health check
    app.get("health") { req async -> String in
        return "OK"
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
        let predictor = BaselinePredictor(gameRepository: gameRepo)

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
}
