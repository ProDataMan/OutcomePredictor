import Foundation
import OutcomePredictor

/// Example demonstrating how to load and use real NFL data.
///
/// Run this example to see how to:
/// 1. Set up data sources with API keys
/// 2. Load historical game data
/// 3. Fetch news and social media content
/// 4. Create prediction context
/// 5. Make predictions with loaded data

@main
struct DataLoadingExample {
    static func main() async {
        print("=== NFL Data Loading Example ===\n")

        do {
            // Example 1: Basic ESPN Data Loading
            print("📊 Example 1: Loading NFL Games from ESPN\n")
            try await example1_LoadGamesFromESPN()

            print("\n" + String(repeating: "=", count: 60) + "\n")

            // Example 2: Complete Prediction with Multiple Sources
            print("🔮 Example 2: Complete Prediction Pipeline\n")
            try await example2_CompletePrediction()

            print("\n" + String(repeating: "=", count: 60) + "\n")

            // Example 3: Caching Demonstration
            print("💾 Example 3: Data Caching\n")
            try await example3_Caching()

        } catch {
            print("❌ Error: \(error)")
        }
    }

    /// Example 1: Load games from ESPN (no API key required)
    static func example1_LoadGamesFromESPN() async throws {
        print("Setting up ESPN data source...")

        // Build data loader with ESPN
        let loader = try DataLoaderBuilder()
            .withESPN()
            .build()

        // Get a team
        guard let chiefs = NFLTeams.team(abbreviation: "KC") else {
            print("Team not found")
            return
        }

        print("Loading games for \(chiefs.name)...\n")

        // Load games for current season
        let games = try await loader.loadGames(for: chiefs, season: 2024)

        print("✅ Loaded \(games.count) games\n")

        // Display first few games
        for game in games.prefix(3) {
            let opponent = game.homeTeam.id == chiefs.id ? game.awayTeam : game.homeTeam
            let location = game.homeTeam.id == chiefs.id ? "vs" : "@"

            if let outcome = game.outcome {
                let teamScore = game.homeTeam.id == chiefs.id ? outcome.homeScore : outcome.awayScore
                let oppScore = game.homeTeam.id == chiefs.id ? outcome.awayScore : outcome.homeScore
                let result = teamScore > oppScore ? "W" : (teamScore < oppScore ? "L" : "T")

                print("  Week \(game.week): \(result) \(location) \(opponent.abbreviation) \(teamScore)-\(oppScore)")
            } else {
                print("  Week \(game.week): \(location) \(opponent.abbreviation) (upcoming)")
            }
        }
    }

