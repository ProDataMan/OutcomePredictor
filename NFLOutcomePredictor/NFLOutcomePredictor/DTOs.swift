import Foundation

/// Data Transfer Objects for the OutcomePredictor API.
/// These models are shared between the server and iOS client.

// MARK: - Team DTO

/// Simplified team representation for API responses.
public struct TeamDTO: Codable, Sendable {
    public let abbreviation: String
    public let name: String
    public let conference: String
    public let division: String

    public init(abbreviation: String, name: String, conference: String, division: String) {
        self.abbreviation = abbreviation
        self.name = name
        self.conference = conference
        self.division = division
    }
}

// MARK: - Game DTO

/// Game information for API responses.
public struct GameDTO: Codable, Sendable {
    public let id: String
    public let homeTeam: TeamDTO
    public let awayTeam: TeamDTO
    public let scheduledDate: Date
    public let week: Int
    public let season: Int
    public let homeScore: Int?
    public let awayScore: Int?
    public let winner: String? // "home", "away", or "tie"

    public init(
        id: String,
        homeTeam: TeamDTO,
        awayTeam: TeamDTO,
        scheduledDate: Date,
        week: Int,
        season: Int,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        winner: String? = nil
    ) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.scheduledDate = scheduledDate
        self.week = week
        self.season = season
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.winner = winner
    }
}

// MARK: - Article DTO

/// News article for API responses.
public struct ArticleDTO: Codable, Sendable {
    public let title: String
    public let content: String
    public let source: String
    public let publishedDate: Date
    public let teamAbbreviations: [String]
    public let url: String?

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

// MARK: - Prediction DTO

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
