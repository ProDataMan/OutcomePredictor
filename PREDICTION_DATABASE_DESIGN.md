# Prediction Database Storage Design

## Overview

System for storing predictions in a database, comparing them with actual game outcomes, and tracking prediction accuracy over time for model tuning.

## Database Schema

### Predictions Table

Stores all predictions made by the system.

```sql
CREATE TABLE predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL,

    -- Teams
    home_team_id VARCHAR(3) NOT NULL,  -- Team abbreviation
    away_team_id VARCHAR(3) NOT NULL,

    -- Game info
    scheduled_date TIMESTAMP NOT NULL,
    week INTEGER NOT NULL,
    season INTEGER NOT NULL,
    location VARCHAR(255),

    -- Prediction data
    home_win_probability DOUBLE PRECISION NOT NULL,
    away_win_probability DOUBLE PRECISION NOT NULL,
    confidence DOUBLE PRECISION NOT NULL,
    predicted_home_score INTEGER,
    predicted_away_score INTEGER,
    reasoning TEXT,

    -- Model info
    predictor_name VARCHAR(100) NOT NULL,  -- e.g., "BaselinePredictor", "LLMPredictor"
    predictor_version VARCHAR(50) NOT NULL,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes
    CONSTRAINT fk_game FOREIGN KEY (game_id) REFERENCES games(id),
    INDEX idx_predictions_game_id (game_id),
    INDEX idx_predictions_scheduled_date (scheduled_date),
    INDEX idx_predictions_season_week (season, week)
);
```

### Games Table

Stores game information and actual outcomes.

```sql
CREATE TABLE games (
    id UUID PRIMARY KEY,

    -- Teams
    home_team_id VARCHAR(3) NOT NULL,
    away_team_id VARCHAR(3) NOT NULL,

    -- Game info
    scheduled_date TIMESTAMP NOT NULL,
    week INTEGER NOT NULL,
    season INTEGER NOT NULL,

    -- Actual outcome (populated after game completes)
    actual_home_score INTEGER,
    actual_away_score INTEGER,
    winner VARCHAR(10),  -- 'home', 'away', 'tie'
    game_completed_at TIMESTAMP,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes
    INDEX idx_games_scheduled_date (scheduled_date),
    INDEX idx_games_season_week (season, week),
    INDEX idx_games_teams (home_team_id, away_team_id)
);
```

### Prediction Evaluations Table

Stores evaluation metrics after comparing predictions with actual outcomes.

```sql
CREATE TABLE prediction_evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prediction_id UUID NOT NULL,
    game_id UUID NOT NULL,

    -- Accuracy metrics
    predicted_winner_correct BOOLEAN NOT NULL,
    score_difference_home INTEGER,  -- predicted - actual
    score_difference_away INTEGER,
    total_score_difference INTEGER,  -- sum of absolute differences

    -- Probability metrics
    brier_score DOUBLE PRECISION,  -- (predicted_prob - actual_outcome)^2
    log_loss DOUBLE PRECISION,

    -- Calculated at
    evaluated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT fk_prediction FOREIGN KEY (prediction_id) REFERENCES predictions(id),
    CONSTRAINT fk_game_eval FOREIGN KEY (game_id) REFERENCES games(id),
    INDEX idx_evaluations_prediction_id (prediction_id),
    INDEX idx_evaluations_game_id (game_id)
);
```

### Predictor Performance Table

Aggregated statistics for each predictor model.

```sql
CREATE TABLE predictor_performance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    predictor_name VARCHAR(100) NOT NULL,
    predictor_version VARCHAR(50) NOT NULL,

    -- Time period
    evaluation_period_start DATE NOT NULL,
    evaluation_period_end DATE NOT NULL,

    -- Aggregate metrics
    total_predictions INTEGER NOT NULL,
    correct_predictions INTEGER NOT NULL,
    accuracy DOUBLE PRECISION NOT NULL,

    -- Score prediction metrics
    avg_score_difference DOUBLE PRECISION,
    median_score_difference DOUBLE PRECISION,

    -- Probability metrics
    avg_brier_score DOUBLE PRECISION,
    avg_log_loss DOUBLE PRECISION,
    calibration_score DOUBLE PRECISION,

    -- Confidence analysis
    high_confidence_predictions INTEGER,  -- confidence > 0.7
    high_confidence_correct INTEGER,
    high_confidence_accuracy DOUBLE PRECISION,

    -- Metadata
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes
    INDEX idx_performance_predictor (predictor_name, predictor_version),
    INDEX idx_performance_period (evaluation_period_start, evaluation_period_end),
    UNIQUE (predictor_name, predictor_version, evaluation_period_start, evaluation_period_end)
);
```

