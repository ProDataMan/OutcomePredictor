import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// API-Sports data source for fetching NFL player statistics and headshots.
///
/// API-Sports provides free tier access (100 requests/day) with:
/// - Player statistics from 2022 onwards
/// - Player headshot URLs
/// - Team statistics
///
/// Get API key at: https://dashboard.api-football.com/
/// Documentation: https://api-sports.io/documentation/nfl/v1
public actor APISportsDataSource: Sendable {
    private let apiKey: String
    private let baseURL: String
    private let session: URLSession

    /// Simple cache entry for roster data
    private struct RosterCacheEntry: Sendable {
        let roster: TeamRoster
        let timestamp: Date
        let expiresAt: Date
    }

    /// Cache for roster data (15 minute TTL to respect 100 requests/day limit)
    private var rosterCache: [String: RosterCacheEntry] = [:]
    private let cacheTTL: TimeInterval

    /// Creates an API-Sports data source with caching.
    ///
    /// - Parameters:
    ///   - apiKey: API-Sports API key.
    ///   - baseURL: API-Sports base URL (default: NFL v1 API).
    ///   - session: URL session for requests.
    ///   - cacheTTL: Cache time-to-live in seconds (default: 900 = 15 minutes).
    public init(
        apiKey: String,
        baseURL: String = "https://v1.american-football.api-sports.io",
        session: URLSession = .shared,
        cacheTTL: TimeInterval = 900 // 15 minutes
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
        self.cacheTTL = cacheTTL
    }

    /// Fetch team roster with player stats and headshots for the season.
    ///
    /// Results are cached for 15 minutes to minimize API calls.
    ///
    /// - Parameters:
    ///   - team: NFL team to fetch roster for.
    ///   - season: Season year (2022 or later for API-Sports).
    /// - Returns: Team roster with players, stats, and headshot URLs.
    /// - Throws: Network or parsing errors.
    public func fetchRoster(for team: Team, season: Int) async throws -> TeamRoster {
        // Check cache first
        let cacheKey = "roster_\(team.abbreviation)_\(season)"
        if let entry = rosterCache[cacheKey], Date() < entry.expiresAt {
            print("✅ Using cached roster for \(team.abbreviation) (season \(season))")
            return entry.roster
        }

        print("📥 Fetching fresh roster from API-Sports for \(team.abbreviation) (season \(season))")

        // API-Sports uses team IDs, so we need to map abbreviations to team IDs
        guard let teamID = getAPIFootballTeamID(abbreviation: team.abbreviation) else {
            throw DataSourceError.parsingError("Unknown API-Sports team ID for \(team.abbreviation)")
        }

        let urlString = "\(baseURL)/players?team=\(teamID)&season=\(season)"
        guard let url = URL(string: urlString) else {
            throw DataSourceError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-apisports-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataSourceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw DataSourceError.rateLimitExceeded
            }
            throw DataSourceError.httpError(httpResponse.statusCode)
        }

        // Log raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📋 API-Sports raw response (first 500 chars): \(String(jsonString.prefix(500)))")
        }

        let apiResponse = try JSONDecoder().decode(APISportsPlayersResponse.self, from: data)

        guard apiResponse.results > 0 else {
            throw DataSourceError.noDataAvailable
        }

        let roster = parseRoster(from: apiResponse, team: team, season: season)

        // Cache the result
        let entry = RosterCacheEntry(
            roster: roster,
            timestamp: Date(),
            expiresAt: Date().addingTimeInterval(cacheTTL)
        )
        rosterCache[cacheKey] = entry
        print("💾 Cached roster for \(team.abbreviation) for \(Int(cacheTTL/60)) minutes")

        return roster
    }

    /// Parse roster from API-Sports response.
    private func parseRoster(from response: APISportsPlayersResponse, team: Team, season: Int) -> TeamRoster {
        var players: [Player] = []
        var playersWithPhotos = 0
        var playersWithoutPhotos = 0

        for playerData in response.response {
            guard let playerId = playerData.id,
                  let playerName = playerData.name else {
                continue
            }

            // Get position (API-Sports uses different position names)
            let position = normalizePosition(playerData.position ?? "")

            // Parse statistics
            let stats = parsePlayerStats(from: playerData.statistics, position: position)

            // Extract bio data from API-Sports (flat structure)
            let age = playerData.age
            let heightUS = playerData.height  // e.g., "6' 1\""
            let weightUS = playerData.weight  // e.g., "340 lbs"

            // Parse weight from string like "340 lbs" to Int
            let weight: Int? = if let weightStr = weightUS {
                Int(weightStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
            } else {
                nil
            }

            // Track photo URL availability
            if let photoURL = playerData.image, !photoURL.isEmpty {
                playersWithPhotos += 1
            } else {
                playersWithoutPhotos += 1
            }

            // Convert number to String for jerseyNumber
            let jerseyNumberStr = playerData.number.map { String($0) }

            let nflPlayer = Player(
                id: String(playerId),
                name: playerName,
                position: position,
                jerseyNumber: jerseyNumberStr,
                photoURL: playerData.image,
                team: team,
                stats: stats,
                height: heightUS,
                weight: weight,
                age: age,
                college: playerData.college,
                experience: playerData.experience
            )

            players.append(nflPlayer)
        }

        print("📸 Photo URL stats for \(team.abbreviation): \(playersWithPhotos) with photos, \(playersWithoutPhotos) without photos")

        return TeamRoster(team: team, players: players, season: season)
    }

    /// Parse player statistics from API-Sports data.
    private func parsePlayerStats(from statistics: [APISportsPlayerStatistics]?, position: String) -> PlayerStats? {
        guard let stats = statistics, !stats.isEmpty else {
            print("⚠️ No statistics array for position \(position)")
            return nil
        }

        // API-Sports provides season stats - use the first entry
        guard let seasonStats = stats.first else {
            print("⚠️ Statistics array is empty for position \(position)")
            return nil
        }

        print("✅ Found statistics for position \(position):")
        print("   - Team: \(seasonStats.team?.name ?? "nil"), Season: \(seasonStats.season ?? "nil")")
        print("   - Passing: \(seasonStats.games.passing?.yards ?? 0) yds, \(seasonStats.games.passing?.touchdowns ?? 0) TDs")
        print("   - Rushing: \(seasonStats.games.rushing?.yards ?? 0) yds, \(seasonStats.games.rushing?.touchdowns ?? 0) TDs")
        print("   - Receiving: \(seasonStats.games.receiving?.yards ?? 0) yds, \(seasonStats.games.receiving?.touchdowns ?? 0) TDs")

        let games = seasonStats.games

        let playerStats = PlayerStats(
            passingYards: games.passing?.yards,
            passingTouchdowns: games.passing?.touchdowns,
            passingInterceptions: games.passing?.interceptions,
            passingCompletions: games.passing?.completions,
            passingAttempts: games.passing?.attempts,
            rushingYards: games.rushing?.yards,
            rushingTouchdowns: games.rushing?.touchdowns,
            rushingAttempts: games.rushing?.attempts,
            receivingYards: games.receiving?.yards,
            receivingTouchdowns: games.receiving?.touchdowns,
            receptions: games.receiving?.receptions,
            targets: games.receiving?.targets,
            tackles: games.defense?.tackles?.total,
            sacks: games.defense?.sacks,
            interceptions: games.defense?.interceptions
        )

        // Check if all fields are nil - if so, return nil instead of empty stats
        let hasAnyStats = [
            playerStats.passingYards, playerStats.passingTouchdowns,
            playerStats.rushingYards, playerStats.rushingTouchdowns,
            playerStats.receivingYards, playerStats.receivingTouchdowns,
            playerStats.tackles
        ].contains(where: { $0 != nil && $0 != 0 })

        if !hasAnyStats {
            print("⚠️ All stats are nil/zero for position \(position)")
            return nil
        }

        return playerStats
    }

    /// Normalize position names from API-Sports to NFL standard positions.
    private func normalizePosition(_ position: String) -> String {
        let normalized = position.uppercased()
        switch normalized {
        case "QUARTERBACK", "QB": return "QB"
        case "RUNNING BACK", "RUNNINGBACK", "RB": return "RB"
        case "WIDE RECEIVER", "WIDERECEIVER", "WR": return "WR"
        case "TIGHT END", "TIGHTEND", "TE": return "TE"
        case "KICKER", "K", "PK": return "K"
        case "DEFENSE", "DEF", "D": return "DEF"
        case "LINEBACKER", "LB": return "LB"
        case "DEFENSIVE BACK", "DB": return "DB"
        case "DEFENSIVE LINE", "DL": return "DL"
        case "OFFENSIVE LINE", "OL": return "OL"
        default: return normalized
        }
    }

    /// Map NFL team abbreviations to API-Sports team IDs.
    ///
    /// API-Sports uses numeric team IDs. This mapping is based on their database.
    /// Note: These IDs may need to be updated if API-Sports changes their system.
    private func getAPIFootballTeamID(abbreviation: String) -> Int? {
        let teamMap: [String: Int] = [
            "ARI": 1, "ATL": 2, "BAL": 3, "BUF": 4,
            "CAR": 5, "CHI": 6, "CIN": 7, "CLE": 8,
            "DAL": 9, "DEN": 10, "DET": 11, "GB": 12,
            "HOU": 13, "IND": 14, "JAX": 15, "KC": 16,
            "LAC": 17, "LAR": 18, "LV": 19, "MIA": 20,
            "MIN": 21, "NE": 22, "NO": 23, "NYG": 24,
            "NYJ": 25, "PHI": 26, "PIT": 27, "SF": 28,
            "SEA": 29, "TB": 30, "TEN": 31, "WAS": 32
        ]
        return teamMap[abbreviation]
    }

    /// Get cache statistics for monitoring.
    public func getCacheStats() -> (count: Int, oldestEntry: Date?, newestEntry: Date?) {
        let timestamps = rosterCache.values.map { $0.timestamp }
        return (
            count: rosterCache.count,
            oldestEntry: timestamps.min(),
            newestEntry: timestamps.max()
        )
    }

    /// Clear all caches (useful for testing or forced refresh).
    public func clearCaches() {
        rosterCache.removeAll()
        print("🗑️ Cleared API-Sports roster cache")
    }

    /// Clean up expired cache entries.
    public func cleanupExpiredCache() {
        let now = Date()
        rosterCache = rosterCache.filter { $0.value.expiresAt > now }
        print("🧹 Cleaned up expired API-Sports cache entries")
    }
}

