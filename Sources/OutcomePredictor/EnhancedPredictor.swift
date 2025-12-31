import Foundation

/// Enhanced predictor incorporating injuries, news sentiment, head-to-head history, home/away performance, and weather.
///
/// This predictor combines multiple data sources:
/// - Historical win rates (overall and head-to-head)
/// - Home field advantage with team-specific adjustments
/// - Injury impact assessment
/// - News sentiment analysis (player-affecting events)
/// - Home vs away performance splits
/// - Weather conditions impact on game style
public struct EnhancedPredictor: GamePredictor {
    private let gameRepository: GameRepository
    private let injuryTracker: InjuryTracker?
    private let newsAnalyzer: NewsAnalyzer?
    private let weatherService: WeatherService?
    private let homeFieldAdvantage: Double
    private let injuryImpactWeight: Double
    private let newsSentimentWeight: Double
    private let headToHeadWeight: Double
    private let homeAwayWeight: Double
    private let weatherImpactWeight: Double
    private let restTravelWeight: Double
    private let recentFormWeight: Double

    /// Creates an enhanced predictor with configurable weights.
    ///
    /// - Parameters:
    ///   - gameRepository: Repository for historical game data
    ///   - injuryTracker: Optional injury tracking service
    ///   - newsAnalyzer: Optional news sentiment analyzer
    ///   - weatherService: Optional weather forecast service
    ///   - homeFieldAdvantage: Base probability boost for home team (default: 0.06)
    ///   - injuryImpactWeight: Weight for injury impact (default: 0.15)
    ///   - newsSentimentWeight: Weight for news sentiment (default: 0.08)
    ///   - headToHeadWeight: Weight for head-to-head history (default: 0.25)
    ///   - homeAwayWeight: Weight for home/away splits (default: 0.12)
    ///   - weatherImpactWeight: Weight for weather conditions (default: 0.12)
    ///   - restTravelWeight: Weight for rest and travel factors (default: 0.12)
    ///   - recentFormWeight: Weight for momentum and recent form (default: 0.15)
    public init(
        gameRepository: GameRepository,
        injuryTracker: InjuryTracker? = nil,
        newsAnalyzer: NewsAnalyzer? = nil,
        weatherService: WeatherService? = nil,
        homeFieldAdvantage: Double = 0.06,
        injuryImpactWeight: Double = 0.15,
        newsSentimentWeight: Double = 0.08,
        headToHeadWeight: Double = 0.25,
        homeAwayWeight: Double = 0.12,
        weatherImpactWeight: Double = 0.12,
        restTravelWeight: Double = 0.12,
        recentFormWeight: Double = 0.15
    ) {
        self.gameRepository = gameRepository
        self.injuryTracker = injuryTracker
        self.newsAnalyzer = newsAnalyzer
        self.weatherService = weatherService
        self.homeFieldAdvantage = homeFieldAdvantage
        self.injuryImpactWeight = injuryImpactWeight
        self.newsSentimentWeight = newsSentimentWeight
        self.headToHeadWeight = headToHeadWeight
        self.homeAwayWeight = homeAwayWeight
        self.weatherImpactWeight = weatherImpactWeight
        self.restTravelWeight = restTravelWeight
        self.recentFormWeight = recentFormWeight
    }

