import Testing
import Foundation
@testable import OutcomePredictor

@Suite("Feature: Domain Models")
struct DomainModelTests {
    @Test("Creates team with required properties", .tags(.small))
    func testTeamCreation() {
        let team = Team(
            name: "San Francisco 49ers",
            abbreviation: "SF",
            conference: .nfc,
            division: .west
        )

        #expect(team.name == "San Francisco 49ers")
        #expect(team.abbreviation == "SF")
        #expect(team.conference == .nfc)
        #expect(team.division == .west)
    }

    @Test("Creates game with teams and schedule", .tags(.small))
    func testGameCreation() {
        let homeTeam = Team(name: "49ers", abbreviation: "SF", conference: .nfc, division: .west)
        let awayTeam = Team(name: "Seahawks", abbreviation: "SEA", conference: .nfc, division: .west)
        let scheduledDate = Date()

        let game = Game(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            scheduledDate: scheduledDate,
            week: 1,
            season: 2024
        )

        #expect(game.homeTeam.name == "49ers")
        #expect(game.awayTeam.name == "Seahawks")
        #expect(game.week == 1)
        #expect(game.season == 2024)
        #expect(game.outcome == nil)
    }

    @Test("GameOutcome calculates winner correctly", .tags(.small))
    func testGameOutcomeWinner() {
        let homeWin = GameOutcome(homeScore: 24, awayScore: 17)
        #expect(homeWin.winner == .home)
        #expect(homeWin.pointDifferential == 7)

        let awayWin = GameOutcome(homeScore: 17, awayScore: 24)
        #expect(awayWin.winner == .away)
        #expect(awayWin.pointDifferential == -7)

        let tie = GameOutcome(homeScore: 20, awayScore: 20)
        #expect(tie.winner == .tie)
        #expect(tie.pointDifferential == 0)
    }

    @Test("Prediction validates probability range", .tags(.small))
    func testPredictionValidation() throws {
        let game = createTestGame()

        // Valid prediction
        let validPrediction = try Prediction(
            game: game,
            homeWinProbability: 0.65,
            confidence: 0.8,
            reasoning: "Test"
        )
        #expect(validPrediction.homeWinProbability == 0.65)
        #expect(validPrediction.awayWinProbability == 0.35)
        #expect(validPrediction.predictedWinner == .home)

        // Invalid probability - too high
        #expect(throws: PredictionError.self) {
            try Prediction(
                game: game,
                homeWinProbability: 1.5,
                confidence: 0.8,
                reasoning: "Test"
            )
        }

        // Invalid probability - negative
        #expect(throws: PredictionError.self) {
            try Prediction(
                game: game,
                homeWinProbability: -0.1,
                confidence: 0.8,
                reasoning: "Test"
            )
        }
    }

    @Test("Prediction determines winner from probability", .tags(.small))
    func testPredictionWinner() throws {
        let game = createTestGame()

        let homeWin = try Prediction(
            game: game,
            homeWinProbability: 0.7,
            confidence: 0.8,
            reasoning: "Home favored"
        )
        #expect(homeWin.predictedWinner == .home)

        let awayWin = try Prediction(
            game: game,
            homeWinProbability: 0.3,
            confidence: 0.8,
            reasoning: "Away favored"
        )
        #expect(awayWin.predictedWinner == .away)

        let tossup = try Prediction(
            game: game,
            homeWinProbability: 0.5,
            confidence: 0.5,
            reasoning: "Even match"
        )
        #expect(tossup.predictedWinner == .tie)
    }
}

@Suite("Feature: In-Memory Repositories")
struct RepositoryTests {
    @Test("InMemoryGameRepository stores and retrieves games", .tags(.medium))
    func testGameRepositoryBasicOperations() async throws {
        let repository = InMemoryGameRepository()
        let game = createTestGame()

        try await repository.save(game)

        let retrieved = try await repository.game(id: game.id)
        #expect(retrieved != nil)
        #expect(retrieved?.id == game.id)
    }

