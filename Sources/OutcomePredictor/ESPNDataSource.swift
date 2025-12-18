import Foundation

/// ESPN API client for fetching real NFL game data.
///
/// Uses AsyncHTTPClient for optimal Linux performance with actor-based caching.
/// ESPN provides a public API for sports data including schedules, scores, and team information.
/// Base URL: https://site.api.espn.com/apis/site/v2/sports/football/nfl
public struct ESPNDataSource: NFLDataSource {
    private let baseURL: String
    private let httpClient: HTTPClient
    private let cache: HTTPCache<[Game]>

    /// Creates an ESPN data source.
    ///
    /// - Parameters:
    ///   - baseURL: ESPN API base URL (defaults to configuration).
    ///   - cacheTTL: Cache time-to-live in seconds (default: 1 hour).
    public init(
        baseURL: String? = nil,
        cacheTTL: TimeInterval = 3600
    ) {
        let config = Configuration.shared.api
        self.baseURL = baseURL ?? config.espnBaseURL
        self.httpClient = HTTPClient()
        self.cache = HTTPCache(defaultTTL: cacheTTL)
    }

    public func fetchGames(week: Int, season: Int) async throws -> [Game] {
        let cacheKey = "espn_scoreboard_\(season)_\(week)"

        // Check cache first
        if let cached = await cache.get(cacheKey) {
            return cached
        }

        // Fetch from API
        let urlString = "\(baseURL)/scoreboard?seasontype=2&week=\(week)&dates=\(season)"
        let (data, statusCode) = try await httpClient.get(url: urlString)

        guard statusCode == 200 else {
            throw DataSourceError.httpError(statusCode)
        }

        let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: data)
        let games = try parseGames(from: scoreboard, season: season, week: week)

        // Cache result
        await cache.set(cacheKey, value: games)

        return games
    }

    public func fetchGames(for team: Team, season: Int) async throws -> [Game] {
        let cacheKey = "espn_team_\(team.abbreviation)_\(season)"

        // Check cache first
        if let cached = await cache.get(cacheKey) {
            return cached
        }

        // ESPN uses team abbreviations in their API
        let urlString = "\(baseURL)/teams/\(team.abbreviation.lowercased())/schedule?season=\(season)"
        let (data, statusCode) = try await httpClient.get(url: urlString)

        guard statusCode == 200 else {
            throw DataSourceError.httpError(statusCode)
        }

        let schedule = try JSONDecoder().decode(ESPNSchedule.self, from: data)
        let games = try parseSchedule(from: schedule, season: season)

        // Cache result
        await cache.set(cacheKey, value: games)

        return games
    }

    public func fetchLiveScores() async throws -> [Game] {
        // Don't cache live scores as they change frequently
        let urlString = "\(baseURL)/scoreboard"
        let (data, statusCode) = try await httpClient.get(url: urlString)

        guard statusCode == 200 else {
            throw DataSourceError.httpError(statusCode)
        }

        let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: data)

        // Extract season and week from ESPN's scoreboard metadata
        let season = scoreboard.season?.year ?? Calendar.current.component(.year, from: Date())
        let week = scoreboard.week?.number ?? 1

        return try parseGames(from: scoreboard, season: season, week: week)
    }

    private func parseGames(from scoreboard: ESPNScoreboard, season: Int, week: Int) throws -> [Game] {
        var games: [Game] = []

        for event in scoreboard.events {
            guard let competition = event.competitions.first else { continue }

            // Parse teams
            guard competition.competitors.count >= 2 else { continue }

            let homeCompetitor = competition.competitors.first { $0.homeAway == "home" }
            let awayCompetitor = competition.competitors.first { $0.homeAway == "away" }

            guard let homeComp = homeCompetitor, let awayComp = awayCompetitor else {
                print("⚠️  Could not find home/away competitors in event")
                continue
            }

            guard let homeTeam = findTeam(abbreviation: homeComp.team.abbreviation) else {
                print("⚠️  Team not found: \(homeComp.team.abbreviation) (Home)")
                continue
            }
            guard let awayTeam = findTeam(abbreviation: awayComp.team.abbreviation) else {
                print("⚠️  Team not found: \(awayComp.team.abbreviation) (Away)")
                continue
            }

            // Parse date - ESPN uses ISO 8601 format but sometimes omits seconds
            var scheduledDate: Date?

            // Try ISO8601 with seconds first
            let iso8601Formatter = ISO8601DateFormatter()
            scheduledDate = iso8601Formatter.date(from: event.date)

            // If that fails, try custom formatter for dates without seconds
            if scheduledDate == nil {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                scheduledDate = dateFormatter.date(from: event.date)
            }

            guard let scheduledDate = scheduledDate else {
                print("⚠️  Could not parse date: \(event.date)")
                continue
            }

            // Parse outcome if game is complete
            var outcome: GameOutcome? = nil
            if competition.status.type.completed {
                if let homeScore = Int(homeComp.score),
                   let awayScore = Int(awayComp.score) {
                    outcome = GameOutcome(homeScore: homeScore, awayScore: awayScore)
                }
            }

            let game = Game(
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                scheduledDate: scheduledDate,
                week: week,
                season: season,
                outcome: outcome
            )

            games.append(game)
        }

        if !games.isEmpty {
            print("✅ Successfully parsed \(games.count) games from ESPN")
        }

        return games
    }

    private func parseSchedule(from schedule: ESPNSchedule, season: Int) throws -> [Game] {
        var games: [Game] = []

        for event in schedule.events {
            guard let competition = event.competitions.first else { continue }

            // Parse teams
            guard competition.competitors.count >= 2 else { continue }

            let homeCompetitor = competition.competitors.first { $0.homeAway == "home" }
            let awayCompetitor = competition.competitors.first { $0.homeAway == "away" }

            guard let homeComp = homeCompetitor, let awayComp = awayCompetitor else {
                print("⚠️  Could not find home/away competitors in schedule event")
                continue
            }

            guard let homeTeam = findTeam(abbreviation: homeComp.team.abbreviation) else {
                print("⚠️  Team not found: \(homeComp.team.abbreviation) (Home)")
                continue
            }
            guard let awayTeam = findTeam(abbreviation: awayComp.team.abbreviation) else {
                print("⚠️  Team not found: \(awayComp.team.abbreviation) (Away)")
                continue
            }

            // Parse date - ESPN uses ISO 8601 format but sometimes omits seconds
            var scheduledDate: Date?

            // Try ISO8601 with seconds first
            let iso8601Formatter = ISO8601DateFormatter()
            scheduledDate = iso8601Formatter.date(from: event.date)

            // If that fails, try custom formatter for dates without seconds
            if scheduledDate == nil {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                scheduledDate = dateFormatter.date(from: event.date)
            }

            guard let scheduledDate = scheduledDate else {
                print("⚠️  Could not parse date: \(event.date)")
                continue
            }

            // Parse outcome if game is complete
            var outcome: GameOutcome? = nil
            if competition.status.type.completed {
                if let homeScore = homeComp.score,
                   let awayScore = awayComp.score {
                    outcome = GameOutcome(
                        homeScore: Int(homeScore.value),
                        awayScore: Int(awayScore.value)
                    )
                }
            }

            // Use season and week from the event data
            let game = Game(
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                scheduledDate: scheduledDate,
                week: event.week.number,
                season: event.season.year,
                outcome: outcome
            )

            games.append(game)
        }

        if !games.isEmpty {
            print("✅ Successfully parsed \(games.count) games from ESPN schedule")
        }

        return games
    }

    private func findTeam(abbreviation: String) -> Team? {
        // ESPN sometimes uses different abbreviations
        let normalizedAbbr = normalizeAbbreviation(abbreviation)
        return NFLTeams.team(abbreviation: normalizedAbbr)
    }

    private func normalizeAbbreviation(_ abbr: String) -> String {
        // Handle ESPN's naming differences
        switch abbr.uppercased() {
        case "WSH": return "WAS"  // Washington
        case "LA": return "LAR"   // Rams
        default: return abbr.uppercased()
        }
    }
}

