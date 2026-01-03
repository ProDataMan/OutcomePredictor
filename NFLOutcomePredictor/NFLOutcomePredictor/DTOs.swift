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
    public let quarter: String?
    public let timeRemaining: String?

    // Special case CodingKeys: API sends "scheduled_date" but we want property named "date"
    // Also need to list other fields because when you define CodingKeys, you must include all fields
    enum CodingKeys: String, CodingKey {
        case id, week, season, status, quarter, homeTeam, awayTeam, homeScore, awayScore, timeRemaining
        case date = "scheduledDate"  // convertFromSnakeCase gives us scheduledDate
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
        status: String? = nil,
        quarter: String? = nil,
        timeRemaining: String? = nil
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
        self.quarter = quarter
        self.timeRemaining = timeRemaining
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
    public let vegasOdds: VegasOddsDTO?
    public let homeWinProbability: Double?
    public let awayWinProbability: Double?
    public let predictedHomeScore: Int?
    public let predictedAwayScore: Int?
    public let confidenceBreakdown: PredictionConfidenceBreakdown?

    public init(
        predictedWinner: String,
        confidence: Double,
        reasoning: String? = nil,
        modelVersion: String? = nil,
        vegasOdds: VegasOddsDTO? = nil,
        homeWinProbability: Double? = nil,
        awayWinProbability: Double? = nil,
        predictedHomeScore: Int? = nil,
        predictedAwayScore: Int? = nil,
        confidenceBreakdown: PredictionConfidenceBreakdown? = nil
    ) {
        self.predictedWinner = predictedWinner
        self.confidence = confidence
        self.reasoning = reasoning
        self.modelVersion = modelVersion
        self.vegasOdds = vegasOdds
        self.homeWinProbability = homeWinProbability
        self.awayWinProbability = awayWinProbability
        self.predictedHomeScore = predictedHomeScore
        self.predictedAwayScore = predictedAwayScore
        self.confidenceBreakdown = confidenceBreakdown
    }
}

/// Structured confidence breakdown showing prediction factors.
public struct PredictionConfidenceBreakdown: Codable, Sendable {
    public let factors: [ConfidenceFactor]
    public let totalConfidence: Double

    public init(factors: [ConfidenceFactor], totalConfidence: Double) {
        self.factors = factors
        self.totalConfidence = totalConfidence
    }
}

/// Individual prediction confidence factor.
public struct ConfidenceFactor: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let impact: Double  // -1.0 to 1.0 (positive favors predicted winner)
    public let description: String
    public let category: String  // "historical", "injuries", "momentum", "weather", "travel"

    public init(id: String, name: String, impact: Double, description: String, category: String) {
        self.id = id
        self.impact = impact
        self.description = description
        self.category = category
        self.name = name
    }

    public var impactPercentage: Double {
        abs(impact) * 100
    }

    public var favorsWinner: Bool {
        impact > 0
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

/// Player information for mobile app.
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

/// Player statistics for mobile app.
public struct PlayerStatsDTO: Codable, Sendable {
    // Passing stats
    public let passingYards: Int?
    public let passingTouchdowns: Int?
    public let passingInterceptions: Int?
    public let passingCompletions: Int?
    public let passingAttempts: Int?

    // Rushing stats
    public let rushingYards: Int?
    public let rushingTouchdowns: Int?
    public let rushingAttempts: Int?

    // Receiving stats
    public let receivingYards: Int?
    public let receivingTouchdowns: Int?
    public let receptions: Int?
    public let targets: Int?

    // Defensive stats
    public let tackles: Int?
    public let sacks: Double?
    public let interceptions: Int?
    public let forcedFumbles: Int?

    // Kicking stats
    public let fieldGoalsMade: Int?
    public let fieldGoalsAttempted: Int?
    public let extraPointsMade: Int?

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
        interceptions: Int? = nil,
        forcedFumbles: Int? = nil,
        fieldGoalsMade: Int? = nil,
        fieldGoalsAttempted: Int? = nil,
        extraPointsMade: Int? = nil
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
        self.forcedFumbles = forcedFumbles
        self.fieldGoalsMade = fieldGoalsMade
        self.fieldGoalsAttempted = fieldGoalsAttempted
        self.extraPointsMade = extraPointsMade
    }

    public var passingCompletionPercentage: Double? {
        guard let comp = passingCompletions, let att = passingAttempts, att > 0 else { return nil }
        return (Double(comp) / Double(att)) * 100.0
    }

    public var yardsPerCarry: Double? {
        guard let yards = rushingYards, let att = rushingAttempts, att > 0 else { return nil }
        return Double(yards) / Double(att)
    }

    public var fieldGoalPercentage: Double? {
        guard let made = fieldGoalsMade, let attempted = fieldGoalsAttempted, attempted > 0 else { return nil }
        return (Double(made) / Double(attempted)) * 100.0
    }
}