## Implementation Steps

### 1. Database Setup

Create a new package for database operations using Fluent (Vapor's ORM).

**Files to Create:**
- `Sources/OutcomePredictorDB/Models/PredictionRecord.swift`
- `Sources/OutcomePredictorDB/Models/GameRecord.swift`
- `Sources/OutcomePredictorDB/Models/PredictionEvaluation.swift`
- `Sources/OutcomePredictorDB/Models/PredictorPerformance.swift`
- `Sources/OutcomePredictorDB/Migrations/CreatePredictionsTable.swift`
- `Sources/OutcomePredictorDB/Migrations/CreateGamesTable.swift`
- `Sources/OutcomePredictorDB/Repositories/PredictionRepository.swift`

### 2. Fluent Models

Example PredictionRecord model:

```swift
import Foundation
import Fluent
import Vapor

final class PredictionRecord: Model, Content {
    static let schema = "predictions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "game_id")
    var gameId: UUID

    @Field(key: "home_team_id")
    var homeTeamId: String

    @Field(key: "away_team_id")
    var awayTeamId: String

    @Field(key: "scheduled_date")
    var scheduledDate: Date

    @Field(key: "week")
    var week: Int

    @Field(key: "season")
    var season: Int

    @Field(key: "location")
    var location: String?

    @Field(key: "home_win_probability")
    var homeWinProbability: Double

    @Field(key: "away_win_probability")
    var awayWinProbability: Double

    @Field(key: "confidence")
    var confidence: Double

    @Field(key: "predicted_home_score")
    var predictedHomeScore: Int?

    @Field(key: "predicted_away_score")
    var predictedAwayScore: Int?

    @Field(key: "reasoning")
    var reasoning: String?

    @Field(key: "predictor_name")
    var predictorName: String

    @Field(key: "predictor_version")
    var predictorVersion: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(from prediction: Prediction, predictorName: String, predictorVersion: String) {
        self.gameId = prediction.game.id
        self.homeTeamId = prediction.game.homeTeam.abbreviation
        self.awayTeamId = prediction.game.awayTeam.abbreviation
        self.scheduledDate = prediction.game.scheduledDate
        self.week = prediction.game.week
        self.season = prediction.game.season
        self.homeWinProbability = prediction.homeWinProbability
        self.awayWinProbability = prediction.awayWinProbability
        self.confidence = prediction.confidence
        self.predictedHomeScore = prediction.predictedHomeScore
        self.predictedAwayScore = prediction.predictedAwayScore
        self.reasoning = prediction.reasoning
        self.predictorName = predictorName
        self.predictorVersion = predictorVersion
    }
}
```

### 3. Server Integration

Update `Sources/NFLServer/main.swift` to save predictions:

```swift
// After creating prediction
let prediction = try await predictor.predict(game: game, features: [:])

// Save to database
let predictionRecord = PredictionRecord(
    from: prediction,
    predictorName: "BaselinePredictor",
    predictorVersion: "1.0.0"
)
try await predictionRecord.save(on: req.db)
```

### 4. Daily Evaluation Job

Create a scheduled task to evaluate predictions:

```swift
// Sources/NFLServer/Jobs/EvaluatePredictionsJob.swift
import Vapor
import Fluent

struct EvaluatePredictionsJob {
    func run(on database: Database) async throws {
        // Find predictions for games that completed in last 24 hours
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let predictions = try await PredictionRecord.query(on: database)
            .filter(\.$scheduledDate >= yesterday)
            .all()

        for predictionRecord in predictions {
            // Fetch actual game outcome
            guard let game = try await GameRecord.find(predictionRecord.gameId, on: database),
                  let actualHomeScore = game.actualHomeScore,
                  let actualAwayScore = game.actualAwayScore else {
                continue  // Game not yet completed
            }

            // Calculate evaluation metrics
            let evaluation = try calculateEvaluation(
                prediction: predictionRecord,
                actualHomeScore: actualHomeScore,
                actualAwayScore: actualAwayScore
            )

            // Save evaluation
            try await evaluation.save(on: database)
        }

        // Update aggregate predictor performance
        try await updatePredictorPerformance(on: database)
    }

    private func calculateEvaluation(
        prediction: PredictionRecord,
        actualHomeScore: Int,
        actualAwayScore: Int
    ) throws -> PredictionEvaluation {
        let actualWinner = actualHomeScore > actualAwayScore ? "home" :
                          actualAwayScore > actualHomeScore ? "away" : "tie"
        let predictedWinner = prediction.homeWinProbability > 0.5 ? "home" : "away"

        let evaluation = PredictionEvaluation()
        evaluation.predictionId = prediction.id!
        evaluation.gameId = prediction.gameId
        evaluation.predictedWinnerCorrect = (actualWinner == predictedWinner)

        if let predictedHome = prediction.predictedHomeScore,
           let predictedAway = prediction.predictedAwayScore {
            evaluation.scoreDifferenceHome = predictedHome - actualHomeScore
            evaluation.scoreDifferenceAway = predictedAway - actualAwayScore
            evaluation.totalScoreDifference = abs(predictedHome - actualHomeScore) +
                                             abs(predictedAway - actualAwayScore)
        }

        // Calculate Brier score
        let actualOutcome = actualWinner == "home" ? 1.0 : 0.0
        evaluation.brierScore = pow(prediction.homeWinProbability - actualOutcome, 2)

        // Calculate log loss
        let epsilon = 1e-15
        let prob = max(epsilon, min(1.0 - epsilon, prediction.homeWinProbability))
        evaluation.logLoss = actualOutcome == 1.0 ? -log(prob) : -log(1.0 - prob)

        return evaluation
    }
}
```

### 5. Schedule Job in Server

```swift
// In configure(_ app: Application)
app.queues.schedule(EvaluatePredictionsJob())
    .daily()
    .at(6, 0)  // Run at 6:00 AM daily
```

### 6. API Endpoints for Analytics

Add new endpoints to query prediction accuracy:

```swift
// GET /api/v1/analytics/predictor-performance
api.get("analytics", "predictor-performance") { req async throws -> PredictorPerformanceDTO in
    let predictorName = req.query[String.self, at: "predictor"] ?? "BaselinePredictor"
    let days = req.query[Int.self, at: "days"] ?? 30

    let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

    let performance = try await PredictorPerformance.query(on: req.db)
        .filter(\.$predictorName == predictorName)
        .filter(\.$evaluationPeriodStart >= startDate)
        .first()

    guard let performance = performance else {
        throw Abort(.notFound, reason: "No performance data found")
    }

    return PredictorPerformanceDTO(from: performance)
}

// GET /api/v1/analytics/recent-predictions
api.get("analytics", "recent-predictions") { req async throws -> [PredictionWithEvaluationDTO] in
    let limit = req.query[Int.self, at: "limit"] ?? 10

    let predictions = try await PredictionRecord.query(on: req.db)
        .with(\.$evaluation)
        .sort(\.$createdAt, .descending)
        .limit(limit)
        .all()

    return predictions.map { PredictionWithEvaluationDTO(from: $0) }
}
```

## Configuration

### Database Connection

Add to `Sources/NFLServer/main.swift`:

```swift
// Configure database
let databaseURL = Environment.get("DATABASE_URL") ?? "postgresql://localhost/nfl_predictions"
try app.databases.use(.postgres(url: databaseURL), as: .psql)

// Run migrations
app.migrations.add(CreateGamesTable())
app.migrations.add(CreatePredictionsTable())
app.migrations.add(CreatePredictionEvaluationsTable())
app.migrations.add(CreatePredictorPerformanceTable())

try await app.autoMigrate()
```

### Environment Variables

```bash
export DATABASE_URL="postgresql://user:password@localhost:5432/nfl_predictions"
```

## Benefits

1. **Historical Tracking**: Complete history of all predictions
2. **Model Comparison**: Compare different predictors side-by-side
3. **Accuracy Metrics**: Detailed statistics on prediction performance
4. **Confidence Calibration**: Verify if confidence scores match actual accuracy
5. **Continuous Improvement**: Identify weaknesses to improve models
6. **Score Accuracy**: Track how close score predictions are to actual results

## Next Steps

1. Set up PostgreSQL database
2. Create Fluent models and migrations
3. Update server to save predictions
4. Implement daily evaluation job
5. Add analytics endpoints
6. Create iOS UI to display prediction history and accuracy stats
