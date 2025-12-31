import Foundation

/// Recent form and momentum analysis for teams.
///
/// Analyzes a team's recent performance to identify trends:
/// - Win/loss streaks
/// - Scoring trends
/// - Performance consistency
/// - Clutch wins vs blowout losses
public struct RecentFormAnalysis: Sendable, Codable {
    /// Last 3 games win rate
    public let last3GamesWinRate: Double

    /// Average score differential in last 3 games
    public let last3GamesScoreDifferential: Double

    /// Trend direction based on performance progression
    public let trendDirection: TrendDirection

    /// Number of blowout losses (14+ points) in last 5 games
    public let blowoutLosses: Int

    /// Number of clutch wins (7 or less points) in last 5 games
    public let clutchWins: Int

    /// Current win/loss streak (positive = wins, negative = losses)
    public let currentStreak: Int

    /// Scoring trend (points per game, recent vs earlier in season)
    public let scoringTrend: Double  // Positive = improving offense

    public init(
        last3GamesWinRate: Double,
        last3GamesScoreDifferential: Double,
        trendDirection: TrendDirection,
        blowoutLosses: Int,
        clutchWins: Int,
        currentStreak: Int,
        scoringTrend: Double
    ) {
        self.last3GamesWinRate = last3GamesWinRate
        self.last3GamesScoreDifferential = last3GamesScoreDifferential
        self.trendDirection = trendDirection
        self.blowoutLosses = blowoutLosses
        self.clutchWins = clutchWins
        self.currentStreak = currentStreak
        self.scoringTrend = scoringTrend
    }

    /// Calculate momentum adjustment.
    ///
    /// Positive values indicate improving team (hot), negative indicate declining (cold).
    /// Returns adjustment between -0.15 and +0.15.
    public func calculateMomentum() -> Double {
        var momentum = 0.0

        // Recent win rate heavily weighted
        momentum += (last3GamesWinRate - 0.5) * 0.20

        // Score differential in recent games
        let normalizedScoreDiff = last3GamesScoreDifferential / 14.0 // Normalize to typical win margin
        momentum += normalizedScoreDiff * 0.08

        // Trend direction
        switch trendDirection {
        case .stronglyImproving:
            momentum += 0.08
        case .improving:
            momentum += 0.04
        case .stable:
            break
        case .declining:
            momentum -= 0.04
        case .stronglyDeclining:
            momentum -= 0.08
        }

        // Winning streak bonus
        if currentStreak >= 3 {
            momentum += 0.06 // Hot team
        } else if currentStreak >= 2 {
            momentum += 0.03
        } else if currentStreak <= -3 {
            momentum -= 0.06 // Cold team
        } else if currentStreak <= -2 {
            momentum -= 0.03
        }

        // Blowout losses indicate major problems
        if blowoutLosses >= 2 {
            momentum -= 0.05
        } else if blowoutLosses == 1 {
            momentum -= 0.02
        }

        // Clutch wins show resilience
        if clutchWins >= 2 {
            momentum += 0.03
        }

        // Scoring trend
        momentum += scoringTrend * 0.04

        // Clamp to reasonable range
        return max(-0.15, min(0.15, momentum))
    }

    /// Human-readable summary of recent form.
    public var impactSummary: String {
        var factors: [String] = []

        // Trend
        switch trendDirection {
        case .stronglyImproving:
            factors.append("strongly improving (\(Int(last3GamesWinRate * 100))% in last 3)")
        case .improving:
            factors.append("improving (\(Int(last3GamesWinRate * 100))% in last 3)")
        case .declining:
            factors.append("declining (\(Int(last3GamesWinRate * 100))% in last 3)")
        case .stronglyDeclining:
            factors.append("strongly declining (\(Int(last3GamesWinRate * 100))% in last 3)")
        case .stable:
            break
        }

        // Streak
        if currentStreak >= 3 {
            factors.append("\(currentStreak)-game win streak")
        } else if currentStreak >= 2 {
            factors.append("\(currentStreak)-game win streak")
        } else if currentStreak <= -3 {
            factors.append("\(abs(currentStreak))-game losing streak")
        } else if currentStreak <= -2 {
            factors.append("\(abs(currentStreak))-game losing streak")
        }

        // Score differential
        if last3GamesScoreDifferential > 10 {
            factors.append("dominant wins (+\(Int(last3GamesScoreDifferential)) avg margin)")
        } else if last3GamesScoreDifferential < -10 {
            factors.append("struggling (\(Int(last3GamesScoreDifferential)) avg margin)")
        }

        // Blowouts/clutch
        if blowoutLosses >= 2 {
            factors.append("\(blowoutLosses) blowout losses in last 5")
        }
        if clutchWins >= 2 {
            factors.append("\(clutchWins) clutch wins in last 5")
        }

        if factors.isEmpty {
            return "Stable recent performance"
        }

        return factors.joined(separator: "; ")
    }
}

/// Trend direction enum.
public enum TrendDirection: String, Sendable, Codable {
    case stronglyImproving  // Getting much better
    case improving          // Getting better
    case stable             // Consistent
    case declining          // Getting worse
    case stronglyDeclining  // Getting much worse
}

