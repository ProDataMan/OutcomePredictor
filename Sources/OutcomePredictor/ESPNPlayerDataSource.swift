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
        // ESPN's free API only provides current season roster
        // Don't include season parameter as it causes empty results

        // Convert team abbreviation to ESPN format (WAS → WSH)
        let espnAbbreviation = convertToESPNAbbreviation(team.abbreviation)

        let urlString = "\(baseURL)/teams/\(espnAbbreviation.lowercased())/roster"
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

    /// Convert our abbreviations to ESPN's format.
    private func convertToESPNAbbreviation(_ abbreviation: String) -> String {
        switch abbreviation {
        case "WAS": return "WSH"  // Washington Commanders
        default: return abbreviation
        }
    }

    private func parseRoster(from espnRoster: ESPNRosterResponse, team: Team, season: Int) -> TeamRoster {
        var players: [Player] = []
        var playersWithPhotos = 0
        var playersWithoutPhotos = 0

        // Iterate through position groups
        for positionGroup in espnRoster.athletes {
            // Iterate through players in each position group
            for athlete in positionGroup.items {
                guard let displayName = athlete.displayName,
                      let position = athlete.position?.abbreviation else {
                    continue
                }

                // Track photo URL availability
                if let headshot = athlete.headshot?.href, !headshot.isEmpty {
                    playersWithPhotos += 1
                } else {
                    playersWithoutPhotos += 1
                }

                // ESPN's free API doesn't provide player statistics
                // Return nil for stats - only use real stats from API-Sports
                let stats: PlayerStats? = nil

                // Extract bio data from ESPN
                let age = athlete.age
                let height = athlete.displayHeight
                let collegeName = athlete.college?.name

                // Parse weight from displayWeight string like "215 lbs" to Int
                let weight: Int? = if let displayWeight = athlete.displayWeight {
                    Int(displayWeight.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                } else if let weightValue = athlete.weight {
                    Int(weightValue)
                } else {
                    nil
                }

                // Calculate experience from debut year
                let experience: Int? = if let debutYear = athlete.debutYear {
                    season - debutYear
                } else {
                    nil
                }

                let player = Player(
                    id: athlete.id,
                    name: displayName,
                    position: position,
                    jerseyNumber: athlete.jersey,
                    photoURL: athlete.headshot?.href,
                    team: team,
                    stats: stats,
                    height: height,
                    weight: weight,
                    age: age,
                    college: collegeName,
                    experience: experience
                )

                players.append(player)
            }
        }

        print("📸 ESPN Photo URL stats for \(team.abbreviation): \(playersWithPhotos) with photos, \(playersWithoutPhotos) without photos")

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
    let age: Int?
    let displayHeight: String?
    let displayWeight: String?
    let weight: Double?
    let debutYear: Int?
    let college: ESPNCollege?
}

private struct ESPNPosition: Codable {
    let abbreviation: String
}

private struct ESPNHeadshot: Codable {
    let href: String
}

private struct ESPNCollege: Codable {
    let name: String?
}

private struct ESPNStatistic: Codable {
    let name: String?
    let value: Double
}
