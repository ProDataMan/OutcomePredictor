import Foundation
import OutcomePredictor

/// Fetch real NFL data using free sources (ESPN)
@main
struct FetchRealData {
    static func main() async {
        print("""
        ╔══════════════════════════════════════════════════════════╗
        ║        Fetching Real NFL Data (Free Sources)            ║
        ╚══════════════════════════════════════════════════════════╝

        """)

        do {
            try await fetchESPNData()
        } catch {
            print("❌ Error: \(error)")
            if let dataError = error as? DataSourceError {
                print("\nDetails: \(dataError.errorDescription ?? "Unknown error")")
            }
        }
    }

    static func fetchESPNData() async throws {
        print("📡 Setting up ESPN data source (no API key required)...\n")

        let espn = ESPNDataSource()

        // Determine current NFL season
        // NFL regular season: September - January (named for the starting year)
        // Playoffs/Super Bowl: January - February (still uses starting year)
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        // January-February: previous year's playoffs/Super Bowl
        // March-August: offseason, use previous completed season
        // September-December: current year's regular season
        let detectedSeason = currentMonth <= 2 ? currentYear - 1 :
                            currentMonth < 9 ? currentYear - 1 : currentYear

        print("📅 Current date: \(now)")
        print("📅 Detected NFL season: \(detectedSeason)\n")

        // Try current season first
        print("🏈 Fetching current week's scores (season \(detectedSeason))...\n")
        let liveGames = try await espn.fetchLiveScores()

        // If no games found, try previous season as fallback
        var workingSeason = detectedSeason
        if liveGames.isEmpty {
            print("ℹ️  No games in \(detectedSeason) season, trying \(detectedSeason - 1)...\n")
            workingSeason = detectedSeason - 1
            // We'll fetch specific week data below
        } else {
            print("✅ Found \(liveGames.count) games in current week\n")
            displayGames(liveGames)
        }

        if liveGames.isEmpty {
            print("ℹ️  No games found in current week. Trying specific week data...\n")
        }

        // Try fetching specific week data
        print(String(repeating: "=", count: 60))
        print("\n📅 Fetching Week 13, \(workingSeason) data...\n")

        do {
            let week13Games = try await espn.fetchGames(week: 13, season: workingSeason)

            if week13Games.isEmpty {
                print("ℹ️  No games found for Week 13, \(workingSeason)")
            } else {
                print("✅ Found \(week13Games.count) games for Week 13, \(workingSeason):\n")
                displayGames(week13Games)
            }
        } catch {
            print("⚠️  Could not fetch Week 13 data: \(error)")
        }

        // Fetch games for specific teams
        print("\n" + String(repeating: "=", count: 60))
        print("\n🏆 Fetching team-specific data...\n")

        let teamsToFetch = [
            NFLTeams.team(abbreviation: "KC")!,  // Chiefs
            NFLTeams.team(abbreviation: "SF")!,  // 49ers
            NFLTeams.team(abbreviation: "BUF")!, // Bills
        ]

        for team in teamsToFetch {
            print("Loading \(team.name) \(workingSeason) season data...")

            do {
                let teamGames = try await espn.fetchGames(for: team, season: workingSeason)

                if teamGames.isEmpty {
                    print("  ⚠️  No games found")
                } else {
                    print("  ✅ Found \(teamGames.count) games")

                    // Calculate record
                    let record = calculateRecord(for: team, in: teamGames)
                    print("  📊 Record: \(record.wins)-\(record.losses)\(record.ties > 0 ? "-\(record.ties)" : "")")

                    // Show last 3 games
                    let recentGames = teamGames
                        .filter { $0.outcome != nil }
                        .sorted { $0.scheduledDate > $1.scheduledDate }
                        .prefix(3)

                    if !recentGames.isEmpty {
                        print("  Recent games:")
                        for game in recentGames {
                            let opponent = game.homeTeam.id == team.id ? game.awayTeam : game.homeTeam
                            let location = game.homeTeam.id == team.id ? "vs" : "@"
                            let outcome = game.outcome!
                            let teamScore = game.homeTeam.id == team.id ? outcome.homeScore : outcome.awayScore
                            let oppScore = game.homeTeam.id == team.id ? outcome.awayScore : outcome.homeScore
                            let result = teamScore > oppScore ? "W" : (teamScore < oppScore ? "L" : "T")

                            print("    \(result) \(location) \(opponent.abbreviation) \(teamScore)-\(oppScore)")
                        }
                    }
                }
                print()

                // Small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            } catch {
                print("  ❌ Error: \(error)")
                print()
            }
        }

        // Now test with DataLoader and caching
        print(String(repeating: "=", count: 60))
        print("\n💾 Testing DataLoader with caching...\n")

        // Check for NewsAPI key in environment
        let newsAPIKey = ProcessInfo.processInfo.environment["NEWS_API_KEY"] ?? "168084c7268f48b48f2e4eec0ddca9cd"

        let loader = try DataLoaderBuilder()
            .withESPN()
            .withNewsAPI(apiKey: newsAPIKey)
            .build()

        let chiefs = NFLTeams.team(abbreviation: "KC")!

        print("First fetch (from ESPN API)...")
        let start1 = Date()
        let games1 = try await loader.loadGames(for: chiefs, season: workingSeason)
        let time1 = Date().timeIntervalSince(start1)
        print("  ✅ Loaded \(games1.count) games in \(String(format: "%.3f", time1))s\n")

        print("Second fetch (from cache)...")
        let start2 = Date()
        let games2 = try await loader.loadGames(for: chiefs, season: workingSeason)
        let time2 = Date().timeIntervalSince(start2)
        print("  ✅ Loaded \(games2.count) games in \(String(format: "%.3f", time2))s")

        if time1 > 0 && time2 > 0 {
            print("  ⚡️ Cache is \(String(format: "%.0f", time1 / time2))x faster!\n")
        }

        // Create a prediction using real data
        if games1.count >= 2 {
            print(String(repeating: "=", count: 60))
            print("\n🔮 Making prediction with real data...\n")

            // Find two teams with data
            let gameRepo = InMemoryGameRepository(games: games1)
            let baseline = BaselinePredictor(gameRepository: gameRepo)

            // Create hypothetical upcoming game
            let upcomingGame = Game(
                homeTeam: chiefs,
                awayTeam: NFLTeams.team(abbreviation: "BUF")!,
                scheduledDate: Date().addingTimeInterval(86400 * 7), // Next week
                week: 13,
                season: workingSeason
            )

            let prediction = try await baseline.predict(game: upcomingGame, features: [:])

            // Format the game date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .short
            let gameDate = dateFormatter.string(from: upcomingGame.scheduledDate)

            // Extract city from home team name
            // Team names follow pattern: "City Name TeamName" or "City TeamName"
            // Special cases: "San Francisco 49ers", "Tampa Bay Buccaneers", "Los Angeles Rams/Chargers", "New York Giants/Jets", "New England Patriots", "Green Bay Packers"
            let cityMap: [String: String] = [
                "SF": "San Francisco",
                "TB": "Tampa Bay",
                "LAR": "Los Angeles",
                "LAC": "Los Angeles",
                "NYG": "New York",
                "NYJ": "New York",
                "NE": "New England",
                "GB": "Green Bay",
                "KC": "Kansas City",
                "NO": "New Orleans"
            ]

            let homeCity = cityMap[upcomingGame.homeTeam.abbreviation] ??
                           upcomingGame.homeTeam.name.components(separatedBy: " ").dropLast().joined(separator: " ")

            print("🏈 \(upcomingGame.awayTeam.name) @ \(upcomingGame.homeTeam.name)")
            print("")
            print("📅 Date:     \(gameDate)")
            print("📍 Location: \(homeCity)")
            print("📊 Week \(upcomingGame.week), \(upcomingGame.season) Season")
            print("")

            // Mock Vegas odds for demonstration (in real use, fetch from The Odds API)
            let mockHomeMoneyline = -155  // Chiefs favored
            let mockAwayMoneyline = +135  // Bills underdog
            let mockSpread = -3.5         // Chiefs -3.5

            let vegasHomeProbImplied = BettingOdds.oddsToProbability(mockHomeMoneyline)
            let vegasAwayProbImplied = BettingOdds.oddsToProbability(mockAwayMoneyline)

            // Display side-by-side comparison
            print(String(repeating: "-", count: 60))
            print(String(format: "%-30s %12s %12s", "", "Our Model", "Vegas Odds"))
            print(String(repeating: "-", count: 60))
            print(String(format: "%-30s %11.1f%% %11.1f%%",
                         "Home Win (\(upcomingGame.homeTeam.abbreviation))",
                         prediction.homeWinProbability * 100,
                         vegasHomeProbImplied * 100))
            print(String(format: "%-30s %11.1f%% %11.1f%%",
                         "Away Win (\(upcomingGame.awayTeam.abbreviation))",
                         prediction.awayWinProbability * 100,
                         vegasAwayProbImplied * 100))
            print(String(repeating: "-", count: 60))
            print(String(format: "%-30s %12s %12s",
                         "Spread",
                         "N/A",
                         String(format: "%.1f", mockSpread)))
            print(String(format: "%-30s %12s %12s",
                         "Confidence",
                         String(format: "%.1f%%", prediction.confidence * 100),
                         "N/A"))
            print(String(repeating: "-", count: 60))
            print("")
            print("💡 Note: Vegas odds are mocked for demonstration")
            print("   To fetch real odds, get a free API key from https://the-odds-api.com/")
            print("")
            print("Reasoning:")
            for line in prediction.reasoning.split(separator: "\n") {
                print("  \(line)")
            }
            print("")
            print("⚠️  NOTE: The baseline predictor currently uses ONLY historical win rates.")
            print("   News articles are being fetched but not yet incorporated into predictions.")
            print("   Future versions will include sentiment analysis from news/social media.")
        }

        // Fetch recent news articles
        print("\n" + String(repeating: "=", count: 60))
        print("\n📰 Fetching recent news articles...\n")

        let newsTeams = [
            NFLTeams.team(abbreviation: "KC")!,  // Chiefs
            NFLTeams.team(abbreviation: "BUF")!, // Bills
        ]

        for team in newsTeams {
            print("📰 \(team.name) news:")

            do {
                // Fetch articles from the last 7 days
                let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let articles = try await loader.loadArticles(
                    for: team,
                    before: Date(),
                    after: sevenDaysAgo
                )

                if articles.isEmpty {
                    print("  ℹ️  No recent articles found\n")
                } else {
                    for article in articles.prefix(3) {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .short
                        let dateStr = dateFormatter.string(from: article.publishedDate)

                        print("  • \(article.title)")
                        print("    \(article.source) - \(dateStr)")
                    }
                    print("  ✅ Found \(articles.count) total articles\n")
                }

                // Small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            } catch {
                print("  ⚠️  Could not fetch news: \(error)\n")
            }
        }

        print("\n✅ Data fetching complete!")
        print("\nNext steps:")
        print("  1. Data is now cached for 1 hour")
        print("  2. NewsAPI integrated (100 requests/day limit)")
        print("  3. To add Reddit: Register app at https://reddit.com/prefs/apps")
        print("  4. Set environment variables and rebuild")
    }