    @Test("InMemoryGameRepository filters games by team and season", .tags(.medium))
    func testGameRepositoryFiltering() async throws {
        let repository = InMemoryGameRepository()
        let team = Team(name: "49ers", abbreviation: "SF", conference: .nfc, division: .west)
        let otherTeam = Team(name: "Seahawks", abbreviation: "SEA", conference: .nfc, division: .west)

        let game1 = Game(
            homeTeam: team,
            awayTeam: otherTeam,
            scheduledDate: Date(),
            week: 1,
            season: 2024
        )
        let game2 = Game(
            homeTeam: otherTeam,
            awayTeam: team,
            scheduledDate: Date(),
            week: 2,
            season: 2024
        )
        let game3 = Game(
            homeTeam: team,
            awayTeam: otherTeam,
            scheduledDate: Date(),
            week: 1,
            season: 2023
        )

        try await repository.save(game1)
        try await repository.save(game2)
        try await repository.save(game3)

        let games2024 = try await repository.games(for: team, season: 2024)
        #expect(games2024.count == 2)

        let games2023 = try await repository.games(for: team, season: 2023)
        #expect(games2023.count == 1)
    }

    @Test("InMemoryGameRepository filters by date range", .tags(.medium))
    func testGameRepositoryDateRange() async throws {
        let repository = InMemoryGameRepository()
        let team = Team(name: "49ers", abbreviation: "SF", conference: .nfc, division: .west)
        let otherTeam = Team(name: "Seahawks", abbreviation: "SEA", conference: .nfc, division: .west)

        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let game1 = Game(homeTeam: team, awayTeam: otherTeam, scheduledDate: yesterday, week: 1, season: 2024)
        let game2 = Game(homeTeam: team, awayTeam: otherTeam, scheduledDate: today, week: 2, season: 2024)
        let game3 = Game(homeTeam: team, awayTeam: otherTeam, scheduledDate: tomorrow, week: 3, season: 2024)

        try await repository.save(game1)
        try await repository.save(game2)
        try await repository.save(game3)

        let gamesInRange = try await repository.games(from: yesterday, to: today)
        #expect(gamesInRange.count == 2)
    }

    @Test("InMemoryPredictionRepository stores predictions", .tags(.medium))
    func testPredictionRepository() async throws {
        let repository = InMemoryPredictionRepository()
        let game = createTestGame()
        let prediction = try Prediction(
            game: game,
            homeWinProbability: 0.7,
            confidence: 0.8,
            reasoning: "Test prediction"
        )

        try await repository.save(prediction)

        let retrieved = try await repository.predictions(for: game.id)
        #expect(retrieved.count == 1)
        #expect(retrieved.first?.game.id == game.id)
    }
}

@Suite("Feature: Baseline Predictor")
struct BaselinePredictorTests {
    @Test("Baseline predictor requires historical data", .tags(.medium))
    func testPredictorRequiresData() async throws {
        let repository = InMemoryGameRepository()
        let predictor = BaselinePredictor(gameRepository: repository)

        let game = createTestGame()

        await #expect(throws: PredictionError.self) {
            try await predictor.predict(game: game, features: [:])
        }
    }

    @Test("Baseline predictor uses historical win rates", .tags(.medium))
    func testPredictorUsesWinRates() async throws {
        let homeTeam = Team(name: "Strong Team", abbreviation: "ST", conference: .nfc, division: .west)
        let awayTeam = Team(name: "Weak Team", abbreviation: "WT", conference: .nfc, division: .west)

        // Create historical games where home team wins 80% of games
        var historicalGames: [Game] = []
        let calendar = Calendar.current

        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i - 1, to: Date())!
            let outcome = i < 8
                ? GameOutcome(homeScore: 24, awayScore: 10)
                : GameOutcome(homeScore: 10, awayScore: 24)

            let game = Game(
                homeTeam: homeTeam,
                awayTeam: Team(name: "Other", abbreviation: "OT", conference: .afc, division: .east),
                scheduledDate: date,
                week: i + 1,
                season: 2024,
                outcome: outcome
            )
            historicalGames.append(game)
        }

        // Away team has 20% win rate
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i - 1, to: Date())!
            let outcome = i < 2
                ? GameOutcome(homeScore: 10, awayScore: 24)
                : GameOutcome(homeScore: 24, awayScore: 10)

            let game = Game(
                homeTeam: Team(name: "Other", abbreviation: "OT", conference: .afc, division: .east),
                awayTeam: awayTeam,
                scheduledDate: date,
                week: i + 1,
                season: 2024,
                outcome: outcome
            )
            historicalGames.append(game)
        }

        let repository = InMemoryGameRepository(games: historicalGames)
        let predictor = BaselinePredictor(gameRepository: repository)

        let upcomingGame = Game(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            scheduledDate: Date(),
            week: 11,
            season: 2024
        )

        let prediction = try await predictor.predict(game: upcomingGame, features: [:])

        // Strong home team should be heavily favored
        #expect(prediction.homeWinProbability > 0.5)
        #expect(prediction.confidence > 0.5)
    }
}

