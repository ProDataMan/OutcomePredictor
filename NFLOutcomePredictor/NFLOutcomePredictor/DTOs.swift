import Foundation

/// Data Transfer Objects for the OutcomePredictor API.
/// These models are shared between the server and iOS client.

// MARK: - Team DTO

/// Simplified team representation for API responses.
public struct TeamDTO: Codable, Sendable, Identifiable {
    public let name: String
    public let abbreviation: String
    public let conference: String
    public let division: String

    // Use abbreviation as unique identifier for SwiftUI
    public var id: String { abbreviation }

    public init(
        name: String,
        abbreviation: String,
        conference: String,
        division: String
    ) {
        self.name = name
        self.abbreviation = abbreviation
        self.conference = conference
        self.division = division
    }
}

/// Detailed team information including record and next game.
public struct TeamDetail: Codable, Sendable, Identifiable {
    public let name: String
    public let abbreviation: String
    public let conference: String
    public let division: String
    public let record: TeamRecord?
    public let nextGame: Game?

    // Use abbreviation as unique identifier for SwiftUI
    public var id: String { abbreviation }

    public init(
        name: String,
        abbreviation: String,
        conference: String,
        division: String,
        record: TeamRecord? = nil,
        nextGame: Game? = nil
    ) {
        self.name = name
        self.abbreviation = abbreviation
        self.conference = conference
        self.division = division
        self.record = record
        self.nextGame = nextGame
    }
}

/// Team win-loss record.
public struct TeamRecord: Codable, Sendable {
    public let wins: Int?
    public let losses: Int?
    public let ties: Int?
    public let winPercentage: Double?

    public init(wins: Int? = nil, losses: Int? = nil, ties: Int? = nil, winPercentage: Double? = nil) {
        self.wins = wins
        self.losses = losses
        self.ties = ties
        self.winPercentage = winPercentage
    }
}

// MARK: - Game DTO

/// Game information for API responses.
public struct GameDTO: Codable, Sendable {
    public let id: String
    public let homeTeam: TeamDTO
    public let awayTeam: TeamDTO
    public let date: Date
    public let week: Int?
    public let season: Int?
    public let homeScore: Int?
    public let awayScore: Int?
    public let status: String?

    // Custom mapping for scheduled_date -> date
    enum CodingKeys: String, CodingKey {
        case id, homeTeam, awayTeam, week, season, homeScore, awayScore, status
        case date = "scheduledDate"  // Maps to scheduled_date via snake_case conversion
    }

    public init(
        id: String,
        homeTeam: TeamDTO,
        awayTeam: TeamDTO,
        date: Date,
        week: Int? = nil,
        season: Int? = nil,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        status: String? = nil
    ) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.date = date
        self.week = week
        self.season = season
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.status = status
    }
}

/// Game with prediction information.
public struct GamePrediction: Codable, Sendable {
    public let game: GameDTO
    public let prediction: PredictionResult?
    public let odds: GameOdds?

    public init(game: GameDTO, prediction: PredictionResult? = nil, odds: GameOdds? = nil) {
        self.game = game
        self.prediction = prediction
        self.odds = odds
    }
}

/// Basic game information (alias for compatibility).
public typealias Game = GameDTO

// MARK: - Article DTO

/// News article for API responses.
public struct ArticleDTO: Codable, Sendable, Identifiable {
    public let title: String
    public let content: String
    public let source: String
    public let publishedDate: Date
    public let teamAbbreviations: [String]
    public let url: String?

    // Use title + publishedDate as unique identifier
    public var id: String {
        "\(title)-\(publishedDate.timeIntervalSince1970)"
    }

    public init(
        title: String,
        content: String,
        source: String,
        publishedDate: Date,
        teamAbbreviations: [String],
        url: String? = nil
    ) {
        self.title = title
        self.content = content
        self.source = source
        self.publishedDate = publishedDate
        self.teamAbbreviations = teamAbbreviations
        self.url = url
    }
}

// MARK: - Prediction DTOs

/// Prediction result for API responses.
public struct PredictionResult: Codable, Sendable {
    public let predictedWinner: String
    public let confidence: Double
    public let reasoning: String?
    public let modelVersion: String?

    public init(
        predictedWinner: String,
        confidence: Double,
        reasoning: String? = nil,
        modelVersion: String? = nil
    ) {
        self.predictedWinner = predictedWinner
        self.confidence = confidence
        self.reasoning = reasoning
        self.modelVersion = modelVersion
    }
}