/// Team roster for mobile app.
public struct TeamRosterDTO: Codable, Sendable {
    public let team: TeamDTO
    public let players: [PlayerDTO]
    public let season: Int

    enum CodingKeys: String, CodingKey {
        case team, players, season
    }

    public init(team: TeamDTO, players: [PlayerDTO], season: Int) {
        self.team = team
        self.players = players
        self.season = season
    }

    // Custom decoder to handle missing team field (WAS team issue)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode team, if missing create a placeholder
        if let decodedTeam = try? container.decode(TeamDTO.self, forKey: .team) {
            self.team = decodedTeam
        } else {
            // Create a placeholder team - will be replaced by caller
            self.team = TeamDTO(name: "Unknown", abbreviation: "UNK", conference: "", division: "")
        }

        self.players = try container.decode([PlayerDTO].self, forKey: .players)
        self.season = try container.decode(Int.self, forKey: .season)
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

    public var winPercentage: Double {
        games > 0 ? (Double(wins) / Double(games)) * 100 : 0
    }

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

// MARK: - Player Comparison DTOs

/// Request to compare multiple players.
public struct PlayerComparisonRequest: Codable, Sendable {
    public let playerIds: [String]
    public let season: Int

    public init(playerIds: [String], season: Int) {
        self.playerIds = playerIds
        self.season = season
    }
}

/// Response containing compared players with analysis.
public struct PlayerComparisonResponse: Codable, Sendable {
    public let players: [PlayerDTO]
    public let comparisons: [StatComparison]
    public let season: Int
    public let generatedAt: Date

    public init(
        players: [PlayerDTO],
        comparisons: [StatComparison],
        season: Int,
        generatedAt: Date = Date()
    ) {
        self.players = players
        self.comparisons = comparisons
        self.season = season
        self.generatedAt = generatedAt
    }
}

/// Statistical comparison between players for a specific metric.
public struct StatComparison: Codable, Sendable, Identifiable {
    public let id: String
    public let statName: String
    public let category: StatCategory
    public let values: [PlayerStatValue]
    public let leaderPlayerId: String?

    public init(
        id: String,
        statName: String,
        category: StatCategory,
        values: [PlayerStatValue],
        leaderPlayerId: String? = nil
    ) {
        self.id = id
        self.statName = statName
        self.category = category
        self.values = values
        self.leaderPlayerId = leaderPlayerId
    }
}

/// Individual player's value for a statistic.
public struct PlayerStatValue: Codable, Sendable, Identifiable {
    public let playerId: String
    public let playerName: String
    public let value: Double?
    public let formattedValue: String
    public let percentileRank: Double?

    public var id: String { playerId }

    public init(
        playerId: String,
        playerName: String,
        value: Double?,
        formattedValue: String,
        percentileRank: Double? = nil
    ) {
        self.playerId = playerId
        self.playerName = playerName
        self.value = value
        self.formattedValue = formattedValue
        self.percentileRank = percentileRank
    }
}

/// Category for player statistics.
public enum StatCategory: String, Codable, Sendable {
    case passing = "passing"
    case rushing = "rushing"
    case receiving = "receiving"
    case defense = "defense"
    case kicking = "kicking"
    case general = "general"
}

// MARK: - Injury DTOs

/// Team injury report with list of injured players.
public struct TeamInjuryReportDTO: Codable, Sendable {
    public let team: TeamDTO
    public let injuries: [InjuredPlayerDTO]
    public let fetchedAt: Date

