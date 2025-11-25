import Foundation

/// Baseline predictor using historical win rates and home field advantage.
///
/// This predictor uses simple statistics:
/// - Team win percentage from historical games
/// - Home field advantage adjustment
/// - Recent performance weighting
public struct BaselinePredictor: GamePredictor {
    private let gameRepository: GameRepository
    private let homeFieldAdvantage: Double
    private let recentGamesWeight: Int

    /// Creates a baseline predictor.
    ///
    /// - Parameters:
    ///   - gameRepository: Repository for historical game data.
    ///   - homeFieldAdvantage: Probability boost for home team (default: 0.05).
    ///   - recentGamesWeight: Number of recent games to weight more heavily (default: 5).
    public init(
        gameRepository: GameRepository,
        homeFieldAdvantage: Double = 0.05,
        recentGamesWeight: Int = 5
    ) {
        self.gameRepository = gameRepository
        self.homeFieldAdvantage = homeFieldAdvantage
        self.recentGamesWeight = recentGamesWeight
    }

    public func predict(game: Game, features: [String: Double]) async throws -> Prediction {
        // Fetch historical games for both teams in current season
        let homeGames = try await gameRepository.games(for: game.homeTeam, season: game.season)
        let awayGames = try await gameRepository.games(for: game.awayTeam, season: game.season)

        // Filter only completed games before the prediction date
        let completedHomeGames = homeGames.filter { $0.outcome != nil && $0.scheduledDate < game.scheduledDate }
        let completedAwayGames = awayGames.filter { $0.outcome != nil && $0.scheduledDate < game.scheduledDate }

        guard !completedHomeGames.isEmpty || !completedAwayGames.isEmpty else {
            throw PredictionError.insufficientData
        }

        // Calculate win rates
        let homeWinRate = calculateWinRate(for: game.homeTeam, in: completedHomeGames)
        let awayWinRate = calculateWinRate(for: game.awayTeam, in: completedAwayGames)

        // Apply home field advantage
        var homeWinProbability = (homeWinRate + homeFieldAdvantage + (1.0 - awayWinRate)) / 2.0

        // Clamp probability to valid range
        homeWinProbability = max(0.0, min(1.0, homeWinProbability))

        // Calculate confidence based on sample size
        let totalGames = completedHomeGames.count + completedAwayGames.count
        let confidence = min(1.0, Double(totalGames) / 20.0)

        let reasoning = """
        Baseline prediction based on historical win rates:
        - \(game.homeTeam.name): \(String(format: "%.1f%%", homeWinRate * 100)) win rate (\(completedHomeGames.count) games)
        - \(game.awayTeam.name): \(String(format: "%.1f%%", awayWinRate * 100)) win rate (\(completedAwayGames.count) games)
        - Home field advantage: +\(String(format: "%.1f%%", homeFieldAdvantage * 100))
        - Confidence: \(String(format: "%.1f%%", confidence * 100))
        """

        return try Prediction(
            game: game,
            homeWinProbability: homeWinProbability,
            confidence: confidence,
            reasoning: reasoning
        )
    }

    private func calculateWinRate(for team: Team, in games: [Game]) -> Double {
        guard !games.isEmpty else { return 0.5 }

        let wins = games.filter { game in
            guard let outcome = game.outcome else { return false }

            if game.homeTeam.id == team.id {
                return outcome.winner == .home
            } else if game.awayTeam.id == team.id {
                return outcome.winner == .away
            }
            return false
        }.count

        return Double(wins) / Double(games.count)
    }
}

/// In-memory game repository for testing and development.
public actor InMemoryGameRepository: GameRepository {
    private var games: [UUID: Game] = [:]

    /// Creates an empty in-memory repository.
    public init() {}

    /// Creates a repository with initial games.
    ///
    /// - Parameter games: Initial games to store.
    public init(games: [Game]) {
        for game in games {
            self.games[game.id] = game
        }
    }

    public func games(for team: Team, season: Int) async throws -> [Game] {
        games.values.filter { game in
            game.season == season &&
            (game.homeTeam.id == team.id || game.awayTeam.id == team.id)
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    public func game(id: UUID) async throws -> Game? {
        games[id]
    }

    public func save(_ game: Game) async throws {
        games[game.id] = game
    }

    public func games(from startDate: Date, to endDate: Date) async throws -> [Game] {
        games.values.filter { game in
            game.scheduledDate >= startDate && game.scheduledDate <= endDate
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }
}

/// In-memory prediction repository for testing and development.
public actor InMemoryPredictionRepository: PredictionRepository {
    private var predictions: [Prediction] = []

    /// Creates an empty in-memory prediction repository.
    public init() {}

    public func save(_ prediction: Prediction) async throws {
        predictions.append(prediction)
    }

    public func predictions(for gameId: UUID) async throws -> [Prediction] {
        predictions.filter { $0.game.id == gameId }
            .sorted { $0.timestamp < $1.timestamp }
    }

    public func predictions(from startDate: Date, to endDate: Date) async throws -> [Prediction] {
        predictions.filter { prediction in
            prediction.timestamp >= startDate && prediction.timestamp <= endDate
        }.sorted { $0.timestamp < $1.timestamp }
    }
}

/// Basic prediction evaluator using standard metrics.
public struct BasicPredictionEvaluator: PredictionEvaluator {
    /// Creates a basic evaluator.
    public init() {}

    public func evaluate(
        _ predictions: [(prediction: Prediction, outcome: GameOutcome)]
    ) async throws -> EvaluationMetrics {
        guard !predictions.isEmpty else {
            return EvaluationMetrics(accuracy: 0, brierScore: 0, logLoss: 0, totalPredictions: 0)
        }

        var correctPredictions = 0
        var brierSum = 0.0
        var logLossSum = 0.0

        for (prediction, outcome) in predictions {
            // Calculate accuracy
            if prediction.predictedWinner == outcome.winner {
                correctPredictions += 1
            }

            // Calculate Brier score
            let actualOutcome = outcome.winner == .home ? 1.0 : 0.0
            let predictedProb = prediction.homeWinProbability
            let brierContribution = pow(predictedProb - actualOutcome, 2)
            brierSum += brierContribution

            // Calculate log loss
            let epsilon = 1e-15 // Prevent log(0)
            let clampedProb = max(epsilon, min(1.0 - epsilon, predictedProb))
            let logLossContribution = actualOutcome == 1.0
                ? -log(clampedProb)
                : -log(1.0 - clampedProb)
            logLossSum += logLossContribution
        }

        let total = predictions.count
        let accuracy = Double(correctPredictions) / Double(total)
        let brierScore = brierSum / Double(total)
        let logLoss = logLossSum / Double(total)

        return EvaluationMetrics(
            accuracy: accuracy,
            brierScore: brierScore,
            logLoss: logLoss,
            totalPredictions: total
        )
    }
}