/// ESPN API response structures.
private struct ESPNScoreboard: Codable {
    let events: [ESPNEvent]
    let season: ESPNScoreboardSeason?
    let week: ESPNScoreboardWeek?
}

private struct ESPNScoreboardSeason: Codable {
    let year: Int
    let type: Int
}

private struct ESPNScoreboardWeek: Codable {
    let number: Int
}

private struct ESPNEvent: Codable {
    let date: String
    let competitions: [ESPNCompetition]
}

private struct ESPNCompetition: Codable {
    let competitors: [ESPNCompetitor]
    let status: ESPNStatus
}

private struct ESPNCompetitor: Codable {
    let homeAway: String
    let score: String
    let team: ESPNTeam
    let winner: Bool?
}

private struct ESPNTeam: Codable {
    let abbreviation: String
    let displayName: String
}

private struct ESPNStatus: Codable {
    let type: ESPNStatusType
}

private struct ESPNStatusType: Codable {
    let completed: Bool
}

private struct ESPNSchedule: Codable {
    let events: [ESPNScheduleEvent]
    let requestedSeason: ESPNSeasonInfo?
}

private struct ESPNScheduleEvent: Codable {
    let id: String
    let date: String
    let season: ESPNSeasonInfo
    let week: ESPNWeek
    let competitions: [ESPNScheduleCompetition]
}

private struct ESPNScheduleCompetition: Codable {
    let competitors: [ESPNScheduleCompetitor]
    let status: ESPNStatus
}

private struct ESPNScheduleCompetitor: Codable {
    let homeAway: String
    let score: ESPNScore?
    let team: ESPNTeam
    let winner: Bool?
}

private struct ESPNScore: Codable {
    let value: Double
    let displayValue: String
}

private struct ESPNSeasonInfo: Codable {
    let year: Int
    let displayName: String?
}

private struct ESPNWeek: Codable {
    let number: Int
    let text: String?
}

/// Errors that can occur when fetching data from external sources.
public enum DataSourceError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(Int)
    case parsingError(String)
    case networkError(Error)
    case rateLimitExceeded
    case authenticationFailed
    case noDataAvailable

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .parsingError(let message):
            return "Failed to parse response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        case .authenticationFailed:
            return "API authentication failed. Check your API key."
        case .noDataAvailable:
            return "No data available for this request"
        }
    }
}
