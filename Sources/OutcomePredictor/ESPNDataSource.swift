import Foundation

/// ESPN API client for fetching real NFL game data.
///
/// ESPN provides a public API for sports data including schedules, scores, and team information.
/// Base URL: https://site.api.espn.com/apis/site/v2/sports/football/nfl
public struct ESPNDataSource: NFLDataSource {
    private let baseURL: String
    private let session: URLSession

    /// Creates an ESPN data source.
    ///
    /// - Parameters:
    ///   - baseURL: ESPN API base URL.
    ///   - session: URL session for requests.
    public init(
        baseURL: String = "https://site.api.espn.com/apis/site/v2/sports/football/nfl",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    public func fetchGames(week: Int, season: Int) async throws -> [Game] {
        let urlString = "\(baseURL)/scoreboard?seasontype=2&week=\(week)&dates=\(season)"
        guard let url = URL(string: urlString) else {
            throw DataSourceError.invalidURL(urlString)
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataSourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DataSourceError.httpError(httpResponse.statusCode)
        }

        let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: data)
        return try parseGames(from: scoreboard, season: season, week: week)
    }

    public func fetchGames(for team: Team, season: Int) async throws -> [Game] {
        // ESPN uses team abbreviations in their API
        let urlString = "\(baseURL)/teams/\(team.abbreviation.lowercased())/schedule?season=\(season)"
        guard let url = URL(string: urlString) else {
            throw DataSourceError.invalidURL(urlString)
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataSourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DataSourceError.httpError(httpResponse.statusCode)
        }

        let schedule = try JSONDecoder().decode(ESPNSchedule.self, from: data)
        return try parseSchedule(from: schedule, season: season)
    }

    public func fetchLiveScores() async throws -> [Game] {
        let urlString = "\(baseURL)/scoreboard"
        guard let url = URL(string: urlString) else {
            throw DataSourceError.invalidURL(urlString)
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataSourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DataSourceError.httpError(httpResponse.statusCode)
        }

        let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: data)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        return try parseGames(from: scoreboard, season: currentYear, week: 1)
    }

    private func parseGames(from scoreboard: ESPNScoreboard, season: Int, week: Int) throws -> [Game] {
        var games: [Game] = []

        for event in scoreboard.events {
            guard let competition = event.competitions.first else { continue }

            // Parse teams
            guard competition.competitors.count >= 2 else { continue }

            let homeCompetitor = competition.competitors.first { $0.homeAway == "home" }
            let awayCompetitor = competition.competitors.first { $0.homeAway == "away" }

            guard let homeComp = homeCompetitor, let awayComp = awayCompetitor else { continue }
            guard let homeTeam = findTeam(abbreviation: homeComp.team.abbreviation) else { continue }
            guard let awayTeam = findTeam(abbreviation: awayComp.team.abbreviation) else { continue }

            // Parse date
            let dateFormatter = ISO8601DateFormatter()
            guard let scheduledDate = dateFormatter.date(from: event.date) else { continue }

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

        return games
    }

    private func parseSchedule(from schedule: ESPNSchedule, season: Int) throws -> [Game] {
        // Similar parsing logic for schedule endpoint
        // Implementation depends on ESPN schedule response structure
        return []
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
    // Schedule response structure
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
