import Foundation

/// Ensemble predictor that combines multiple prediction strategies.
public struct EnsemblePredictor: GamePredictor {
    private let predictors: [(predictor: any GamePredictor, weight: Double)]

    /// Creates an ensemble predictor.
    ///
    /// - Parameter predictors: Array of predictors with their weights.
    /// - Note: Weights should sum to 1.0 for proper probability calibration.
    public init(predictors: [(predictor: any GamePredictor, weight: Double)]) {
        self.predictors = predictors
    }

    /// Creates an ensemble with common configurations.
    ///
    /// - Parameters:
    ///   - baseline: Baseline predictor.
    ///   - llm: LLM predictor.
    ///   - baselineWeight: Weight for baseline (default: 0.3).
    ///   - llmWeight: Weight for LLM (default: 0.7).
    /// - Returns: Configured ensemble predictor.
    public static func standard(
        baseline: BaselinePredictor,
        llm: LLMPredictor,
        baselineWeight: Double = 0.3,
        llmWeight: Double = 0.7
    ) -> EnsemblePredictor {
        EnsemblePredictor(predictors: [
            (baseline, baselineWeight),
            (llm, llmWeight)
        ])
    }

    public func predict(game: Game, features: [String: Double]) async throws -> Prediction {
        // Get predictions from all predictors
        var predictions: [(prediction: Prediction, weight: Double)] = []

        for (predictor, weight) in predictors {
            do {
                let prediction = try await predictor.predict(game: game, features: features)
                predictions.append((prediction, weight))
            } catch {
                // Log error but continue with other predictors
                print("Warning: Predictor failed with error: \(error)")
            }
        }

        guard !predictions.isEmpty else {
            throw PredictionError.insufficientData
        }

        // Calculate weighted average of probabilities
        var weightedProb = 0.0
        var weightedConf = 0.0
        var totalWeight = 0.0

        for (prediction, weight) in predictions {
            weightedProb += prediction.homeWinProbability * weight
            weightedConf += prediction.confidence * weight
            totalWeight += weight
        }

        // Normalize by actual total weight (in case some predictors failed)
        let finalProb = weightedProb / totalWeight
        let finalConf = weightedConf / totalWeight

        // Combine reasoning from all predictors
        let reasoning = buildEnsembleReasoning(predictions: predictions, finalProb: finalProb)

        return try Prediction(
            game: game,
            homeWinProbability: finalProb,
            confidence: finalConf,
            reasoning: reasoning
        )
    }

    private func buildEnsembleReasoning(
        predictions: [(prediction: Prediction, weight: Double)],
        finalProb: Double
    ) -> String {
        var reasoning = """
        Ensemble Prediction (combining \(predictions.count) models):
        Final probability: \(String(format: "%.1f%%", finalProb * 100))

        Individual predictions:

        """

        for (index, (prediction, weight)) in predictions.enumerated() {
            reasoning += """
            Model \(index + 1) (weight: \(String(format: "%.2f", weight))):
            - Probability: \(String(format: "%.1f%%", prediction.homeWinProbability * 100))
            - Confidence: \(String(format: "%.1f%%", prediction.confidence * 100))


            """
        }

        return reasoning
    }
}

