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

        // Iterate through position groups
        for positionGroup in espnRoster.athletes {
            // Iterate through players in each position group
            for athlete in positionGroup.items {
                guard let displayName = athlete.displayName,
                      let position = athlete.position?.abbreviation else {
                    continue
                }

                // ESPN's free API doesn't provide player statistics
                // Add sample stats for demonstration (would use paid API in production)
                let stats = generateSampleStats(for: position, playerName: displayName)

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
        }

        return TeamRoster(team: team, players: players, season: season)
    }

    /// Generate sample stats for demonstration
    /// NOTE: ESPN's free API doesn't provide player statistics
    /// In production, use ESPN's premium API or another stats provider
    private func generateSampleStats(for position: String, playerName: String) -> PlayerStats? {
        // Only generate stats for key positions and common player names to keep it realistic
        switch position {
        case "QB":
            return PlayerStats(
                passingYards: Int.random(in: 2800...4500),
                passingTouchdowns: Int.random(in: 20...35),
                passingInterceptions: Int.random(in: 8...15),
                passingCompletions: Int.random(in: 300...450),
                passingAttempts: Int.random(in: 450...650),
                rushingYards: Int.random(in: 50...400),
                rushingTouchdowns: Int.random(in: 2...8),
                rushingAttempts: Int.random(in: 40...90)
            )
        case "RB":
            return PlayerStats(
                rushingYards: Int.random(in: 400...1400),
                rushingTouchdowns: Int.random(in: 4...15),
                rushingAttempts: Int.random(in: 100...300),
                receivingYards: Int.random(in: 150...600),
                receivingTouchdowns: Int.random(in: 1...5),
                receptions: Int.random(in: 20...80),
                targets: Int.random(in: 30...100)
            )
        case "WR":
            return PlayerStats(
                receivingYards: Int.random(in: 300...1500),
                receivingTouchdowns: Int.random(in: 3...12),
                receptions: Int.random(in: 40...120),
                targets: Int.random(in: 60...180)
            )
        case "TE":
            return PlayerStats(
                receivingYards: Int.random(in: 200...1000),
                receivingTouchdowns: Int.random(in: 2...10),
                receptions: Int.random(in: 30...100),
                targets: Int.random(in: 45...130)
            )
        default:
            // Don't generate stats for other positions
            return nil
        }
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
    let athletes: [ESPNPositionGroup]
}

private struct ESPNPositionGroup: Codable {
    let position: String
    let items: [ESPNAthlete]
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
