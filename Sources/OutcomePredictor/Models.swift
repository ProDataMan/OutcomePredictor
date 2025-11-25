import Foundation

/// Represents an NFL team with basic identifying information.
public struct Team: Identifiable, Codable, Hashable, Sendable {
    /// Unique identifier for the team.
    public let id: UUID

    /// Team name (e.g., "San Francisco 49ers").
    public let name: String

    /// Team abbreviation (e.g., "SF").
    public let abbreviation: String

    /// Conference affiliation (NFC or AFC).
    public let conference: Conference

    /// Division affiliation.
    public let division: Division

    /// Creates a new team instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to new UUID.
    ///   - name: Full team name.
    ///   - abbreviation: Team abbreviation code.
    ///   - conference: NFC or AFC.
    ///   - division: Division within conference.
    public init(
        id: UUID = UUID(),
        name: String,
        abbreviation: String,
        conference: Conference,
        division: Division
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.conference = conference
        self.division = division
    }
}

/// NFL conference affiliation.
public enum Conference: String, Codable, Sendable {
    case nfc = "NFC"
    case afc = "AFC"
}

/// NFL division within a conference.
public enum Division: String, Codable, Sendable {
    case north = "North"
    case south = "South"
    case east = "East"
    case west = "West"
}

/// Represents a scheduled or completed NFL game.
public struct Game: Identifiable, Codable, Sendable {
    /// Unique identifier for the game.
    public let id: UUID

    /// Home team.
    public let homeTeam: Team

    /// Away team.
    public let awayTeam: Team

    /// Scheduled kickoff time.
    public let scheduledDate: Date

    /// Game week number in the season.
    public let week: Int

    /// Season year.
    public let season: Int

    /// Actual game outcome if completed.
    public let outcome: GameOutcome?

    /// Creates a new game instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to new UUID.
    ///   - homeTeam: Team playing at home.
    ///   - awayTeam: Team playing away.
    ///   - scheduledDate: Kickoff date and time.
    ///   - week: Week number in season.
    ///   - season: Year of the season.
    ///   - outcome: Actual result if game is completed.
    public init(
        id: UUID = UUID(),
        homeTeam: Team,
        awayTeam: Team,
        scheduledDate: Date,
        week: Int,
        season: Int,
        outcome: GameOutcome? = nil
    ) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.scheduledDate = scheduledDate
        self.week = week
        self.season = season
        self.outcome = outcome
    }
}

/// Actual outcome of a completed game.
public struct GameOutcome: Codable, Sendable {
    /// Home team final score.
    public let homeScore: Int

    /// Away team final score.
    public let awayScore: Int

    /// Winner of the game.
    public var winner: Winner {
        if homeScore > awayScore {
            return .home
        } else if awayScore > homeScore {
            return .away
        } else {
            return .tie
        }
    }

    /// Point differential (home team perspective).
    public var pointDifferential: Int {
        homeScore - awayScore
    }

    /// Creates a new game outcome.
    ///
    /// - Parameters:
    ///   - homeScore: Home team final score.
    ///   - awayScore: Away team final score.
    public init(homeScore: Int, awayScore: Int) {
        self.homeScore = homeScore
        self.awayScore = awayScore
    }
}

/// Game winner.
public enum Winner: String, Codable, Sendable {
    case home
    case away
    case tie
}

/// Prediction for a game outcome.
public struct Prediction: Codable, Sendable {
    /// Game being predicted.
    public let game: Game

    /// Probability of home team winning (0.0 to 1.0).
    public let homeWinProbability: Double

    /// Confidence in the prediction (0.0 to 1.0).
    public let confidence: Double

    /// Human-readable reasoning for the prediction.
    public let reasoning: String

    /// Timestamp when prediction was made.
    public let timestamp: Date

    /// Predicted winner based on probability.
    public var predictedWinner: Winner {
        if homeWinProbability > 0.5 {
            return .home
        } else if homeWinProbability < 0.5 {
            return .away
        } else {
            return .tie
        }
    }

    /// Away team win probability.
    public var awayWinProbability: Double {
        1.0 - homeWinProbability
    }

    /// Creates a new prediction.
    ///
    /// - Parameters:
    ///   - game: Game to predict.
    ///   - homeWinProbability: Probability home team wins (0.0-1.0).
    ///   - confidence: Confidence level (0.0-1.0).
    ///   - reasoning: Explanation of the prediction.
    ///   - timestamp: When prediction was made. Defaults to current time.
    /// - Throws: `PredictionError.invalidProbability` if probability is out of range.
    public init(
        game: Game,
        homeWinProbability: Double,
        confidence: Double,
        reasoning: String,
        timestamp: Date = Date()
    ) throws {
        guard (0.0...1.0).contains(homeWinProbability) else {
            throw PredictionError.invalidProbability(homeWinProbability)
        }
        guard (0.0...1.0).contains(confidence) else {
            throw PredictionError.invalidConfidence(confidence)
        }

        self.game = game
        self.homeWinProbability = homeWinProbability
        self.confidence = confidence
        self.reasoning = reasoning
        self.timestamp = timestamp
    }
}

/// Errors that can occur during prediction.
public enum PredictionError: Error, LocalizedError {
    case invalidProbability(Double)
    case invalidConfidence(Double)
    case insufficientData
    case modelNotTrained

    public var errorDescription: String? {
        switch self {
        case .invalidProbability(let value):
            return "Invalid probability: \(value). Must be between 0.0 and 1.0"
        case .invalidConfidence(let value):
            return "Invalid confidence: \(value). Must be between 0.0 and 1.0"
        case .insufficientData:
            return "Insufficient data to make prediction"
        case .modelNotTrained:
            return "Prediction model has not been trained"
        }
    }
}

/// Sentiment score extracted from text.
public struct SentimentScore: Codable, Sendable {
    /// Overall sentiment (-1.0 to 1.0, where -1 is negative and 1 is positive).
    public let score: Double

    /// Confidence in the sentiment analysis (0.0 to 1.0).
    public let confidence: Double

    /// Creates a new sentiment score.
    ///
    /// - Parameters:
    ///   - score: Sentiment value (-1.0 to 1.0).
    ///   - confidence: Confidence level (0.0 to 1.0).
    public init(score: Double, confidence: Double) {
        self.score = score
        self.confidence = confidence
    }
}

/// News article or social media post.
public struct Article: Identifiable, Codable, Sendable {
    /// Unique identifier.
    public let id: UUID

    /// Article title or post headline.
    public let title: String

    /// Full text content.
    public let content: String

    /// Publication or posting date.
    public let publishedDate: Date

    /// Source (e.g., "ESPN", "Twitter").
    public let source: String

    /// Teams mentioned in the article.
    public let teams: [Team]

    /// Creates a new article.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to new UUID.
    ///   - title: Article headline.
    ///   - content: Full text.
    ///   - publishedDate: Publication date.
    ///   - source: Source name.
    ///   - teams: Teams mentioned.
    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        publishedDate: Date,
        source: String,
        teams: [Team]
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.publishedDate = publishedDate
        self.source = source
        self.teams = teams
    }
}