    public init(team: TeamDTO, injuries: [InjuredPlayerDTO], fetchedAt: Date = Date()) {
        self.team = team
        self.injuries = injuries
        self.fetchedAt = fetchedAt
    }

    /// Total injury impact for the team.
    public var totalImpact: Double {
        let sortedImpacts = injuries.map { $0.impact }.sorted(by: >)
        let weights = [1.0, 0.5, 0.25]

        var total = 0.0
        for (index, impact) in sortedImpacts.prefix(3).enumerated() {
            total += impact * weights[index]
        }

        return min(1.0, total)
    }

    /// Get key injuries (high impact players).
    public var keyInjuries: [InjuredPlayerDTO] {
        injuries.filter { injury in
            injury.impact > 0.3 && (injury.status == "OUT" || injury.status == "DOUBTFUL")
        }
    }
}

/// Injured player information.
public struct InjuredPlayerDTO: Codable, Sendable, Identifiable {
    public let name: String
    public let position: String
    public let status: String
    public let description: String?

    public var id: String { name }

    public init(name: String, position: String, status: String, description: String? = nil) {
        self.name = name
        self.position = position
        self.status = status
        self.description = description
    }

    /// Calculate impact on team performance (0.0 to 1.0).
    public var impact: Double {
        let statusMultiplier: Double
        switch status.uppercased() {
        case "OUT":
            statusMultiplier = 1.0
        case "DOUBTFUL":
            statusMultiplier = 0.75
        case "QUESTIONABLE":
            statusMultiplier = 0.4
        case "PROBABLE":
            statusMultiplier = 0.15
        default:
            statusMultiplier = 0.0
        }

        let positionWeight: Double
        switch position.uppercased() {
        case "QB":
            positionWeight = 1.0
        case "RB":
            positionWeight = 0.6
        case "WR":
            positionWeight = 0.5
        case "TE":
            positionWeight = 0.3
        case "DEF", "DEFENSE":
            positionWeight = 0.4
        default:
            positionWeight = 0.1
        }

        return positionWeight * statusMultiplier
    }
}

/// Injury report for both teams in a game.
public struct GameInjuryReportDTO: Codable, Sendable {
    public let homeTeam: TeamInjuryReportDTO
    public let awayTeam: TeamInjuryReportDTO
    public let gameId: String

    public init(homeTeam: TeamInjuryReportDTO, awayTeam: TeamInjuryReportDTO, gameId: String) {
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.gameId = gameId
    }
}

// MARK: - Standings DTOs

/// Team standings information calculated from game results.
public struct TeamStandings: Codable, Sendable, Identifiable {
    public let team: TeamDTO
    public let wins: Int
    public let losses: Int
    public let ties: Int
    public let winPercentage: Double
    public let pointsFor: Int
    public let pointsAgainst: Int
    public let divisionWins: Int
    public let divisionLosses: Int
    public let conferenceWins: Int
    public let conferenceLosses: Int
    public let streak: String  // e.g., "W3" or "L2"

    public var id: String { team.abbreviation }

    public var record: String {
        if ties > 0 {
            return "\(wins)-\(losses)-\(ties)"
        }
        return "\(wins)-\(losses)"
    }

    public init(
        team: TeamDTO,
        wins: Int,
        losses: Int,
        ties: Int,
        winPercentage: Double,
        pointsFor: Int,
        pointsAgainst: Int,
        divisionWins: Int,
        divisionLosses: Int,
        conferenceWins: Int,
        conferenceLosses: Int,
        streak: String
    ) {
        self.team = team
        self.wins = wins
        self.losses = losses
        self.ties = ties
        self.winPercentage = winPercentage
        self.pointsFor = pointsFor
        self.pointsAgainst = pointsAgainst
        self.divisionWins = divisionWins
        self.divisionLosses = divisionLosses
        self.conferenceWins = conferenceWins
        self.conferenceLosses = conferenceLosses
        self.streak = streak
    }
}

/// Division standings grouping teams by division.
public struct DivisionStandings: Codable, Sendable, Identifiable {
    public let conference: String
    public let division: String
    public let teams: [TeamStandings]