/// Game odds information.
public struct GameOdds: Codable, Sendable {
    public let homeTeamOdds: Double?
    public let awayTeamOdds: Double?
    public let spread: Double?
    public let overUnder: Double?
    public let lastUpdated: Date?

    public init(
        homeTeamOdds: Double? = nil,
        awayTeamOdds: Double? = nil,
        spread: Double? = nil,
        overUnder: Double? = nil,
        lastUpdated: Date? = nil
    ) {
        self.homeTeamOdds = homeTeamOdds
        self.awayTeamOdds = awayTeamOdds
        self.spread = spread
        self.overUnder = overUnder
        self.lastUpdated = lastUpdated
    }
}

/// Current week response with games and metadata.
public struct CurrentWeekResponse: Codable, Sendable {
    public let week: Int
    public let season: Int
    public let games: [GamePrediction]
    public let lastUpdated: Date?

    public init(week: Int, season: Int, games: [GamePrediction], lastUpdated: Date? = nil) {
        self.week = week
        self.season = season
        self.games = games
        self.lastUpdated = lastUpdated
    }
}

/// Prediction result for API responses.
public struct PredictionDTO: Codable, Sendable {
    public let gameId: String
    public let homeTeam: TeamDTO
    public let awayTeam: TeamDTO
    public let scheduledDate: Date
    public let location: String
    public let week: Int
    public let season: Int
    public let homeWinProbability: Double
    public let awayWinProbability: Double
    public let confidence: Double
    public let predictedHomeScore: Int?
    public let predictedAwayScore: Int?
    public let reasoning: String
    public let vegasOdds: VegasOddsDTO?

    // Note: APIClient uses .convertFromSnakeCase for automatic mapping

    public init(
        gameId: String,
        homeTeam: TeamDTO,
        awayTeam: TeamDTO,
        scheduledDate: Date,
        location: String,
        week: Int,
        season: Int,
        homeWinProbability: Double,
        awayWinProbability: Double,
        confidence: Double,
        predictedHomeScore: Int? = nil,
        predictedAwayScore: Int? = nil,
        reasoning: String,
        vegasOdds: VegasOddsDTO? = nil
    ) {
        self.gameId = gameId
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.scheduledDate = scheduledDate
        self.location = location
        self.week = week
        self.season = season
        self.homeWinProbability = homeWinProbability
        self.awayWinProbability = awayWinProbability
        self.confidence = confidence
        self.predictedHomeScore = predictedHomeScore
        self.predictedAwayScore = predictedAwayScore
        self.reasoning = reasoning
        self.vegasOdds = vegasOdds
    }
}

// MARK: - Vegas Odds DTO

/// Vegas betting odds for API responses.
public struct VegasOddsDTO: Codable, Sendable {
    public let homeMoneyline: Int?
    public let awayMoneyline: Int?
    public let spread: Double?
    public let total: Double?
    public let homeImpliedProbability: Double?
    public let awayImpliedProbability: Double?
    public let bookmaker: String

    // Note: APIClient uses .convertFromSnakeCase for automatic mapping

    public init(
        homeMoneyline: Int?,
        awayMoneyline: Int?,
        spread: Double?,
        total: Double?,
        homeImpliedProbability: Double?,
        awayImpliedProbability: Double?,
        bookmaker: String
    ) {
        self.homeMoneyline = homeMoneyline
        self.awayMoneyline = awayMoneyline
        self.spread = spread
        self.total = total
        self.homeImpliedProbability = homeImpliedProbability
        self.awayImpliedProbability = awayImpliedProbability
        self.bookmaker = bookmaker
    }
}

// MARK: - Response Containers

/// Standard API response wrapper.
public struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    public let data: T
    public let timestamp: Date
    public let cached: Bool

    public init(data: T, timestamp: Date = Date(), cached: Bool = false) {
        self.data = data
        self.timestamp = timestamp
        self.cached = cached
    }
}

/// Error response from API.
public struct ErrorResponse: Codable, Error, Sendable {
    public let error: String
    public let message: String
    public let timestamp: Date

    public init(error: String, message: String, timestamp: Date = Date()) {
        self.error = error
        self.message = message
        self.timestamp = timestamp
    }
}

// MARK: - Request Parameters

/// Parameters for fetching team games.
public struct GamesRequest: Codable, Sendable {
    public let teamAbbreviation: String
    public let season: Int

    public init(teamAbbreviation: String, season: Int) {
        self.teamAbbreviation = teamAbbreviation
        self.season = season
    }
}

/// Parameters for fetching news.
public struct NewsRequest: Codable, Sendable {
    public let teamAbbreviation: String
    public let limit: Int?

