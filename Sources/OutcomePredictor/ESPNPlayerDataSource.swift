import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// ESPN player data source for fetching rosters and stats.
public struct ESPNPlayerDataSource: Sendable {
    private let baseURL: String
    private let session: URLSession

    public init(
        baseURL: String = "https://site.api.espn.com/apis/site/v2/sports/football/nfl",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Fetch team roster with player stats for the season.
    public func fetchRoster(for team: Team, season: Int) async throws -> TeamRoster {
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

        let espnRoster = try JSONDecoder().decode(ESPNRosterResponse.self, from: data)
        return parseRoster(from: espnRoster, team: team, season: season)
    }

    private func parseRoster(from espnRoster: ESPNRosterResponse, team: Team, season: Int) -> TeamRoster {
        var players: [Player] = []

        for athlete in espnRoster.athletes {
            guard let displayName = athlete.displayName,
                  let position = athlete.position?.abbreviation else {
                continue
            }

            // Parse stats if available
            var stats: PlayerStats? = nil
            if let athleteStats = athlete.statistics, !athleteStats.isEmpty {
                stats = parsePlayerStats(athleteStats, position: position)
            }

            let player = Player(
                id: athlete.id,
                name: displayName,
                position: position,
                jerseyNumber: athlete.jersey,
                photoURL: athlete.headshot?.href,
                team: team,
                stats: stats
            )

            players.append(player)
        }

        return TeamRoster(team: team, players: players, season: season)
    }

    private func parsePlayerStats(_ stats: [ESPNStatistic], position: String) -> PlayerStats {
        var passingYards: Int? = nil
        var passingTD: Int? = nil
        var passingINT: Int? = nil
        var passingComp: Int? = nil
        var passingAtt: Int? = nil
        var rushingYards: Int? = nil
        var rushingTD: Int? = nil
        var rushingAtt: Int? = nil
        var receivingYards: Int? = nil
        var receivingTD: Int? = nil
        var receptions: Int? = nil
        var targets: Int? = nil
        var tackles: Int? = nil
        var sacks: Double? = nil
        var interceptions: Int? = nil

        for stat in stats {
            switch stat.name?.lowercased() {
            case "passingyards": passingYards = Int(stat.value)
            case "passingtouchdowns": passingTD = Int(stat.value)
            case "interceptions":
                if position == "QB" {
                    passingINT = Int(stat.value)
                } else {
                    interceptions = Int(stat.value)
                }
            case "completions": passingComp = Int(stat.value)
            case "attempts":
                if position == "QB" {
                    passingAtt = Int(stat.value)
                } else {
                    rushingAtt = Int(stat.value)
                }
            case "rushingyards": rushingYards = Int(stat.value)
            case "rushingtouchdowns": rushingTD = Int(stat.value)
            case "receivingyards": receivingYards = Int(stat.value)
            case "receivingtouchdowns": receivingTD = Int(stat.value)
            case "receptions": receptions = Int(stat.value)
            case "targets": targets = Int(stat.value)
            case "totaltackles": tackles = Int(stat.value)
            case "sacks": sacks = Double(stat.value)
            default: break
            }
        }

        return PlayerStats(
            passingYards: passingYards,
            passingTouchdowns: passingTD,
            passingInterceptions: passingINT,
            passingCompletions: passingComp,
            passingAttempts: passingAtt,
            rushingYards: rushingYards,
            rushingTouchdowns: rushingTD,
            rushingAttempts: rushingAtt,
            receivingYards: receivingYards,
            receivingTouchdowns: receivingTD,
            receptions: receptions,
            targets: targets,
            tackles: tackles,
            sacks: sacks,
            interceptions: interceptions
        )
    }
}

// MARK: - ESPN API Models

private struct ESPNRosterResponse: Codable {
    let athletes: [ESPNAthlete]
}

private struct ESPNAthlete: Codable {
    let id: String
    let displayName: String?
    let jersey: String?
    let position: ESPNPosition?
    let headshot: ESPNHeadshot?
    let statistics: [ESPNStatistic]?
}

private struct ESPNPosition: Codable {
    let abbreviation: String
}

private struct ESPNHeadshot: Codable {
    let href: String
}

private struct ESPNStatistic: Codable {
    let name: String?
    let value: Double
}