    public var id: String { "\(conference)-\(division)" }

    public init(conference: String, division: String, teams: [TeamStandings]) {
        self.conference = conference
        self.division = division
        self.teams = teams
    }
}

/// League-wide standings organized by conference and division.
public struct LeagueStandings: Codable, Sendable {
    public let season: Int
    public let week: Int?
    public let lastUpdated: Date
    public let divisions: [DivisionStandings]

    // Helper computed properties
    public var afcStandings: [DivisionStandings] {
        divisions.filter { $0.conference == "AFC" }
    }

    public var nfcStandings: [DivisionStandings] {
        divisions.filter { $0.conference == "NFC" }
    }

    public init(season: Int, week: Int?, lastUpdated: Date, divisions: [DivisionStandings]) {
        self.season = season
        self.week = week
        self.lastUpdated = lastUpdated
        self.divisions = divisions
    }
}

// MARK: - Team Stats DTOs

/// Comprehensive team statistics for a season.
public struct TeamStatsDTO: Codable, Sendable {
    public let team: TeamDTO
    public let season: Int
    public let offensiveStats: OffensiveStatsDTO
    public let defensiveStats: DefensiveStatsDTO
    public let rankings: TeamRankingsDTO?
    public let recentGames: [GameDTO]
    public let keyPlayers: [PlayerDTO]

    public init(
        team: TeamDTO,
        season: Int,
        offensiveStats: OffensiveStatsDTO,
        defensiveStats: DefensiveStatsDTO,
        rankings: TeamRankingsDTO? = nil,
        recentGames: [GameDTO] = [],
        keyPlayers: [PlayerDTO] = []
    ) {
        self.team = team
        self.season = season
        self.offensiveStats = offensiveStats
        self.defensiveStats = defensiveStats
        self.rankings = rankings
        self.recentGames = recentGames
        self.keyPlayers = keyPlayers
    }
}

/// Offensive statistics for a team.
public struct OffensiveStatsDTO: Codable, Sendable {
    public let pointsPerGame: Double
    public let yardsPerGame: Double
    public let passingYardsPerGame: Double
    public let rushingYardsPerGame: Double
    public let thirdDownConversionRate: Double?
    public let redZoneEfficiency: Double?
    public let turnoversPerGame: Double?

    public init(
        pointsPerGame: Double,
        yardsPerGame: Double,
        passingYardsPerGame: Double,
        rushingYardsPerGame: Double,
        thirdDownConversionRate: Double? = nil,
        redZoneEfficiency: Double? = nil,
        turnoversPerGame: Double? = nil
    ) {
        self.pointsPerGame = pointsPerGame
        self.yardsPerGame = yardsPerGame
        self.passingYardsPerGame = passingYardsPerGame
        self.rushingYardsPerGame = rushingYardsPerGame
        self.thirdDownConversionRate = thirdDownConversionRate
        self.redZoneEfficiency = redZoneEfficiency
        self.turnoversPerGame = turnoversPerGame
    }
}

/// Defensive statistics for a team.
public struct DefensiveStatsDTO: Codable, Sendable {
    public let pointsAllowedPerGame: Double
    public let yardsAllowedPerGame: Double
    public let passingYardsAllowedPerGame: Double
    public let rushingYardsAllowedPerGame: Double
    public let sacksPerGame: Double?
    public let interceptionsPerGame: Double?
    public let forcedFumblesPerGame: Double?

