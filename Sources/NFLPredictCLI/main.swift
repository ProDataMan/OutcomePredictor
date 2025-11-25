import Foundation
import OutcomePredictor

@main
struct NFLPredictCLI {
    static func main() async {
        print("""
        ╔══════════════════════════════════════════════════════════╗
        ║           NFL Outcome Predictor - CLI Tool              ║
        ║                  Powered by AI                          ║
        ╚══════════════════════════════════════════════════════════╝

        """)

        do {
            try await run()
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    static func run() async throws {
        let args = CommandLine.arguments

        if args.contains("--help") || args.contains("-h") {
            printHelp()
            return
        }

        if args.contains("--demo") {
            try await runDemo()
            return
        }

        if args.contains("--teams") {
            printTeams()
            return
        }

        // Parse command line arguments
        let config = try parseArguments(args)

        // Run prediction
        try await makePrediction(config: config)
    }

    static func printHelp() {
        print("""
        USAGE:
            nfl-predict [OPTIONS]

        OPTIONS:
            --demo              Run demo with sample data
            --teams             List all NFL teams and abbreviations
            --home <TEAM>       Home team abbreviation (e.g., SF, KC, BUF)
            --away <TEAM>       Away team abbreviation
            --week <NUM>        Week number (1-18)
            --season <YEAR>     Season year (default: 2024)
            --predictor <TYPE>  Predictor type: baseline, llm, ensemble (default: ensemble)
            --api-key <KEY>     Anthropic API key for LLM predictions
            --help, -h          Show this help message

        EXAMPLES:
            # Run demo with sample data
            nfl-predict --demo

            # List all teams
            nfl-predict --teams

            # Predict SF vs KC game using ensemble
            nfl-predict --home SF --away KC --week 11

            # Use only baseline predictor
            nfl-predict --home BUF --away MIA --week 12 --predictor baseline

            # Use LLM predictor with API key
            nfl-predict --home DET --away GB --predictor llm --api-key sk-...

        """)
    }

    static func printTeams() {
        print("NFL TEAMS:\n")

        let conferences: [Conference] = [.afc, .nfc]
        let divisions: [Division] = [.east, .north, .south, .west]

        for conference in conferences {
            print("\(conference.rawValue):")
            for division in divisions {
                let teams = NFLTeams.teams(in: conference, division: division)
                print("  \(division.rawValue):")
                for team in teams {
                    print("    [\(team.abbreviation.padding(toLength: 3, withPad: " ", startingAt: 0))] \(team.name)")
                }
            }
            print()
        }
    }

    static func runDemo() async throws {
        print("🎮 Running demo with sample data...\n")

        // Generate sample historical data
        print("📊 Generating sample historical data...")
        let historicalGames = SampleDataGenerator.generateSeason(season: 2024, weeks: 10)
        print("   Generated \(historicalGames.count) games\n")

        // Generate sample upcoming game
        let game = SampleDataGenerator.generateUpcomingGame(week: 11, season: 2024)
        print("🏈 Upcoming Game:")
        printGameInfo(game)

        // Create predictors with sample data
        let gameRepo = InMemoryGameRepository(games: historicalGames)
        let baseline = BaselinePredictor(gameRepository: gameRepo)

        // Generate sample articles
        let articles = SampleDataGenerator.generateArticles(for: [game.homeTeam, game.awayTeam], count: 3)
        print("\n📰 Sample news articles: \(articles.count)")
        for article in articles.prefix(3) {
            print("   - [\(article.source)] \(article.title)")
        }

        // Use mock LLM for demo
        let mockLLM = MockLLMClient()
        let llmPredictor = LLMPredictor(llmClient: mockLLM)

        // Make predictions
        print("\n🔮 Making predictions...\n")

        print("───────────────────────────────────────────────────────")
        print("Baseline Predictor (Historical Win Rates):")
        print("───────────────────────────────────────────────────────")
        let baselinePred = try await baseline.predict(game: game, features: [:])
        printPrediction(baselinePred)

        print("\n───────────────────────────────────────────────────────")
        print("LLM Predictor (AI Analysis):")
        print("───────────────────────────────────────────────────────")
        let llmPred = try await llmPredictor.predict(game: game, features: [:])
        printPrediction(llmPred)

        print("\n───────────────────────────────────────────────────────")
        print("Ensemble Predictor (Combined):")
        print("───────────────────────────────────────────────────────")
        let ensemble = EnsemblePredictor.standard(baseline: baseline, llm: llmPredictor)
        let ensemblePred = try await ensemble.predict(game: game, features: [:])
        printPrediction(ensemblePred)

        print("\n✅ Demo complete!")
    }

    static func makePrediction(config: PredictionConfig) async throws {
        // Find teams
        guard let homeTeam = NFLTeams.team(abbreviation: config.homeTeam) else {
            throw CLIError.invalidTeam(config.homeTeam)
        }
        guard let awayTeam = NFLTeams.team(abbreviation: config.awayTeam) else {
            throw CLIError.invalidTeam(config.awayTeam)
        }

        let calendar = Calendar.current
        let gameDate = calendar.date(byAdding: .day, value: 3, to: Date())!

        let game = Game(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            scheduledDate: gameDate,
            week: config.week,
            season: config.season
        )

        print("🏈 Game:")
        printGameInfo(game)

        // Create predictor based on type
        print("\n🔮 Making prediction using \(config.predictorType) predictor...\n")

        let prediction: Prediction

        switch config.predictorType {
        case "baseline":
            let gameRepo = InMemoryGameRepository()
            let predictor = BaselinePredictor(gameRepository: gameRepo)
            prediction = try await predictor.predict(game: game, features: [:])

        case "llm":
            guard let apiKey = config.apiKey else {
                throw CLIError.missingAPIKey
            }
            let client = ClaudeAPIClient(apiKey: apiKey)
            let predictor = LLMPredictor(llmClient: client)
            prediction = try await predictor.predict(game: game, features: [:])

        case "ensemble":
            let gameRepo = InMemoryGameRepository()
            let baseline = BaselinePredictor(gameRepository: gameRepo)

            let llmClient: LLMClient
            if let apiKey = config.apiKey {
                llmClient = ClaudeAPIClient(apiKey: apiKey)
            } else {
                print("ℹ️  No API key provided, using mock LLM for demo\n")
                llmClient = MockLLMClient()
            }

            let llm = LLMPredictor(llmClient: llmClient)
            let ensemble = EnsemblePredictor.standard(baseline: baseline, llm: llm)
            prediction = try await ensemble.predict(game: game, features: [:])

        default:
            throw CLIError.invalidPredictorType(config.predictorType)
        }

        printPrediction(prediction)
    }

    static func printGameInfo(_ game: Game) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        print("""
           Away: \(game.awayTeam.name) (\(game.awayTeam.abbreviation))
             at
           Home: \(game.homeTeam.name) (\(game.homeTeam.abbreviation))

           Week: \(game.week), Season: \(game.season)
           Date: \(formatter.string(from: game.scheduledDate))
        """)
    }

    static func printPrediction(_ prediction: Prediction) {
        let homeProb = prediction.homeWinProbability * 100
        let awayProb = prediction.awayWinProbability * 100
        let confidence = prediction.confidence * 100

        let winner = prediction.predictedWinner == .home
            ? prediction.game.homeTeam.name
            : (prediction.predictedWinner == .away ? prediction.game.awayTeam.name : "TIE")

        print("""
        📊 PREDICTION:
           Predicted Winner: \(winner)

           Win Probabilities:
           - \(prediction.game.homeTeam.abbreviation) (Home): \(String(format: "%.1f%%", homeProb))
           - \(prediction.game.awayTeam.abbreviation) (Away): \(String(format: "%.1f%%", awayProb))

           Confidence: \(String(format: "%.1f%%", confidence))

        💭 Reasoning:
        \(prediction.reasoning)
        """)
    }

    static func parseArguments(_ args: [String]) throws -> PredictionConfig {
        var config = PredictionConfig()

        var i = 1
        while i < args.count {
            let arg = args[i]

            switch arg {
            case "--home":
                guard i + 1 < args.count else { throw CLIError.missingValue(arg) }
                config.homeTeam = args[i + 1]
                i += 2
            case "--away":
                guard i + 1 < args.count else { throw CLIError.missingValue(arg) }
                config.awayTeam = args[i + 1]
                i += 2
            case "--week":
                guard i + 1 < args.count else { throw CLIError.missingValue(arg) }
                guard let week = Int(args[i + 1]) else { throw CLIError.invalidValue(arg, args[i + 1]) }
                config.week = week
                i += 2
            case "--season":
                guard i + 1 < args.count else { throw CLIError.missingValue(arg) }
                guard let season = Int(args[i + 1]) else { throw CLIError.invalidValue(arg, args[i + 1]) }
                config.season = season
                i += 2
            case "--predictor":
                guard i + 1 < args.count else { throw CLIError.missingValue(arg) }
                config.predictorType = args[i + 1]
                i += 2
            case "--api-key":
                guard i + 1 < args.count else { throw CLIError.missingValue(arg) }
                config.apiKey = args[i + 1]
                i += 2
            default:
                i += 1
            }
        }

        // Validate required arguments
        if config.homeTeam.isEmpty {
            throw CLIError.missingArgument("--home")
        }
        if config.awayTeam.isEmpty {
            throw CLIError.missingArgument("--away")
        }

        return config
    }
}

struct PredictionConfig {
    var homeTeam: String = ""
    var awayTeam: String = ""
    var week: Int = 11
    var season: Int = 2024
    var predictorType: String = "ensemble"
    var apiKey: String? = nil
}

enum CLIError: Error, LocalizedError {
    case missingArgument(String)
    case missingValue(String)
    case invalidValue(String, String)
    case invalidTeam(String)
    case invalidPredictorType(String)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .missingArgument(let arg):
            return "Missing required argument: \(arg)"
        case .missingValue(let arg):
            return "Missing value for argument: \(arg)"
        case .invalidValue(let arg, let value):
            return "Invalid value '\(value)' for argument: \(arg)"
        case .invalidTeam(let team):
            return "Invalid team abbreviation: \(team). Use --teams to see valid abbreviations."
        case .invalidPredictorType(let type):
            return "Invalid predictor type: \(type). Valid types: baseline, llm, ensemble"
        case .missingAPIKey:
            return "API key required for LLM predictor. Use --api-key to provide Anthropic API key."
        }
    }
}