    public func predict(game: Game, features: [String: Double]) async throws -> Prediction {
        // Fetch historical games for both teams
        let homeGames = try await gameRepository.games(for: game.homeTeam, season: game.season)
        let awayGames = try await gameRepository.games(for: game.awayTeam, season: game.season)

        // Filter completed games
        let completedHomeGames = homeGames.filter { $0.outcome != nil && $0.scheduledDate < game.scheduledDate }
        let completedAwayGames = awayGames.filter { $0.outcome != nil && $0.scheduledDate < game.scheduledDate }

        guard !completedHomeGames.isEmpty || !completedAwayGames.isEmpty else {
            throw PredictionError.insufficientData
        }

        // Calculate base win rates
        let homeWinRate = calculateWinRate(for: game.homeTeam, in: completedHomeGames)
        let awayWinRate = calculateWinRate(for: game.awayTeam, in: completedAwayGames)

        // Calculate head-to-head history
        let headToHeadAdjustment = await calculateHeadToHeadAdjustment(
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            season: game.season
        )

        // Calculate home/away splits
        let homeAwayAdjustment = calculateHomeAwaySplit(
            homeTeam: game.homeTeam,
            homeGames: completedHomeGames,
            awayTeam: game.awayTeam,
            awayGames: completedAwayGames
        )

        // Assess injury impact
        var injuryAdjustment = 0.0
        var injuryDetails = ""
        if let tracker = injuryTracker {
            (injuryAdjustment, injuryDetails) = await assessInjuryImpact(
                homeTeam: game.homeTeam,
                awayTeam: game.awayTeam,
                season: game.season,
                tracker: tracker
            )
        }

        // Analyze news sentiment
        var newsSentimentAdjustment = 0.0
        var newsDetails = ""
        if let analyzer = newsAnalyzer {
            (newsSentimentAdjustment, newsDetails) = await analyzeNewsSentiment(
                homeTeam: game.homeTeam,
                awayTeam: game.awayTeam,
                analyzer: analyzer
            )
        }

        // Analyze weather impact
        var weatherAdjustment = 0.0
        var weatherDetails = ""
        if let service = weatherService {
            (weatherAdjustment, weatherDetails) = await analyzeWeatherImpact(
                homeTeam: game.homeTeam,
                awayTeam: game.awayTeam,
                homeGames: completedHomeGames,
                awayGames: completedAwayGames,
                gameDate: game.scheduledDate,
                service: service
            )
        }

        // Analyze rest and travel
        let restTravelAnalysis = analyzeRestAndTravel(
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            homeGames: completedHomeGames,
            awayGames: completedAwayGames,
            gameDate: game.scheduledDate
        )
        let restTravelAdjustment = restTravelAnalysis.calculateAdvantage()
        let restTravelDetails = restTravelAnalysis.impactSummary

        // Analyze recent form and momentum
        let homeFormAnalysis = analyzeRecentForm(for: game.homeTeam, in: completedHomeGames)
        let awayFormAnalysis = analyzeRecentForm(for: game.awayTeam, in: completedAwayGames)
        let homeFormAdjustment = homeFormAnalysis.calculateMomentum()
        let awayFormAdjustment = awayFormAnalysis.calculateMomentum()
        let recentFormAdjustment = homeFormAdjustment - awayFormAdjustment
        let recentFormDetails = buildFormDetails(home: homeFormAnalysis, away: awayFormAnalysis, homeTeam: game.homeTeam, awayTeam: game.awayTeam)

        // Combine all factors
        var homeWinProbability = (homeWinRate + (1.0 - awayWinRate)) / 2.0
        homeWinProbability += homeFieldAdvantage
        homeWinProbability += headToHeadAdjustment * headToHeadWeight
        homeWinProbability += homeAwayAdjustment * homeAwayWeight
        homeWinProbability += injuryAdjustment * injuryImpactWeight
        homeWinProbability += newsSentimentAdjustment * newsSentimentWeight
        homeWinProbability += weatherAdjustment * weatherImpactWeight
        homeWinProbability += restTravelAdjustment * restTravelWeight
        homeWinProbability += recentFormAdjustment * recentFormWeight

        // Clamp to valid range
        homeWinProbability = max(0.0, min(1.0, homeWinProbability))

        // Calculate confidence
        let confidence = calculateConfidence(
            homeWinProbability: homeWinProbability,
            totalGames: completedHomeGames.count + completedAwayGames.count,
            hasInjuryData: injuryTracker != nil,
            hasNewsData: newsAnalyzer != nil,
            hasWeatherData: weatherService != nil,
            headToHeadGames: await countHeadToHeadGames(homeTeam: game.homeTeam, awayTeam: game.awayTeam, season: game.season)
        )

        // Calculate predicted scores
        let homeAvgScore = calculateAverageScore(for: game.homeTeam, from: completedHomeGames, isHome: true)
        let awayAvgScore = calculateAverageScore(for: game.awayTeam, from: completedAwayGames, isHome: false)

        let scoreDiff = Int((homeWinProbability - 0.5) * 16.0)
        let predictedHomeScore = homeAvgScore + scoreDiff
        let predictedAwayScore = awayAvgScore - scoreDiff

        // Build detailed reasoning
        let reasoning = buildReasoning(
            homeTeam: game.homeTeam,
            awayTeam: game.awayTeam,
            homeWinRate: homeWinRate,
            awayWinRate: awayWinRate,
            homeGamesCount: completedHomeGames.count,
            awayGamesCount: completedAwayGames.count,
            headToHeadAdjustment: headToHeadAdjustment,
            homeAwayAdjustment: homeAwayAdjustment,
            injuryDetails: injuryDetails,
            newsDetails: newsDetails,
            weatherDetails: weatherDetails,
            restTravelDetails: restTravelDetails,
            recentFormDetails: recentFormDetails,
            confidence: confidence
        )

        return try Prediction(
            game: game,
            homeWinProbability: homeWinProbability,
            confidence: confidence,
            predictedHomeScore: predictedHomeScore,
            predictedAwayScore: predictedAwayScore,
            reasoning: reasoning
        )
    }