    static func displayGames(_ games: [Game]) {
        for game in games.prefix(10) {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short

            let dateStr = formatter.string(from: game.scheduledDate)

            if let outcome = game.outcome {
                let status = outcome.winner == .home ? "✓" : (outcome.winner == .away ? "✗" : "↔")
                print("  [\(status)] \(game.awayTeam.abbreviation) @ \(game.homeTeam.abbreviation): \(outcome.awayScore)-\(outcome.homeScore) (\(dateStr))")
            } else {
                print("  [ ] \(game.awayTeam.abbreviation) @ \(game.homeTeam.abbreviation) (Scheduled: \(dateStr))")
            }
        }

        if games.count > 10 {
            print("  ... and \(games.count - 10) more games")
        }
    }

    static func calculateRecord(for team: Team, in games: [Game]) -> (wins: Int, losses: Int, ties: Int) {
        var wins = 0
        var losses = 0
        var ties = 0

        for game in games where game.outcome != nil {
            let isHome = game.homeTeam.id == team.id
            let outcome = game.outcome!

            switch outcome.winner {
            case .home where isHome, .away where !isHome:
                wins += 1
            case .home where !isHome, .away where isHome:
                losses += 1
            case .tie:
                ties += 1
            default:
                break
            }
        }

        return (wins, losses, ties)
    }
}