    public init(
        pointsAllowedPerGame: Double,
        yardsAllowedPerGame: Double,
        passingYardsAllowedPerGame: Double,
        rushingYardsAllowedPerGame: Double,
        sacksPerGame: Double? = nil,
        interceptionsPerGame: Double? = nil,
        forcedFumblesPerGame: Double? = nil
    ) {
        self.pointsAllowedPerGame = pointsAllowedPerGame
        self.yardsAllowedPerGame = yardsAllowedPerGame
        self.passingYardsAllowedPerGame = passingYardsAllowedPerGame
        self.rushingYardsAllowedPerGame = rushingYardsAllowedPerGame
        self.sacksPerGame = sacksPerGame
        self.interceptionsPerGame = interceptionsPerGame
        self.forcedFumblesPerGame = forcedFumblesPerGame
    }
}

/// Team rankings in various statistical categories.
public struct TeamRankingsDTO: Codable, Sendable {
    public let offensiveRank: Int?
    public let defensiveRank: Int?
    public let passingOffenseRank: Int?
    public let rushingOffenseRank: Int?
    public let passingDefenseRank: Int?
    public let rushingDefenseRank: Int?
    public let totalRank: Int?

    public init(
        offensiveRank: Int? = nil,
        defensiveRank: Int? = nil,
        passingOffenseRank: Int? = nil,
        rushingOffenseRank: Int? = nil,
        passingDefenseRank: Int? = nil,
        rushingDefenseRank: Int? = nil,
        totalRank: Int? = nil
    ) {
        self.offensiveRank = offensiveRank
        self.defensiveRank = defensiveRank
        self.passingOffenseRank = passingOffenseRank
        self.rushingOffenseRank = rushingOffenseRank
        self.passingDefenseRank = passingDefenseRank
        self.rushingDefenseRank = rushingDefenseRank
        self.totalRank = totalRank
    }
}

// MARK: - Prediction Accuracy DTOs

/// Historical prediction accuracy tracking.
public struct PredictionAccuracyDTO: Codable, Sendable {
    public let overallAccuracy: Double
    public let totalPredictions: Int
    public let correctPredictions: Int
    public let weeklyAccuracy: [WeeklyAccuracyDTO]
    public let confidenceBreakdown: [ConfidenceAccuracyDTO]
    public let modelVersion: String
    public let lastUpdated: Date

    public init(
        overallAccuracy: Double,
        totalPredictions: Int,
        correctPredictions: Int,
        weeklyAccuracy: [WeeklyAccuracyDTO],
        confidenceBreakdown: [ConfidenceAccuracyDTO],
        modelVersion: String,
        lastUpdated: Date = Date()
    ) {
        self.overallAccuracy = overallAccuracy
        self.totalPredictions = totalPredictions
        self.correctPredictions = correctPredictions
        self.weeklyAccuracy = weeklyAccuracy
        self.confidenceBreakdown = confidenceBreakdown
        self.modelVersion = modelVersion
        self.lastUpdated = lastUpdated
    }
}

/// Accuracy statistics for a specific week.
public struct WeeklyAccuracyDTO: Codable, Sendable, Identifiable {
    public let week: Int
    public let season: Int
    public let accuracy: Double
    public let totalGames: Int
    public let correctPredictions: Int

    public var id: String { "\(season)-\(week)" }

    public init(
        week: Int,
        season: Int,
        accuracy: Double,
        totalGames: Int,
        correctPredictions: Int
    ) {
        self.week = week
        self.season = season
        self.accuracy = accuracy
        self.totalGames = totalGames
        self.correctPredictions = correctPredictions
    }
}

/// Accuracy breakdown by confidence level.
public struct ConfidenceAccuracyDTO: Codable, Sendable, Identifiable {
    public let confidenceRange: String
    public let accuracy: Double
    public let totalPredictions: Int
    public let correctPredictions: Int
    public let minConfidence: Double
    public let maxConfidence: Double

    public var id: String { confidenceRange }