// MARK: - API-Sports Response Models

/// Root response from API-Sports players endpoint.
private struct APISportsPlayersResponse: Codable {
    let results: Int
    let response: [APISportsPlayerData]

    // Ignore other fields that have variable types
    enum CodingKeys: String, CodingKey {
        case results
        case response
    }
}

/// Player data container - flat structure from API
private struct APISportsPlayerData: Codable {
    let id: Int?
    let name: String?
    let position: String?
    let number: Int?
    let age: Int?
    let height: String?
    let weight: String?
    let college: String?
    let experience: Int?
    let image: String?
    let group: String?
    let salary: String?
    let statistics: [APISportsPlayerStatistics]?
}

/// Height/Weight measurement.
private struct APISportsMeasurement: Codable {
    let US: String?
}

/// Player statistics for a season.
private struct APISportsPlayerStatistics: Codable {
    let team: APISportsTeamInfo?
    let league: String?
    let season: String?
    let games: APISportsGameStats
}

/// Team information.
private struct APISportsTeamInfo: Codable {
    let id: Int?
    let name: String?
    let logo: String?
}

/// Game statistics breakdown.
private struct APISportsGameStats: Codable {
    let passing: APISportsPassingStats?
    let rushing: APISportsRushingStats?
    let receiving: APISportsReceivingStats?
    let defense: APISportsDefenseStats?
}

/// Passing statistics.
private struct APISportsPassingStats: Codable {
    let completions: Int?
    let attempts: Int?
    let yards: Int?
    let touchdowns: Int?
    let interceptions: Int?
    let rating: Double?
}

/// Rushing statistics.
private struct APISportsRushingStats: Codable {
    let attempts: Int?
    let yards: Int?
    let touchdowns: Int?
    let longest: Int?
}

/// Receiving statistics.
private struct APISportsReceivingStats: Codable {
    let targets: Int?
    let receptions: Int?
    let yards: Int?
    let touchdowns: Int?
    let longest: Int?
}

/// Defense statistics.
private struct APISportsDefenseStats: Codable {
    let tackles: APISportsTackles?
    let sacks: Double?
    let interceptions: Int?
    let forcedFumbles: Int?
    let fumblesRecovered: Int?
}

/// Tackle statistics.
private struct APISportsTackles: Codable {
    let total: Int?
    let solo: Int?
    let assisted: Int?
}
