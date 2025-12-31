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

// MARK: - Player DTOs

/// Player information for API responses.
public struct PlayerDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let position: String
    public let jerseyNumber: String?
    public let photoURL: String?
    public let stats: PlayerStatsDTO?
    public let height: String?
    public let weight: Int?
    public let age: Int?
    public let college: String?
    public let experience: Int?

    public init(
        id: String,
        name: String,
        position: String,
        jerseyNumber: String? = nil,
        photoURL: String? = nil,
        stats: PlayerStatsDTO? = nil,
        height: String? = nil,
        weight: Int? = nil,
        age: Int? = nil,
        college: String? = nil,
        experience: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.position = position
        self.jerseyNumber = jerseyNumber
        self.photoURL = photoURL
        self.stats = stats
        self.height = height
        self.weight = weight
        self.age = age
        self.college = college
        self.experience = experience
    }
}

/// Player statistics for API responses.
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
}

/// Team roster for API responses.
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

// MARK: - Weather DTOs

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

/// Team weather performance statistics.
public struct TeamWeatherStatsDTO: Codable, Sendable {
    public let teamAbbreviation: String
    public let season: Int
    public let homeStats: WeatherPerformanceDTO
    public let awayStats: WeatherPerformanceDTO

    public init(
        teamAbbreviation: String,
        season: Int,
        homeStats: WeatherPerformanceDTO,
        awayStats: WeatherPerformanceDTO
    ) {
        self.teamAbbreviation = teamAbbreviation
        self.season = season
        self.homeStats = homeStats
        self.awayStats = awayStats
    }
}

/// Performance in different weather conditions.
public struct WeatherPerformanceDTO: Codable, Sendable {
    public let clear: ConditionStatsDTO
    public let rain: ConditionStatsDTO
    public let snow: ConditionStatsDTO
    public let wind: ConditionStatsDTO
    public let cold: ConditionStatsDTO
    public let hot: ConditionStatsDTO

    public init(
        clear: ConditionStatsDTO,
        rain: ConditionStatsDTO,
        snow: ConditionStatsDTO,
        wind: ConditionStatsDTO,
        cold: ConditionStatsDTO,
        hot: ConditionStatsDTO
    ) {
        self.clear = clear
        self.rain = rain
        self.snow = snow
        self.wind = wind
        self.cold = cold
        self.hot = hot
    }
}

/// Statistics for a weather condition.
public struct ConditionStatsDTO: Codable, Sendable {
    public let games: Int
    public let wins: Int
    public let losses: Int
    public let avgPointsScored: Double
    public let avgPointsAllowed: Double

    public init(
        games: Int,
        wins: Int,
        losses: Int,
        avgPointsScored: Double,
        avgPointsAllowed: Double
    ) {
        self.games = games
        self.wins = wins
        self.losses = losses
        self.avgPointsScored = avgPointsScored
        self.avgPointsAllowed = avgPointsAllowed
    }
}

// MARK: - Feedback DTOs

/// Request to submit user feedback.
public struct FeedbackSubmissionDTO: Codable, Sendable {
    public let userId: String
    public let page: String
    public let platform: String
    public let feedbackText: String
    public let appVersion: String?
    public let deviceModel: String?

    public init(
        userId: String,
        page: String,
        platform: String,
        feedbackText: String,
        appVersion: String? = nil,
        deviceModel: String? = nil
    ) {
        self.userId = userId
        self.page = page
        self.platform = platform
        self.feedbackText = feedbackText
        self.appVersion = appVersion
        self.deviceModel = deviceModel
    }
}

/// Feedback item returned from the API.
public struct FeedbackDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let userId: String
    public let page: String
    public let platform: String
    public let feedbackText: String
    public let appVersion: String?
    public let deviceModel: String?
    public let createdAt: Date
    public let isRead: Bool

    public init(
        id: String,
        userId: String,
        page: String,
        platform: String,
        feedbackText: String,
        appVersion: String? = nil,
        deviceModel: String? = nil,
        createdAt: Date,
        isRead: Bool
    ) {
        self.id = id
        self.userId = userId
        self.page = page
        self.platform = platform
        self.feedbackText = feedbackText
        self.appVersion = appVersion
        self.deviceModel = deviceModel
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

/// Request to mark feedback as read.
public struct MarkFeedbackReadDTO: Codable, Sendable {
    public let feedbackIds: [String]

    public init(feedbackIds: [String]) {
        self.feedbackIds = feedbackIds
    }
}
