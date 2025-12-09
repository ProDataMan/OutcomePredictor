import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Injury status for NFL players.
public enum InjuryStatus: String, Codable, Sendable {
    case out = "Out"
    case doubtful = "Doubtful"
    case questionable = "Questionable"
    case probable = "Probable"
    case healthy = "Healthy"
}

/// Player position categories for impact assessment.
public enum PlayerPosition: String, Codable, Sendable {
    case quarterback = "QB"
    case runningBack = "RB"
    case wideReceiver = "WR"
    case tightEnd = "TE"
    case defense = "DEF"
    case other = "Other"

    /// Impact weight for predictions (0.0 to 1.0).
    public var impactWeight: Double {
        switch self {
        case .quarterback: return 1.0  // Highest impact
        case .runningBack: return 0.6
        case .wideReceiver: return 0.5
        case .tightEnd: return 0.3
        case .defense: return 0.4
        case .other: return 0.1
        }
    }
}

/// Represents an injured player.
public struct InjuredPlayer: Codable, Sendable {
    public let name: String
    public let position: PlayerPosition
    public let status: InjuryStatus
    public let description: String?

    public init(name: String, position: PlayerPosition, status: InjuryStatus, description: String? = nil) {
        self.name = name
        self.position = position
        self.status = status
        self.description = description
    }

    /// Calculate impact on team performance (0.0 to 1.0).
    public var impact: Double {
        let statusMultiplier: Double
        switch status {
        case .out: statusMultiplier = 1.0
        case .doubtful: statusMultiplier = 0.75
        case .questionable: statusMultiplier = 0.4
        case .probable: statusMultiplier = 0.15
        case .healthy: statusMultiplier = 0.0
        }

        return position.impactWeight * statusMultiplier
    }
}

/// Team injury report.
public struct TeamInjuryReport: Sendable {
    public let team: Team
    public let injuries: [InjuredPlayer]
    public let fetchedAt: Date

    public init(team: Team, injuries: [InjuredPlayer], fetchedAt: Date = Date()) {
        self.team = team
        self.injuries = injuries
        self.fetchedAt = fetchedAt
    }

    /// Total injury impact for the team (0.0 to 1.0).
    public var totalImpact: Double {
        // Take top 3 most impactful injuries (diminishing returns)
        let sortedImpacts = injuries.map { $0.impact }.sorted(by: >)
        let weights = [1.0, 0.5, 0.25] // Diminishing impact

        var total = 0.0
        for (index, impact) in sortedImpacts.prefix(3).enumerated() {
            total += impact * weights[index]
        }

        return min(1.0, total)
    }

    /// Get key injuries (QB, RB1, WR1).
    public var keyInjuries: [InjuredPlayer] {
        injuries.filter { injury in
            injury.impact > 0.3 &&
            (injury.status == .out || injury.status == .doubtful)
        }
    }
}

/// Protocol for fetching injury data.
public protocol InjuryDataSource: Sendable {
    /// Fetch injury report for a team.
    func fetchInjuries(for team: Team, season: Int) async throws -> TeamInjuryReport
}

/// Injury tracking service.
public actor InjuryTracker {
    private let dataSource: InjuryDataSource
    private var cache: [String: TeamInjuryReport] = [:]
    private let cacheExpiration: TimeInterval = 6 * 60 * 60 // 6 hours

    public init(dataSource: InjuryDataSource) {
        self.dataSource = dataSource
    }

    /// Get injury report for a team, using cache if available.
    public func getInjuries(for team: Team, season: Int) async throws -> TeamInjuryReport {
        let cacheKey = "\(team.id)-\(season)"

        // Check cache
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.fetchedAt) < cacheExpiration {
            return cached
        }

        // Fetch fresh data
        let report = try await dataSource.fetchInjuries(for: team, season: season)
        cache[cacheKey] = report
        return report
    }

    /// Clear cache.
    public func clearCache() {
        cache.removeAll()
    }
}

/// ESPN injury data source.
public struct ESPNInjuryDataSource: InjuryDataSource {
    private let baseURL: String
    private let session: URLSession

    public init(
        baseURL: String = "https://site.api.espn.com/apis/site/v2/sports/football/nfl",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    public func fetchInjuries(for team: Team, season: Int) async throws -> TeamInjuryReport {
        let urlString = "\(baseURL)/teams/\(team.abbreviation.lowercased())/roster?season=\(season)"
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

        let roster = try JSONDecoder().decode(ESPNRoster.self, from: data)
        return parseInjuries(from: roster, team: team)
    }

    private func parseInjuries(from roster: ESPNRoster, team: Team) -> TeamInjuryReport {
        var injuries: [InjuredPlayer] = []

        for positionGroup in roster.athletes {
            for athlete in positionGroup.items {
                // Only process players with injuries
                guard !athlete.injuries.isEmpty else { continue }

                for injury in athlete.injuries {
                    let status = mapInjuryStatus(injury.status)
                    let position = mapPosition(athlete.position?.abbreviation ?? "")

                    let injuredPlayer = InjuredPlayer(
                        name: athlete.displayName,
                        position: position,
                        status: status,
                        description: injury.longComment ?? injury.shortComment
                    )

                    injuries.append(injuredPlayer)
                }
            }
        }

        return TeamInjuryReport(team: team, injuries: injuries)
    }

    private func mapInjuryStatus(_ status: String) -> InjuryStatus {
        switch status.lowercased() {
        case "out": return .out
        case "doubtful": return .doubtful
        case "questionable": return .questionable
        case "probable": return .probable
        default: return .healthy
        }
    }

    private func mapPosition(_ abbreviation: String) -> PlayerPosition {
        switch abbreviation.uppercased() {
        case "QB": return .quarterback
        case "RB", "FB": return .runningBack
        case "WR": return .wideReceiver
        case "TE": return .tightEnd
        case "DE", "DT", "LB", "CB", "S", "DB": return .defense
        default: return .other
        }
    }
}

// MARK: - ESPN API Models

private struct ESPNRoster: Codable {
    let athletes: [ESPNPositionGroup]
}

private struct ESPNPositionGroup: Codable {
    let position: String
    let items: [ESPNAthlete]
}

private struct ESPNAthlete: Codable {
    let displayName: String
    let position: ESPNPosition?
    let injuries: [ESPNInjury]
}

private struct ESPNPosition: Codable {
    let abbreviation: String
}

private struct ESPNInjury: Codable {
    let status: String
    let longComment: String?
    let shortComment: String?
}