    // MARK: - Head-to-Head Analysis

    private func calculateHeadToHeadAdjustment(
        homeTeam: Team,
        awayTeam: Team,
        season: Int
    ) async -> Double {
        // Look back 3 seasons for head-to-head matchups
        var headToHeadGames: [Game] = []

        for lookbackSeason in (season - 2)...season {
            do {
                let homeSeasonGames = try await gameRepository.games(for: homeTeam, season: lookbackSeason)
                let h2hGames = homeSeasonGames.filter { game in
                    game.outcome != nil &&
                    ((game.homeTeam.id == homeTeam.id && game.awayTeam.id == awayTeam.id) ||
                     (game.homeTeam.id == awayTeam.id && game.awayTeam.id == homeTeam.id))
                }
                headToHeadGames.append(contentsOf: h2hGames)
            } catch {
                continue
            }
        }

        guard !headToHeadGames.isEmpty else { return 0.0 }

        // Calculate win percentage in head-to-head matchups
        let homeWins = headToHeadGames.filter { game in
            guard let outcome = game.outcome else { return false }
            if game.homeTeam.id == homeTeam.id {
                return outcome.winner == .home
            } else {
                return outcome.winner == .away
            }
        }.count

        let h2hWinRate = Double(homeWins) / Double(headToHeadGames.count)

        // Convert to adjustment (-0.2 to +0.2)
        return (h2hWinRate - 0.5) * 0.4
    }

    private func countHeadToHeadGames(homeTeam: Team, awayTeam: Team, season: Int) async -> Int {
        var count = 0
        for lookbackSeason in (season - 2)...season {
            do {
                let homeSeasonGames = try await gameRepository.games(for: homeTeam, season: lookbackSeason)
                let h2hGames = homeSeasonGames.filter { game in
                    game.outcome != nil &&
                    ((game.homeTeam.id == homeTeam.id && game.awayTeam.id == awayTeam.id) ||
                     (game.homeTeam.id == awayTeam.id && game.awayTeam.id == homeTeam.id))
                }
                count += h2hGames.count
            } catch {
                continue
            }
        }
        return count
    }

    // MARK: - Home/Away Split Analysis