/// Calculate recent form from game history.
public func analyzeRecentForm(for team: Team, in games: [Game]) -> RecentFormAnalysis {
    let completedGames = games
        .filter { $0.outcome != nil }
        .sorted { $0.scheduledDate < $1.scheduledDate }

    guard !completedGames.isEmpty else {
        return RecentFormAnalysis(
            last3GamesWinRate: 0.5,
            last3GamesScoreDifferential: 0.0,
            trendDirection: .stable,
            blowoutLosses: 0,
            clutchWins: 0,
            currentStreak: 0,
            scoringTrend: 0.0
        )
    }

    // Last 3 games
    let last3 = Array(completedGames.suffix(3))
    let last3Wins = last3.filter { isWin(game: $0, team: team) }.count
    let last3WinRate = Double(last3Wins) / Double(last3.count)

    // Score differential in last 3
    let last3ScoreDiffs = last3.compactMap { scoreDifferential(game: $0, team: team) }
    let avgScoreDiff = last3ScoreDiffs.isEmpty ? 0.0 : Double(last3ScoreDiffs.reduce(0, +)) / Double(last3ScoreDiffs.count)

    // Last 5 games for blowouts/clutch
    let last5 = Array(completedGames.suffix(5))
    let blowoutLosses = last5.filter { game in
        if let diff = scoreDifferential(game: game, team: team) {
            return diff <= -14
        }
        return false
    }.count

    let clutchWins = last5.filter { game in
        if let diff = scoreDifferential(game: game, team: team) {
            return diff > 0 && diff <= 7
        }
        return false
    }.count

    // Current streak
    let streak = calculateStreak(games: completedGames, team: team)

    // Scoring trend (recent 4 games vs earlier games)
    let scoringTrend = calculateScoringTrend(games: completedGames, team: team)

    // Determine trend direction
    let trendDirection = determineTrend(
        last3WinRate: last3WinRate,
        overallWinRate: calculateOverallWinRate(games: completedGames, team: team),
        streak: streak,
        scoringTrend: scoringTrend
    )

    return RecentFormAnalysis(
        last3GamesWinRate: last3WinRate,
        last3GamesScoreDifferential: avgScoreDiff,
        trendDirection: trendDirection,
        blowoutLosses: blowoutLosses,
        clutchWins: clutchWins,
        currentStreak: streak,
        scoringTrend: scoringTrend
    )
}

// MARK: - Helper Functions

private func isWin(game: Game, team: Team) -> Bool {
    guard let outcome = game.outcome else { return false }
    if game.homeTeam.id == team.id {
        return outcome.winner == .home
    } else if game.awayTeam.id == team.id {
        return outcome.winner == .away
    }
    return false
}

private func scoreDifferential(game: Game, team: Team) -> Int? {
    guard let outcome = game.outcome else { return nil }
    if game.homeTeam.id == team.id {
        return outcome.homeScore - outcome.awayScore
    } else if game.awayTeam.id == team.id {
        return outcome.awayScore - outcome.homeScore
    }
    return nil
}

private func calculateStreak(games: [Game], team: Team) -> Int {
    guard !games.isEmpty else { return 0 }

    let recentGames = Array(games.suffix(10))
    var streak = 0
    let lastGameWin = isWin(game: recentGames.last!, team: team)

    for game in recentGames.reversed() {
        let gameWin = isWin(game: game, team: team)
        if gameWin == lastGameWin {
            streak += lastGameWin ? 1 : -1
        } else {
            break
        }
    }

    return streak
}

private func calculateScoringTrend(games: [Game], team: Team) -> Double {
    guard games.count >= 8 else { return 0.0 }

    let allGames = Array(games.suffix(8))
    let recentGames = Array(allGames.suffix(4))
    let earlierGames = Array(allGames.prefix(4))

    let recentAvg = averageScore(games: recentGames, team: team)
    let earlierAvg = averageScore(games: earlierGames, team: team)

    // Normalize to -1.0 to +1.0 range
    let diff = recentAvg - earlierAvg
    return max(-1.0, min(1.0, diff / 14.0)) // 14 points = significant change
}

private func averageScore(games: [Game], team: Team) -> Double {
    let scores = games.compactMap { game -> Int? in
        guard let outcome = game.outcome else { return nil }
        if game.homeTeam.id == team.id {
            return outcome.homeScore
        } else if game.awayTeam.id == team.id {
            return outcome.awayScore
        }
        return nil
    }

    guard !scores.isEmpty else { return 0.0 }
    return Double(scores.reduce(0, +)) / Double(scores.count)
}

private func calculateOverallWinRate(games: [Game], team: Team) -> Double {
    let wins = games.filter { isWin(game: $0, team: team) }.count
    return Double(wins) / Double(games.count)
}

private func determineTrend(
    last3WinRate: Double,
    overallWinRate: Double,
    streak: Int,
    scoringTrend: Double
) -> TrendDirection {
    let winRateDiff = last3WinRate - overallWinRate

    // Strongly improving: Recent performance much better + positive streak
    if winRateDiff > 0.3 && streak >= 2 {
        return .stronglyImproving
    }

    // Improving: Recent performance better
    if winRateDiff > 0.15 || (streak >= 2 && scoringTrend > 0.3) {
        return .improving
    }

    // Strongly declining: Recent performance much worse + losing streak
    if winRateDiff < -0.3 && streak <= -2 {
        return .stronglyDeclining
    }

    // Declining: Recent performance worse
    if winRateDiff < -0.15 || (streak <= -2 && scoringTrend < -0.3) {
        return .declining
    }

    // Stable: Recent matches overall performance
    return .stable
}
