import Foundation

/// Mock implementations for testing and development.

/// Mock NFL data source with sample data.
public struct MockNFLDataSource: NFLDataSource {
    private let games: [Game]

    /// Creates a mock NFL data source.
    ///
    /// - Parameter games: Pre-populated games to return.
    public init(games: [Game] = []) {
        self.games = games
    }

    public func fetchGames(week: Int, season: Int) async throws -> [Game] {
        games.filter { $0.week == week && $0.season == season }
    }

    public func fetchGames(for team: Team, season: Int) async throws -> [Game] {
        games.filter { game in
            game.season == season && (game.homeTeam.id == team.id || game.awayTeam.id == team.id)
        }
    }

    public func fetchLiveScores() async throws -> [Game] {
        []
    }
}

/// Mock news data source.
public struct MockNewsDataSource: NewsDataSource {
    private let articles: [Article]

    /// Creates a mock news data source.
    ///
    /// - Parameter articles: Pre-populated articles to return.
    public init(articles: [Article] = []) {
        self.articles = articles
    }

    public func fetchArticles(for team: Team, before date: Date) async throws -> [Article] {
        articles.filter { article in
            article.publishedDate < date && article.teams.contains(where: { $0.id == team.id })
        }
    }
}

/// Mock X/Twitter data source.
public struct MockXDataSource: XDataSource {
    private let tweets: [Article]

    /// Creates a mock X data source.
    ///
    /// - Parameter tweets: Pre-populated tweets to return.
    public init(tweets: [Article] = []) {
        self.tweets = tweets
    }

    public func fetchTweets(about team: Team, limit: Int, before date: Date) async throws -> [Article] {
        Array(tweets.filter { article in
            article.publishedDate < date && article.teams.contains(where: { $0.id == team.id })
        }.prefix(limit))
    }

    public func fetchTweets(from usernames: [String], limit: Int) async throws -> [Article] {
        Array(tweets.prefix(limit))
    }
}

/// Mock Reddit data source.
public struct MockRedditDataSource: RedditDataSource {
    private let posts: [Article]

    /// Creates a mock Reddit data source.
    ///
    /// - Parameter posts: Pre-populated posts to return.
    public init(posts: [Article] = []) {
        self.posts = posts
    }

    public func fetchPosts(about team: Team, limit: Int, before date: Date) async throws -> [Article] {
        Array(posts.filter { article in
            article.publishedDate < date && article.teams.contains(where: { $0.id == team.id })
        }.prefix(limit))
    }

    public func fetchPosts(from subreddits: [String], limit: Int) async throws -> [Article] {
        Array(posts.prefix(limit))
    }
}

/// Mock LLM client that returns deterministic predictions.
public struct MockLLMClient: LLMClient {
    private let response: LLMResponse

    /// Creates a mock LLM client.
    ///
    /// - Parameter response: Response to return for all predictions.
    public init(response: LLMResponse? = nil) {
        self.response = response ?? LLMResponse(
            homeWinProbability: 0.6,
            confidence: 0.7,
            reasoning: "Mock prediction based on test data.",
            keyFactors: ["Home field advantage", "Recent performance", "Injury reports"]
        )
    }

    public func generatePrediction(prompt: String) async throws -> LLMResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return response
    }
}

/// Generates sample historical data for testing.
public struct SampleDataGenerator {
    /// Creates a full season of games with realistic outcomes.
    ///
    /// - Parameters:
    ///   - season: Season year.
    ///   - weeks: Number of weeks to generate (default: 10).
    /// - Returns: Array of games with outcomes.
    public static func generateSeason(season: Int = 2024, weeks: Int = 10) -> [Game] {
        var games: [Game] = []
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: season, month: 9, day: 8))!

        let teams = NFLTeams.allTeams
        var teamIndex = 0

        for week in 1...weeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: week - 1, to: startDate)!

            // Create matchups for this week (8 games per week for simplicity)
            for gameNum in 0..<8 {
                guard teamIndex + 1 < teams.count else { break }

                let homeTeam = teams[teamIndex]
                let awayTeam = teams[teamIndex + 1]
                teamIndex = (teamIndex + 2) % teams.count

                let gameDate = calendar.date(byAdding: .day, value: gameNum, to: weekStart)!

                // Generate realistic score
                let homeScore = Int.random(in: 10...35)
                let awayScore = Int.random(in: 10...35)
                let outcome = GameOutcome(homeScore: homeScore, awayScore: awayScore)

                let game = Game(
                    homeTeam: homeTeam,
                    awayTeam: awayTeam,
                    scheduledDate: gameDate,
                    week: week,
                    season: season,
                    outcome: outcome
                )

                games.append(game)
            }
        }

        return games
    }

    /// Generates sample news articles about teams.
    ///
    /// - Parameters:
    ///   - teams: Teams to generate articles about.
    ///   - count: Number of articles per team.
    /// - Returns: Array of sample articles.
    public static func generateArticles(for teams: [Team], count: Int = 5) -> [Article] {
        let templates = [
            "breaks out in practice this week",
            "injury report shows positive signs",
            "coach discusses game plan",
            "defense prepares for tough matchup",
            "offense looking sharp ahead of game",
            "key player questionable for Sunday",
            "fans excited about playoff chances",
            "analysts predict strong performance"
        ]

        var articles: [Article] = []
        let calendar = Calendar.current

        for team in teams {
            for _ in 0..<count {
                let template = templates.randomElement()!
                let daysAgo = Int.random(in: 1...7)
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!

                let article = Article(
                    title: "\(team.name) \(template)",
                    content: "Sample content about \(team.name).",
                    publishedDate: date,
                    source: ["ESPN", "NFL.com", "Twitter", "Reddit"].randomElement()!,
                    teams: [team]
                )

                articles.append(article)
            }
        }

        return articles
    }

    /// Generates a sample upcoming game.
    ///
    /// - Parameters:
    ///   - homeTeam: Home team (random if nil).
    ///   - awayTeam: Away team (random if nil).
    ///   - week: Week number.
    ///   - season: Season year.
    /// - Returns: Sample game without outcome.
    public static func generateUpcomingGame(
        homeTeam: Team? = nil,
        awayTeam: Team? = nil,
        week: Int = 11,
        season: Int = 2024
    ) -> Game {
        let home = homeTeam ?? NFLTeams.allTeams.randomElement()!
        var away = awayTeam ?? NFLTeams.allTeams.randomElement()!

        // Ensure different teams
        while away.id == home.id {
            away = NFLTeams.allTeams.randomElement()!
        }

        let calendar = Calendar.current
        let gameDate = calendar.date(byAdding: .day, value: 3, to: Date())!

        return Game(
            homeTeam: home,
            awayTeam: away,
            scheduledDate: gameDate,
            week: week,
            season: season
        )
    }
}