    private func calculateHomeAwaySplit(
        homeTeam: Team,
        homeGames: [Game],
        awayTeam: Team,
        awayGames: [Game]
    ) -> Double {
        // Calculate home team's performance at home
        let homeAtHomeGames = homeGames.filter { $0.homeTeam.id == homeTeam.id }
        let homeAtHomeWinRate = calculateWinRate(for: homeTeam, in: homeAtHomeGames)

        // Calculate away team's performance on the road
        let awayOnRoadGames = awayGames.filter { $0.awayTeam.id == awayTeam.id }
        let awayOnRoadWinRate = calculateWinRate(for: awayTeam, in: awayOnRoadGames)

        // Convert to adjustment
        let homeAdvantage = homeAtHomeWinRate - 0.5
        let awayDisadvantage = 0.5 - awayOnRoadWinRate

        return (homeAdvantage + awayDisadvantage) / 2.0
    }

    // MARK: - Injury Impact Assessment

    private func assessInjuryImpact(
        homeTeam: Team,
        awayTeam: Team,
        season: Int,
        tracker: InjuryTracker
    ) async -> (adjustment: Double, details: String) {
        var homeInjuryImpact = 0.0
        var awayInjuryImpact = 0.0
        var details = ""

        do {
            let homeReport = try await tracker.getInjuries(for: homeTeam, season: season)
            homeInjuryImpact = homeReport.totalImpact

            if !homeReport.keyInjuries.isEmpty {
                let injuryList = homeReport.keyInjuries.map { "\($0.name) (\($0.position.rawValue) - \($0.status.rawValue))" }.joined(separator: ", ")
                details += "\(homeTeam.name) key injuries: \(injuryList). "
            }
        } catch {
            // Silently continue if injury data unavailable
        }

        do {
            let awayReport = try await tracker.getInjuries(for: awayTeam, season: season)
            awayInjuryImpact = awayReport.totalImpact

            if !awayReport.keyInjuries.isEmpty {
                let injuryList = awayReport.keyInjuries.map { "\($0.name) (\($0.position.rawValue) - \($0.status.rawValue))" }.joined(separator: ", ")
                details += "\(awayTeam.name) key injuries: \(injuryList). "
            }
        } catch {
            // Silently continue
        }

        // Positive adjustment favors home team
        let adjustment = awayInjuryImpact - homeInjuryImpact

        return (adjustment, details)
    }

    // MARK: - News Sentiment Analysis

    private func analyzeNewsSentiment(
        homeTeam: Team,
        awayTeam: Team,
        analyzer: NewsAnalyzer
    ) async -> (adjustment: Double, details: String) {
        let homeSentiment = await analyzer.analyzeSentiment(for: homeTeam)
        let awaySentiment = await analyzer.analyzeSentiment(for: awayTeam)

        let adjustment = homeSentiment.impact - awaySentiment.impact

        var details = ""
        if let homeNews = homeSentiment.keyNews {
            details += "\(homeTeam.name): \(homeNews). "
        }
        if let awayNews = awaySentiment.keyNews {
            details += "\(awayTeam.name): \(awayNews). "
        }

        return (adjustment, details)
    }

    // MARK: - Weather Impact Analysis

    private func analyzeWeatherImpact(
        homeTeam: Team,
        awayTeam: Team,
        homeGames: [Game],
        awayGames: [Game],
        gameDate: Date,
        service: WeatherService
    ) async -> (adjustment: Double, details: String) {
        do {
            // Get location from home team
            let location = homeTeam.name.components(separatedBy: " ").last ?? homeTeam.name

            // Fetch weather
            let weather = try await service.fetchWeather(for: location, at: gameDate)

            // Calculate team playing styles (pass vs run ratio)
            let homePassRatio = calculatePassRatio(for: homeTeam, in: homeGames)
            let awayPassRatio = calculatePassRatio(for: awayTeam, in: awayGames)

            // Determine if home team is from a dome
            let homeTeamIsFromDome = isDomeTeam(homeTeam)

            // Calculate weather impact
            let adjustment = weather.calculateWeatherImpact(
                homeTeamPassRatio: homePassRatio,
                awayTeamPassRatio: awayPassRatio,
                homeTeamIsFromDome: homeTeamIsFromDome
            )

            let details = weather.impactSummary

            return (adjustment, details)
        } catch {
            // If weather data unavailable, return no impact
            return (0.0, "")
        }
    }

