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
    /// Uses dual-endpoint approach:
    /// 1. Fetches player bio data from /players endpoint
    /// 2. Fetches statistics from /players/statistics endpoint
    /// 3. Merges both by player ID
    ///
    /// Results are cached for 15 minutes to minimize API calls.
    ///
    /// - Parameters:
    ///   - team: NFL team to fetch roster for.
    ///   - season: Season year (2022 or later for API-Sports statistics).
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

        guard let teamID = getAPIFootballTeamID(abbreviation: team.abbreviation) else {
            throw DataSourceError.parsingError("Unknown API-Sports team ID for \(team.abbreviation)")
        }

        // Fetch both bio data and statistics in parallel
        async let bioData = fetchPlayerBioData(teamID: teamID, season: season)
        async let statsData = fetchPlayerStatistics(teamID: teamID, season: season)

        let (players, statistics) = try await (bioData, statsData)

        // Merge bio and stats by player ID
        let roster = mergePlayerData(bioData: players, statsData: statistics, team: team, season: season)

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

    /// Fetch player bio data from /players endpoint
    private func fetchPlayerBioData(teamID: Int, season: Int) async throws -> [APISportsPlayerBioData] {
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

        let apiResponse = try JSONDecoder().decode(APISportsPlayersResponse.self, from: data)
        print("📋 Fetched \(apiResponse.results) player bio records")

        return apiResponse.response
    }

    /// Fetch player statistics from /players/statistics endpoint
    private func fetchPlayerStatistics(teamID: Int, season: Int) async throws -> [APISportsPlayerStatisticsData] {
        let urlString = "\(baseURL)/players/statistics?team=\(teamID)&season=\(season)"
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

        let apiResponse = try JSONDecoder().decode(APISportsStatisticsResponse.self, from: data)
        print("📊 Fetched \(apiResponse.results) player statistics records")

        return apiResponse.response
    }

    /// Merge player bio data and statistics by player ID
    private func mergePlayerData(
        bioData: [APISportsPlayerBioData],
        statsData: [APISportsPlayerStatisticsData],
        team: Team,
        season: Int
    ) -> TeamRoster {
        // Create a dictionary of statistics by player ID for quick lookup
        var statsMap: [Int: APISportsPlayerStatisticsData] = [:]
        for playerStats in statsData {
            if let playerID = playerStats.player?.id {
                statsMap[playerID] = playerStats
            }
        }

        var players: [Player] = []
        var playersWithStats = 0
        var playersWithoutStats = 0
        var playersWithPhotos = 0
        var playersWithoutPhotos = 0

        for playerBio in bioData {
            guard let playerID = playerBio.id,
                  let playerName = playerBio.name else {
                continue
            }

            // Get position
            let position = normalizePosition(playerBio.position ?? "")

            // Get statistics for this player
            let playerStatsData = statsMap[playerID]
            let stats = parsePlayerStats(from: playerStatsData, position: position)

            if stats != nil {
                playersWithStats += 1
            } else {
                playersWithoutStats += 1
            }

            // Track photo URLs
            if let photoURL = playerBio.image, !photoURL.isEmpty {
                playersWithPhotos += 1
            } else {
                playersWithoutPhotos += 1
            }

            // Parse weight
            let weight: Int? = if let weightStr = playerBio.weight {
                Int(weightStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
            } else {
                nil
            }

            let jerseyNumberStr = playerBio.number.map { String($0) }

            let nflPlayer = Player(
                id: String(playerID),
                name: playerName,
                position: position,
                jerseyNumber: jerseyNumberStr,
                photoURL: playerBio.image,
                team: team,
                stats: stats,
                height: playerBio.height,
                weight: weight,
                age: playerBio.age,
                college: playerBio.college,
                experience: playerBio.experience
            )

            players.append(nflPlayer)
        }

        print("📊 Stats summary: \(playersWithStats) with stats, \(playersWithoutStats) without stats")
        print("📸 Photo URL stats: \(playersWithPhotos) with photos, \(playersWithoutPhotos) without photos")

        return TeamRoster(team: team, players: players, season: season)
    }

    /// Parse player statistics from API-Sports /players/statistics endpoint.
    private func parsePlayerStats(from playerStatsData: APISportsPlayerStatisticsData?, position: String) -> PlayerStats? {
        guard let statsData = playerStatsData,
              let teams = statsData.teams,
              let firstTeam = teams.first,
              let groups = firstTeam.groups,
              !groups.isEmpty else {
            return nil
        }

        // Create a dictionary of statistics by group name
        var statsByGroup: [String: [String: String]] = [:]
        for group in groups {
            guard let groupName = group.name, let statistics = group.statistics else { continue }

            var groupStats: [String: String] = [:]
            for stat in statistics {
                if let name = stat.name, let value = stat.value {
                    groupStats[name.lowercased()] = value
                }
            }
            statsByGroup[groupName] = groupStats
        }

        // Parse integer value from string, handling commas
        func parseInt(_ value: String?) -> Int? {
            guard let value = value else { return nil }
            let cleaned = value.replacingOccurrences(of: ",", with: "")
            return Int(cleaned)
        }

        // Parse double value from string
        func parseDouble(_ value: String?) -> Double? {
            guard let value = value else { return nil }
            return Double(value)
        }

        // Extract stats from groups
        let passingStats = statsByGroup["Passing"]
        let rushingStats = statsByGroup["Rushing"]
        let receivingStats = statsByGroup["Receiving"]
        let defensiveStats = statsByGroup["Defensive"]

        return PlayerStats(
            passingYards: parseInt(passingStats?["yards"]),
            passingTouchdowns: parseInt(passingStats?["passing touchdowns"]),
            passingInterceptions: parseInt(passingStats?["interceptions"]),
            passingCompletions: parseInt(passingStats?["completions"]),
            passingAttempts: parseInt(passingStats?["passing attempts"]),
            rushingYards: parseInt(rushingStats?["yards"]),
            rushingTouchdowns: parseInt(rushingStats?["rushing touchdowns"]),
            rushingAttempts: parseInt(rushingStats?["rushing attempts"]),
            receivingYards: parseInt(receivingStats?["receiving yards"]),
            receivingTouchdowns: parseInt(receivingStats?["receiving touchdowns"]),
            receptions: parseInt(receivingStats?["receptions"]),
            targets: parseInt(receivingStats?["receiving targets"]),
            tackles: parseInt(defensiveStats?["tackles"]),
            sacks: parseDouble(defensiveStats?["sacks"]),
            interceptions: parseInt(defensiveStats?["interceptions"])
        )
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
        // Correct team ID mapping from API-Sports (verified 2024-01-03)
        let teamMap: [String: Int] = [
            "LV": 1, "JAX": 2, "NE": 3, "NYG": 4,
            "BAL": 5, "TEN": 6, "DET": 7, "ATL": 8,
            "CLE": 9, "CIN": 10, "ARI": 11, "PHI": 12,
            "NYJ": 13, "SF": 14, "GB": 15, "CHI": 16,
            "KC": 17, "WAS": 18, "CAR": 19, "BUF": 20,
            "IND": 21, "PIT": 22, "SEA": 23, "TB": 24,
            "MIA": 25, "HOU": 26, "NO": 27, "DEN": 28,
            "DAL": 29, "LAC": 30, "LAR": 31, "MIN": 32
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

/// Root response from API-Sports players endpoint (bio data).
private struct APISportsPlayersResponse: Codable {
    let results: Int
    let response: [APISportsPlayerBioData]

    enum CodingKeys: String, CodingKey {
        case results
        case response
    }
}

/// Player bio data from /players endpoint
private struct APISportsPlayerBioData: Codable {
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
}

/// Root response from API-Sports players/statistics endpoint
private struct APISportsStatisticsResponse: Codable {
    let results: Int
    let response: [APISportsPlayerStatisticsData]

    enum CodingKeys: String, CodingKey {
        case results
        case response
    }
}

/// Player statistics data from /players/statistics endpoint
private struct APISportsPlayerStatisticsData: Codable {
    let player: APISportsPlayerInfo?
    let teams: [APISportsTeamStats]?
}

/// Basic player info in statistics response
private struct APISportsPlayerInfo: Codable {
    let id: Int?
    let name: String?
    let image: String?
}

/// Team statistics container
private struct APISportsTeamStats: Codable {
    let team: APISportsTeamInfo?
    let groups: [APISportsStatisticsGroup]?
}

/// Statistics group (Passing, Rushing, etc.)
private struct APISportsStatisticsGroup: Codable {
    let name: String?
    let statistics: [APISportsStatistic]?
}

/// Individual statistic
private struct APISportsStatistic: Codable {
    let name: String?
    let value: String?
}

/// Team information.
private struct APISportsTeamInfo: Codable {
    let id: Int?
    let name: String?
    let logo: String?
}
