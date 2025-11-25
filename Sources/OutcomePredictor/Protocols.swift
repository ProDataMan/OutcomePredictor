import Foundation

/// Fetches news articles and social media posts related to teams.
public protocol NewsDataSource: Sendable {
    /// Fetches articles for a specific team before a given date.
    ///
    /// - Parameters:
    ///   - team: Team to fetch articles about.
    ///   - date: Fetch articles published before this date.
    /// - Returns: Array of articles sorted by publication date (newest first).
    /// - Throws: Network or parsing errors.
    func fetchArticles(for team: Team, before date: Date) async throws -> [Article]
}

/// Analyzes sentiment from text content.
public protocol SentimentAnalyzer: Sendable {
    /// Analyzes sentiment of given text.
    ///
    /// - Parameter text: Text to analyze.
    /// - Returns: Sentiment score with confidence.
    /// - Throws: Analysis errors.
    func analyzeSentiment(_ text: String) async throws -> SentimentScore
}

/// Extracts numeric features from articles for machine learning.
public protocol FeatureExtractor: Sendable {
    /// Extracts features from a collection of articles.
    ///
    /// - Parameter articles: Articles to process.
    /// - Returns: Dictionary of feature names to numeric values.
    /// - Throws: Extraction errors.
    func extractFeatures(from articles: [Article]) async throws -> [String: Double]
}

/// Predicts game outcomes.
public protocol GamePredictor: Sendable {
    /// Predicts the outcome of a game.
    ///
    /// - Parameters:
    ///   - game: Game to predict.
    ///   - features: Optional additional features for prediction.
    /// - Returns: Prediction with probability and reasoning.
    /// - Throws: `PredictionError` if prediction cannot be made.
    func predict(game: Game, features: [String: Double]) async throws -> Prediction
}

/// Stores and retrieves historical game data.
public protocol GameRepository: Sendable {
    /// Fetches all games for a specific team in a season.
    ///
    /// - Parameters:
    ///   - team: Team to query.
    ///   - season: Season year.
    /// - Returns: Array of games.
    /// - Throws: Storage errors.
    func games(for team: Team, season: Int) async throws -> [Game]

    /// Fetches a specific game by identifier.
    ///
    /// - Parameter id: Game identifier.
    /// - Returns: Game if found, nil otherwise.
    /// - Throws: Storage errors.
    func game(id: UUID) async throws -> Game?

    /// Saves a game to the repository.
    ///
    /// - Parameter game: Game to save.
    /// - Throws: Storage errors.
    func save(_ game: Game) async throws

    /// Fetches games within a date range.
    ///
    /// - Parameters:
    ///   - startDate: Start of range (inclusive).
    ///   - endDate: End of range (inclusive).
    /// - Returns: Array of games in the date range.
    /// - Throws: Storage errors.
    func games(from startDate: Date, to endDate: Date) async throws -> [Game]
}

/// Stores and retrieves predictions.
public protocol PredictionRepository: Sendable {
    /// Saves a prediction.
    ///
    /// - Parameter prediction: Prediction to save.
    /// - Throws: Storage errors.
    func save(_ prediction: Prediction) async throws

    /// Fetches all predictions for a specific game.
    ///
    /// - Parameter gameId: Game identifier.
    /// - Returns: Array of predictions for the game.
    /// - Throws: Storage errors.
    func predictions(for gameId: UUID) async throws -> [Prediction]

    /// Fetches predictions within a date range.
    ///
    /// - Parameters:
    ///   - startDate: Start of range (inclusive).
    ///   - endDate: End of range (inclusive).
    /// - Returns: Array of predictions made in the date range.
    /// - Throws: Storage errors.
    func predictions(from startDate: Date, to endDate: Date) async throws -> [Prediction]
}

/// Evaluates prediction accuracy and calibration.
public protocol PredictionEvaluator: Sendable {
    /// Calculates accuracy of predictions against actual outcomes.
    ///
    /// - Parameter predictions: Predictions with corresponding actual outcomes.
    /// - Returns: Accuracy metrics.
    /// - Throws: Evaluation errors.
    func evaluate(_ predictions: [(prediction: Prediction, outcome: GameOutcome)]) async throws -> EvaluationMetrics
}

/// Metrics for evaluating prediction quality.
public struct EvaluationMetrics: Codable, Sendable {
    /// Percentage of correct winner predictions.
    public let accuracy: Double

    /// Brier score (lower is better, measures probability calibration).
    public let brierScore: Double

    /// Log loss (lower is better).
    public let logLoss: Double

    /// Total number of predictions evaluated.
    public let totalPredictions: Int

    /// Creates evaluation metrics.
    ///
    /// - Parameters:
    ///   - accuracy: Prediction accuracy (0.0 to 1.0).
    ///   - brierScore: Brier score.
    ///   - logLoss: Log loss value.
    ///   - totalPredictions: Count of predictions.
    public init(accuracy: Double, brierScore: Double, logLoss: Double, totalPredictions: Int) {
        self.accuracy = accuracy
        self.brierScore = brierScore
        self.logLoss = logLoss
        self.totalPredictions = totalPredictions
    }
}