    private func calculatePassRatio(for team: Team, in games: [Game]) -> Double {
        // Estimate pass ratio from scoring (higher scoring teams tend to pass more)
        // This is a simplification - ideally we'd have play-by-play data
        guard !games.isEmpty else { return 0.55 } // NFL average

        let recentGames = Array(games.suffix(8))
        let totalScore = recentGames.compactMap { game -> Int? in
            guard let outcome = game.outcome else { return nil }
            if game.homeTeam.id == team.id {
                return outcome.homeScore
            } else if game.awayTeam.id == team.id {
                return outcome.awayScore
            }
            return nil
        }.reduce(0, +)

        let avgScore = Double(totalScore) / Double(recentGames.count)

        // Higher scoring teams generally pass more
        // NFL avg is ~24 ppg, ~55% pass ratio
        // Adjust by 1% per point above/below average
        let passRatio = 0.55 + ((avgScore - 24.0) * 0.01)

        return max(0.40, min(0.70, passRatio))
    }

    private func isDomeTeam(_ team: Team) -> Bool {
        // Teams that play in domes/retractable roof stadiums
        let domeTeams = ["Falcons", "Cowboys", "Lions", "Texans", "Colts",
                         "Saints", "Raiders", "Vikings", "Cardinals"]
        return domeTeams.contains { team.name.contains($0) }
    }

    // MARK: - Rest and Travel Analysis

    private func analyzeRestAndTravel(
        homeTeam: Team,
        awayTeam: Team,
        homeGames: [Game],
        awayGames: [Game],
        gameDate: Date
    ) -> RestAndTravelAnalysis {
        // Calculate rest days for each team
        let homeRestDays = calculateRestDays(for: homeTeam, in: homeGames, before: gameDate)
        let awayRestDays = calculateRestDays(for: awayTeam, in: awayGames, before: gameDate)

        // Calculate travel burden for away team
        let travelDistance = calculateTravelDistance(from: awayTeam, to: homeTeam)
        let timeZoneChange = calculateTimeZoneChange(from: awayTeam, to: homeTeam)

        // Count consecutive road games for away team
        let consecutiveRoadGames = countConsecutiveRoadGames(
            for: awayTeam,
            in: awayGames,
            before: gameDate
        )

        // Detect Thursday night game (short week for both teams)
        let isThursday = Calendar.current.component(.weekday, from: gameDate) == 5
        let isThursdayNight = isThursday && (homeRestDays <= 4 || awayRestDays <= 4)

        return RestAndTravelAnalysis(
            homeTeamRestDays: homeRestDays,
            awayTeamRestDays: awayRestDays,
            travelDistance: travelDistance,
            timeZoneChange: timeZoneChange,
            consecutiveRoadGames: consecutiveRoadGames,
            isThursdayNightGame: isThursdayNight
        )
    }

    private func calculateRestDays(for team: Team, in games: [Game], before date: Date) -> Int {
        // Find the most recent completed game before this date
        let previousGames = games.filter { $0.scheduledDate < date && $0.outcome != nil }
        guard let lastGame = previousGames.max(by: { $0.scheduledDate < $1.scheduledDate }) else {
            return 7 // Default to normal week if no previous game found
        }

        let daysBetween = Calendar.current.dateComponents([.day], from: lastGame.scheduledDate, to: date).day ?? 7
        return daysBetween
    }

    private func calculateTravelDistance(from awayTeam: Team, to homeTeam: Team) -> Double {
        guard let awayLocation = NFLStadiums.location(for: awayTeam.name),
              let homeLocation = NFLStadiums.location(for: homeTeam.name) else {
            return 0.0 // Default if stadium not found
        }

        return awayLocation.distance(to: homeLocation)
    }