    /// Example 2: Complete prediction pipeline with all data sources
    static func example2_CompletePrediction() async throws {
        print("Setting up comprehensive data pipeline...\n")

        // Check for API keys in environment
        let newsAPIKey = ProcessInfo.processInfo.environment["NEWS_API_KEY"]
        let claudeAPIKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"]

        // Build data loader
        var builder = DataLoaderBuilder()
            .withESPN()

        if let newsKey = newsAPIKey, !newsKey.isEmpty {
            builder = builder.withNewsAPI(apiKey: newsKey)
            print("✓ NewsAPI configured")
        } else {
            print("ℹ️  NewsAPI not configured (set NEWS_API_KEY environment variable)")
        }

        let loader = try builder.build()

        // Create upcoming game
        let niners = NFLTeams.team(abbreviation: "SF")!
        let chiefs = NFLTeams.team(abbreviation: "KC")!

        let game = Game(
            homeTeam: niners,
            awayTeam: chiefs,
            scheduledDate: Date().addingTimeInterval(86400 * 3), // 3 days from now
            week: 11,
            season: 2024
        )

        print("\nLoading prediction context for:")
        print("  \(game.awayTeam.name) @ \(game.homeTeam.name)\n")

        // Load complete context
        let context = try await loader.loadPredictionContext(
            for: game,
            lookbackDays: 7
        )

        print("✅ Data loaded:")
        print("  - Historical games: \(context.homeTeamGames.count + context.awayTeamGames.count)")
        print("  - Articles: \(context.homeTeamArticles.count + context.awayTeamArticles.count)")
        print("  - Total data points: \(context.totalDataPoints)\n")

        // Calculate team records
        let homeRecord = calculateRecord(for: game.homeTeam, in: context.homeTeamGames)
        let awayRecord = calculateRecord(for: game.awayTeam, in: context.awayTeamGames)

        print("Team Records:")
        print("  \(game.homeTeam.abbreviation): \(homeRecord.wins)-\(homeRecord.losses)")
        print("  \(game.awayTeam.abbreviation): \(awayRecord.wins)-\(awayRecord.losses)\n")

        // Make prediction with baseline
        let gameRepo = InMemoryGameRepository(games: context.homeTeamGames + context.awayTeamGames)
        let baseline = BaselinePredictor(gameRepository: gameRepo)

        let prediction = try await baseline.predict(game: game, features: [:])

        print("🎯 Baseline Prediction:")
        print("  \(game.homeTeam.abbreviation) win probability: \(String(format: "%.1f%%", prediction.homeWinProbability * 100))")
        print("  Confidence: \(String(format: "%.1f%%", prediction.confidence * 100))")

        // If Claude API key is available, use LLM prediction
        if let claudeKey = claudeAPIKey, !claudeKey.isEmpty {
            print("\n🤖 Generating LLM prediction...")

            let llmClient = ClaudeAPIClient(apiKey: claudeKey)
            let llmPredictor = LLMPredictor(llmClient: llmClient)

            let llmPrediction = try await llmPredictor.predict(context: context)

            print("  \(game.homeTeam.abbreviation) win probability: \(String(format: "%.1f%%", llmPrediction.homeWinProbability * 100))")
            print("  Confidence: \(String(format: "%.1f%%", llmPrediction.confidence * 100))")
        } else {
            print("\nℹ️  Set CLAUDE_API_KEY environment variable to enable LLM predictions")
        }
    }

    /// Example 3: Demonstrate caching behavior
    static func example3_Caching() async throws {
        print("Setting up data loader with caching...\n")

        let loader = try DataLoaderBuilder()
            .withESPN()
            .build()

        let chiefs = NFLTeams.team(abbreviation: "KC")!

        // First load - fetches from API
        print("First load (fetching from ESPN)...")
        let start1 = Date()
        let games1 = try await loader.loadGames(for: chiefs, season: 2024)
        let time1 = Date().timeIntervalSince(start1)
        print("  Loaded \(games1.count) games in \(String(format: "%.3f", time1)) seconds\n")

        // Second load - returns cached data
        print("Second load (from cache)...")
        let start2 = Date()
        let games2 = try await loader.loadGames(for: chiefs, season: 2024)
        let time2 = Date().timeIntervalSince(start2)
        print("  Loaded \(games2.count) games in \(String(format: "%.3f", time2)) seconds")
        print("  ⚡️ \(String(format: "%.0f", time1 / time2))x faster with cache!\n")

        // Force refresh - bypasses cache
        print("Third load (force refresh)...")
        let start3 = Date()
        let games3 = try await loader.loadGames(for: chiefs, season: 2024, forceRefresh: true)
        let time3 = Date().timeIntervalSince(start3)
        print("  Loaded \(games3.count) games in \(String(format: "%.3f", time3)) seconds\n")

        // Clear cache
        await loader.clearCache()
        print("✅ Cache cleared")
    }

    // Helper function
    static func calculateRecord(for team: Team, in games: [Game]) -> (wins: Int, losses: Int) {
        var wins = 0
        var losses = 0

        for game in games where game.outcome != nil {
            let isHome = game.homeTeam.id == team.id
            let outcome = game.outcome!

            if (isHome && outcome.winner == .home) || (!isHome && outcome.winner == .away) {
                wins += 1
            } else if outcome.winner != .tie {
                losses += 1
            }
        }

        return (wins, losses)
    }
}