@Suite("Feature: Prediction Evaluation")
struct EvaluationTests {
    @Test("Evaluator calculates accuracy correctly", .tags(.medium))
    func testAccuracyCalculation() async throws {
        let evaluator = BasicPredictionEvaluator()
        let predictions = createTestPredictions()

        let metrics = try await evaluator.evaluate(predictions)

        #expect(metrics.totalPredictions == 4)
        #expect(metrics.accuracy >= 0.0)
        #expect(metrics.accuracy <= 1.0)
        #expect(metrics.brierScore >= 0.0)
        #expect(metrics.logLoss >= 0.0)
    }

    @Test("Evaluator handles perfect predictions", .tags(.medium))
    func testPerfectPredictions() async throws {
        let evaluator = BasicPredictionEvaluator()
        let game = createTestGame()

        let prediction = try Prediction(
            game: game,
            homeWinProbability: 1.0,
            confidence: 1.0,
            reasoning: "Perfect"
        )
        let outcome = GameOutcome(homeScore: 24, awayScore: 10)

        let metrics = try await evaluator.evaluate([(prediction, outcome)])

        #expect(metrics.accuracy == 1.0)
    }

    @Test("Evaluator handles empty predictions", .tags(.small))
    func testEmptyEvaluation() async throws {
        let evaluator = BasicPredictionEvaluator()
        let metrics = try await evaluator.evaluate([])

        #expect(metrics.totalPredictions == 0)
        #expect(metrics.accuracy == 0.0)
    }
}

// MARK: - Test Helpers

extension Tag {
    @Tag static var small: Self
    @Tag static var medium: Self
    @Tag static var large: Self
}

func createTestGame() -> Game {
    let homeTeam = Team(name: "Home Team", abbreviation: "HT", conference: .nfc, division: .west)
    let awayTeam = Team(name: "Away Team", abbreviation: "AT", conference: .afc, division: .east)

    return Game(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        scheduledDate: Date(),
        week: 1,
        season: 2024
    )
}

func createTestPredictions() -> [(prediction: Prediction, outcome: GameOutcome)] {
    let games = (0..<4).map { _ in createTestGame() }

    return [
        (try! Prediction(game: games[0], homeWinProbability: 0.7, confidence: 0.8, reasoning: "Test"),
         GameOutcome(homeScore: 24, awayScore: 10)),
        (try! Prediction(game: games[1], homeWinProbability: 0.3, confidence: 0.7, reasoning: "Test"),
         GameOutcome(homeScore: 10, awayScore: 24)),
        (try! Prediction(game: games[2], homeWinProbability: 0.6, confidence: 0.6, reasoning: "Test"),
         GameOutcome(homeScore: 21, awayScore: 20)),
        (try! Prediction(game: games[3], homeWinProbability: 0.4, confidence: 0.5, reasoning: "Test"),
         GameOutcome(homeScore: 14, awayScore: 17)),
    ]
}