    private func calculateTimeZoneChange(from awayTeam: Team, to homeTeam: Team) -> Int {
        guard let awayLocation = NFLStadiums.location(for: awayTeam.name),
              let homeLocation = NFLStadiums.location(for: homeTeam.name) else {
            return 0 // Default if stadium not found
        }

        return awayLocation.timeZoneDifference(to: homeLocation)
    }

    private func countConsecutiveRoadGames(
        for team: Team,
        in games: [Game],
        before date: Date
    ) -> Int {
        // Count road games leading up to this one
        let recentGames = games
            .filter { $0.scheduledDate <= date }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .suffix(5) // Look at last 5 games

        var consecutiveCount = 1 // Current game is a road game
        for game in recentGames.reversed().dropFirst() { // Skip current game, go backwards
            if game.awayTeam.id == team.id {
                consecutiveCount += 1
            } else {
                break // Hit a home game, stop counting
            }
        }

        return consecutiveCount
    }

    private func buildFormDetails(
        home: RecentFormAnalysis,
        away: RecentFormAnalysis,
        homeTeam: Team,
        awayTeam: Team
    ) -> String {
        var details: [String] = []

        let homeImpact = home.impactSummary
        if homeImpact != "Stable recent performance" {
            details.append("\(homeTeam.name): \(homeImpact)")
        }

        let awayImpact = away.impactSummary
        if awayImpact != "Stable recent performance" {
            details.append("\(awayTeam.name): \(awayImpact)")
        }

        return details.isEmpty ? "" : details.joined(separator: "; ")
    }

    // MARK: - Helper Methods

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

    private func calculateAverageScore(for team: Team, from games: [Game], isHome: Bool) -> Int {
        // Weight recent games more heavily
        let recentGames = Array(games.suffix(5))
        let scores = recentGames.compactMap { game -> Int? in
            guard let outcome = game.outcome else { return nil }
            if game.homeTeam.id == team.id {
                return outcome.homeScore
            } else if game.awayTeam.id == team.id {
                return outcome.awayScore
            }
            return nil
        }

        guard !scores.isEmpty else { return isHome ? 23 : 20 }
        return scores.reduce(0, +) / scores.count
    }

    private func calculateConfidence(
        homeWinProbability: Double,
        totalGames: Int,
        hasInjuryData: Bool,
        hasNewsData: Bool,
        hasWeatherData: Bool,
        headToHeadGames: Int
    ) -> Double {
        // Sample size factor (0.0 to 0.3)
        let sampleSizeFactor = min(0.3, Double(totalGames) / 50.0)

        // Prediction certainty (0.0 to 0.3)
        let distanceFrom50 = abs(homeWinProbability - 0.5)
        let certaintyFactor = min(0.3, distanceFrom50 * 0.6)

        // Data richness factor (0.0 to 0.25)
        var dataRichness = 0.0
        if hasInjuryData { dataRichness += 0.06 }
        if hasNewsData { dataRichness += 0.05 }
        if hasWeatherData { dataRichness += 0.07 }
        if headToHeadGames > 0 { dataRichness += 0.07 }

        // Head-to-head experience (0.0 to 0.15)
        let h2hFactor = min(0.15, Double(headToHeadGames) / 10.0)

        let confidence = sampleSizeFactor + certaintyFactor + dataRichness + h2hFactor
        return min(1.0, max(0.0, confidence))
    }