/// Adaptive predictor that learns from recent prediction accuracy.
public actor AdaptiveEnsemblePredictor: GamePredictor {
    private var baselineWeight: Double
    private var llmWeight: Double
    private let baseline: BaselinePredictor
    private let llm: LLMPredictor
    private var recentAccuracy: [(baseline: Bool, llm: Bool)] = []
    private let windowSize: Int

    /// Creates an adaptive ensemble predictor.
    ///
    /// - Parameters:
    ///   - baseline: Baseline predictor.
    ///   - llm: LLM predictor.
    ///   - initialBaselineWeight: Starting weight for baseline.
    ///   - initialLLMWeight: Starting weight for LLM.
    ///   - windowSize: Number of recent predictions to track.
    public init(
        baseline: BaselinePredictor,
        llm: LLMPredictor,
        initialBaselineWeight: Double = 0.3,
        initialLLMWeight: Double = 0.7,
        windowSize: Int = 20
    ) {
        self.baseline = baseline
        self.llm = llm
        self.baselineWeight = initialBaselineWeight
        self.llmWeight = initialLLMWeight
        self.windowSize = windowSize
    }

    public func predict(game: Game, features: [String: Double]) async throws -> Prediction {
        // Get predictions from both models
        let baselinePred = try await baseline.predict(game: game, features: features)
        let llmPred = try await llm.predict(game: game, features: features)

        // Calculate weighted average
        let totalWeight = baselineWeight + llmWeight
        let finalProb = (baselinePred.homeWinProbability * baselineWeight + llmPred.homeWinProbability * llmWeight) / totalWeight
        let finalConf = (baselinePred.confidence * baselineWeight + llmPred.confidence * llmWeight) / totalWeight

        let reasoning = """
        Adaptive Ensemble Prediction:
        - Baseline: \(String(format: "%.1f%%", baselinePred.homeWinProbability * 100)) (weight: \(String(format: "%.2f", baselineWeight)))
        - LLM: \(String(format: "%.1f%%", llmPred.homeWinProbability * 100)) (weight: \(String(format: "%.2f", llmWeight)))
        - Final: \(String(format: "%.1f%%", finalProb * 100))

        Recent accuracy window: \(recentAccuracy.count)/\(windowSize) predictions
        """

        return try Prediction(
            game: game,
            homeWinProbability: finalProb,
            confidence: finalConf,
            reasoning: reasoning
        )
    }

    /// Updates weights based on actual game outcome.
    ///
    /// - Parameters:
    ///   - game: Game that was predicted.
    ///   - baselinePrediction: Prediction from baseline model.
    ///   - llmPrediction: Prediction from LLM model.
    ///   - outcome: Actual game outcome.
    public func updateWeights(
        game: Game,
        baselinePrediction: Prediction,
        llmPrediction: Prediction,
        outcome: GameOutcome
    ) {
        // Check if each model was correct
        let baselineCorrect = baselinePrediction.predictedWinner == outcome.winner
        let llmCorrect = llmPrediction.predictedWinner == outcome.winner

        // Add to recent accuracy
        recentAccuracy.append((baselineCorrect, llmCorrect))

        // Keep only recent window
        if recentAccuracy.count > windowSize {
            recentAccuracy.removeFirst()
        }

        // Recalculate weights based on recent accuracy
        let baselineAccuracy = Double(recentAccuracy.filter { $0.baseline }.count) / Double(recentAccuracy.count)
        let llmAccuracy = Double(recentAccuracy.filter { $0.llm }.count) / Double(recentAccuracy.count)

        let totalAccuracy = baselineAccuracy + llmAccuracy

        if totalAccuracy > 0 {
            baselineWeight = baselineAccuracy / totalAccuracy
            llmWeight = llmAccuracy / totalAccuracy
        }
    }
}

/// Predictor selection strategy based on game characteristics.
public struct ContextAwarePredictor: GamePredictor {
    private let baseline: BaselinePredictor
    private let llm: LLMPredictor

    /// Creates a context-aware predictor.
    ///
    /// - Parameters:
    ///   - baseline: Baseline predictor for data-rich scenarios.
    ///   - llm: LLM predictor for narrative-heavy scenarios.
    public init(baseline: BaselinePredictor, llm: LLMPredictor) {
        self.baseline = baseline
        self.llm = llm
    }

    public func predict(game: Game, features: [String: Double]) async throws -> Prediction {
        // Decision logic: use LLM for:
        // - Division rivalry games
        // - Games with significant narrative factors
        // - Games where baseline lacks sufficient data

        let useLLM = shouldUseLLM(for: game, features: features)

        if useLLM {
            return try await llm.predict(game: game, features: features)
        } else {
            return try await baseline.predict(game: game, features: features)
        }
    }

    private func shouldUseLLM(for game: Game, features: [String: Double]) -> Bool {
        // Use LLM for division rivalry games
        if game.homeTeam.conference == game.awayTeam.conference &&
           game.homeTeam.division == game.awayTeam.division {
            return true
        }

        // Use LLM if we have text features (news/social media)
        if features.keys.contains(where: { $0.hasPrefix("sentiment_") || $0.hasPrefix("news_") }) {
            return true
        }

        // Use LLM for playoff implications (week 15+)
        if game.week >= 15 {
            return true
        }

        // Otherwise use baseline
        return false
    }
}
