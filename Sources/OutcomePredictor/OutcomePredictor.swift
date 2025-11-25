/// OutcomePredictor - NFL Game Outcome Prediction Framework
///
/// A protocol-oriented Swift framework for predicting NFL game outcomes using historical data,
/// text analysis, and machine learning techniques.
///
/// ## Core Components
///
/// - **Domain Models**: Team, Game, Prediction, Article, SentimentScore
/// - **Protocols**: GamePredictor, NewsDataSource, SentimentAnalyzer, FeatureExtractor
/// - **Implementations**: BaselinePredictor, InMemoryGameRepository, BasicPredictionEvaluator
///
/// ## Getting Started
///
/// ```swift
/// // Create a game repository with historical data
/// let repository = InMemoryGameRepository()
///
/// // Create a predictor
/// let predictor = BaselinePredictor(gameRepository: repository)
///
/// // Make a prediction
/// let prediction = try await predictor.predict(game: game, features: [:])
/// print("Home win probability: \(prediction.homeWinProbability)")
/// ```
///
/// ## Architecture
///
/// The framework follows protocol-oriented design principles:
/// - Dependency injection through protocols
/// - Value types for domain models
/// - Explicit error handling
/// - Modern async/await concurrency
///
/// ## Extension Points
///
/// Implement custom predictors by conforming to `GamePredictor`:
///
/// ```swift
/// struct MyPredictor: GamePredictor {
///     func predict(game: Game, features: [String: Double]) async throws -> Prediction {
///         // Custom prediction logic
///     }
/// }
/// ```