    private func buildReasoning(
        homeTeam: Team,
        awayTeam: Team,
        homeWinRate: Double,
        awayWinRate: Double,
        homeGamesCount: Int,
        awayGamesCount: Int,
        headToHeadAdjustment: Double,
        homeAwayAdjustment: Double,
        injuryDetails: String,
        newsDetails: String,
        weatherDetails: String,
        restTravelDetails: String,
        recentFormDetails: String,
        confidence: Double
    ) -> String {
        var reasoning = """
        Enhanced prediction using multiple data sources:

        Overall Performance:
        - \(homeTeam.name): \(String(format: "%.1f%%", homeWinRate * 100)) win rate (\(homeGamesCount) games)
        - \(awayTeam.name): \(String(format: "%.1f%%", awayWinRate * 100)) win rate (\(awayGamesCount) games)

        """

        if abs(headToHeadAdjustment) > 0.01 {
            let advantage = headToHeadAdjustment > 0 ? homeTeam.name : awayTeam.name
            reasoning += "Head-to-Head: \(advantage) has historical advantage in this matchup.\n"
        }

        if abs(homeAwayAdjustment) > 0.01 {
            reasoning += "Home/Away Split: "
            if homeAwayAdjustment > 0 {
                reasoning += "\(homeTeam.name) strong at home, \(awayTeam.name) struggles on road.\n"
            } else {
                reasoning += "\(awayTeam.name) plays well on road despite home disadvantage.\n"
            }
        }

        if !recentFormDetails.isEmpty {
            reasoning += "\nRecent Form & Momentum:\n\(recentFormDetails)\n"
        }

        if !restTravelDetails.isEmpty && restTravelDetails != "Normal rest and travel conditions" {
            reasoning += "\nRest & Travel:\n\(restTravelDetails)\n"
        }

        if !weatherDetails.isEmpty {
            reasoning += "\nWeather Conditions:\n\(weatherDetails)\n"
        }

        if !injuryDetails.isEmpty {
            reasoning += "\nInjury Report:\n\(injuryDetails)\n"
        }

        if !newsDetails.isEmpty {
            reasoning += "\nRecent News Impact:\n\(newsDetails)\n"
        }

        reasoning += "\nPrediction Confidence: \(String(format: "%.1f%%", confidence * 100))"

        return reasoning
    }
}

// MARK: - News Analyzer

/// Analyzes news articles for sentiment and player-affecting events.
public actor NewsAnalyzer {
    private let newsDataSource: NewsDataSource

    public init(newsDataSource: NewsDataSource) {
        self.newsDataSource = newsDataSource
    }

    /// Analyze sentiment for a team based on recent news.
    public func analyzeSentiment(for team: Team) async -> NewsSentiment {
        do {
            let articles = try await newsDataSource.fetchArticles(for: team, before: Date())
            // Limit to 10 most recent articles
            let recentArticles = Array(articles.prefix(10))
            return analyzeArticles(recentArticles, team: team)
        } catch {
            return NewsSentiment(impact: 0.0, keyNews: nil)
        }
    }

    private func analyzeArticles(_ articles: [Article], team: Team) -> NewsSentiment {
        var totalImpact = 0.0
        var keyNews: String?

        // Keywords that indicate negative player-affecting events
        let negativeKeywords = ["injury", "injured", "out", "suspended", "arrest", "arrested",
                                "jail", "divorce", "personal", "leave", "absence", "ruled out"]
        let positiveKeywords = ["return", "healthy", "activated", "cleared", "practice"]

        for article in articles {
            let content = (article.title + " " + article.content).lowercased()

            // Check for negative events
            for keyword in negativeKeywords {
                if content.contains(keyword) {
                    totalImpact -= 0.05
                    if keyNews == nil {
                        keyNews = article.title
                    }
                }
            }

            // Check for positive events
            for keyword in positiveKeywords {
                if content.contains(keyword) {
                    totalImpact += 0.03
                }
            }
        }

        // Clamp impact
        totalImpact = max(-0.15, min(0.10, totalImpact))

        return NewsSentiment(impact: totalImpact, keyNews: keyNews)
    }
}

/// News sentiment result.
public struct NewsSentiment: Sendable {
    public let impact: Double // -0.15 to +0.10
    public let keyNews: String?

    public init(impact: Double, keyNews: String?) {
        self.impact = impact
        self.keyNews = keyNews
    }
}