    public init(teamAbbreviation: String, limit: Int? = 10) {
        self.teamAbbreviation = teamAbbreviation
        self.limit = limit
    }
}

/// Parameters for making a prediction.
public struct PredictionRequest: Codable, Sendable {
    public let homeTeamAbbreviation: String
    public let awayTeamAbbreviation: String
    public let scheduledDate: Date?
    public let week: Int?
    public let season: Int

    public init(
        homeTeamAbbreviation: String,
        awayTeamAbbreviation: String,
        scheduledDate: Date? = nil,
        week: Int? = nil,
        season: Int
    ) {
        self.homeTeamAbbreviation = homeTeamAbbreviation
        self.awayTeamAbbreviation = awayTeamAbbreviation
        self.scheduledDate = scheduledDate
        self.week = week
        self.season = season
    }
}

// MARK: - Player DTOs

/// Player information for mobile app.
public struct PlayerDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let position: String
    public let jerseyNumber: String?
    public let photoURL: String?
    public let stats: PlayerStatsDTO?

    public init(
        id: String,
        name: String,
        position: String,
        jerseyNumber: String? = nil,
        photoURL: String? = nil,
        stats: PlayerStatsDTO? = nil
    ) {
        self.id = id
        self.name = name
        self.position = position
        self.jerseyNumber = jerseyNumber
        self.photoURL = photoURL
        self.stats = stats
    }
}

/// Player statistics for mobile app.
public struct PlayerStatsDTO: Codable, Sendable {
    public let passingYards: Int?
    public let passingTouchdowns: Int?
    public let passingInterceptions: Int?
    public let passingCompletions: Int?
    public let passingAttempts: Int?
    public let rushingYards: Int?
    public let rushingTouchdowns: Int?
    public let rushingAttempts: Int?
    public let receivingYards: Int?
    public let receivingTouchdowns: Int?
    public let receptions: Int?
    public let targets: Int?
    public let tackles: Int?
    public let sacks: Double?
    public let interceptions: Int?

    public init(
        passingYards: Int? = nil,
        passingTouchdowns: Int? = nil,
        passingInterceptions: Int? = nil,
        passingCompletions: Int? = nil,
        passingAttempts: Int? = nil,
        rushingYards: Int? = nil,
        rushingTouchdowns: Int? = nil,
        rushingAttempts: Int? = nil,
        receivingYards: Int? = nil,
        receivingTouchdowns: Int? = nil,
        receptions: Int? = nil,
        targets: Int? = nil,
        tackles: Int? = nil,
        sacks: Double? = nil,
        interceptions: Int? = nil
    ) {
        self.passingYards = passingYards
        self.passingTouchdowns = passingTouchdowns
        self.passingInterceptions = passingInterceptions
        self.passingCompletions = passingCompletions
        self.passingAttempts = passingAttempts
        self.rushingYards = rushingYards
        self.rushingTouchdowns = rushingTouchdowns
        self.rushingAttempts = rushingAttempts
        self.receivingYards = receivingYards
        self.receivingTouchdowns = receivingTouchdowns
        self.receptions = receptions
        self.targets = targets
        self.tackles = tackles
        self.sacks = sacks
        self.interceptions = interceptions
    }

    public var passingCompletionPercentage: Double? {
        guard let comp = passingCompletions, let att = passingAttempts, att > 0 else { return nil }
        return (Double(comp) / Double(att)) * 100.0
    }

    public var yardsPerCarry: Double? {
        guard let yards = rushingYards, let att = rushingAttempts, att > 0 else { return nil }
        return Double(yards) / Double(att)
    }
}

/// Team roster for mobile app.
public struct TeamRosterDTO: Codable, Sendable {
    public let team: TeamDTO
    public let players: [PlayerDTO]
    public let season: Int

    public init(team: TeamDTO, players: [PlayerDTO], season: Int) {
        self.team = team
        self.players = players
        self.season = season
    }
}

// MARK: - Weather DTO

/// Weather forecast for a game.
public struct GameWeatherDTO: Codable, Sendable {
    public let temperature: Double
    public let condition: String
    public let windSpeed: Double
    public let precipitation: Double
    public let humidity: Double
    public let timestamp: Date

    public init(
        temperature: Double,
        condition: String,
        windSpeed: Double,
        precipitation: Double,
        humidity: Double,
        timestamp: Date = Date()
    ) {
        self.temperature = temperature
        self.condition = condition
        self.windSpeed = windSpeed
        self.precipitation = precipitation
        self.humidity = humidity
        self.timestamp = timestamp
    }
}