    public init(
        confidenceRange: String,
        accuracy: Double,
        totalPredictions: Int,
        correctPredictions: Int,
        minConfidence: Double,
        maxConfidence: Double
    ) {
        self.confidenceRange = confidenceRange
        self.accuracy = accuracy
        self.totalPredictions = totalPredictions
        self.correctPredictions = correctPredictions
        self.minConfidence = minConfidence
        self.maxConfidence = maxConfidence
    }
}

/// Individual prediction result with actual outcome.
public struct PredictionResultDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let gameId: String
    public let homeTeam: TeamDTO
    public let awayTeam: TeamDTO
    public let predictedWinner: String
    public let actualWinner: String?
    public let confidence: Double
    public let week: Int
    public let season: Int
    public let gameDate: Date
    public let correct: Bool?

    public init(
        id: String,
        gameId: String,
        homeTeam: TeamDTO,
        awayTeam: TeamDTO,
        predictedWinner: String,
        actualWinner: String?,
        confidence: Double,
        week: Int,
        season: Int,
        gameDate: Date,
        correct: Bool?
    ) {
        self.id = id
        self.gameId = gameId
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.predictedWinner = predictedWinner
        self.actualWinner = actualWinner
        self.confidence = confidence
        self.week = week
        self.season = season
        self.gameDate = gameDate
        self.correct = correct
    }
}

// MARK: - Model Comparison DTOs

/// Comparison of multiple prediction models for a game.
public struct ModelComparisonDTO: Codable, Sendable {
    public let game: GameDTO
    public let models: [PredictionModelDTO]
    public let consensus: ConsensusDTO?
    public let generatedAt: Date

    public init(
        game: GameDTO,
        models: [PredictionModelDTO],
        consensus: ConsensusDTO? = nil,
        generatedAt: Date = Date()
    ) {
        self.game = game
        self.models = models
        self.consensus = consensus
        self.generatedAt = generatedAt
    }
}

/// Individual prediction model result.
public struct PredictionModelDTO: Codable, Sendable, Identifiable {
    public let id: String
    public let modelName: String
    public let modelVersion: String
    public let predictedWinner: String
    public let confidence: Double
    public let homeWinProbability: Double
    public let awayWinProbability: Double
    public let predictedHomeScore: Int?
    public let predictedAwayScore: Int?
    public let reasoning: String?
    public let accuracy: ModelAccuracyDTO?

    public init(
        id: String,
        modelName: String,
        modelVersion: String,
        predictedWinner: String,
        confidence: Double,
        homeWinProbability: Double,
        awayWinProbability: Double,
        predictedHomeScore: Int? = nil,
        predictedAwayScore: Int? = nil,
        reasoning: String? = nil,
        accuracy: ModelAccuracyDTO? = nil
    ) {
        self.id = id
        self.modelName = modelName
        self.modelVersion = modelVersion
        self.predictedWinner = predictedWinner
        self.confidence = confidence
        self.homeWinProbability = homeWinProbability
        self.awayWinProbability = awayWinProbability
        self.predictedHomeScore = predictedHomeScore
        self.predictedAwayScore = predictedAwayScore
        self.reasoning = reasoning
        self.accuracy = accuracy
    }
}

/// Model accuracy statistics.
public struct ModelAccuracyDTO: Codable, Sendable {
    public let overallAccuracy: Double
    public let recentAccuracy: Double
    public let totalPredictions: Int

    public init(overallAccuracy: Double, recentAccuracy: Double, totalPredictions: Int) {
        self.overallAccuracy = overallAccuracy
        self.recentAccuracy = recentAccuracy
        self.totalPredictions = totalPredictions
    }
}

/// Consensus prediction from all models.
public struct ConsensusDTO: Codable, Sendable {
    public let predictedWinner: String
    public let agreementPercentage: Double
    public let averageConfidence: Double
    public let modelCount: Int

    public init(
        predictedWinner: String,
        agreementPercentage: Double,
        averageConfidence: Double,
        modelCount: Int
    ) {
        self.predictedWinner = predictedWinner
        self.agreementPercentage = agreementPercentage
        self.averageConfidence = averageConfidence
        self.modelCount = modelCount
    }
}


