import Foundation
import Combine

/// API client for communicating with the NFL prediction server.
@MainActor
final class APIClient: ObservableObject {
    private let baseURL: String
    private let urlSession: URLSession
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    init(baseURL: String? = nil) {
        // Use environment variable if provided, otherwise use Azure production server
        if let configuredURL = ProcessInfo.processInfo.environment["SERVER_BASE_URL"] {
            self.baseURL = configuredURL
        } else {
            // StatShark Azure production server
            self.baseURL = baseURL ?? "https://statshark-api.azurewebsites.net/api/v1"
        }

        // Configure URLSession with extended timeouts for Azure cold starts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 90.0  // 90 seconds for request (Azure cold start can take 60s)
        config.timeoutIntervalForResource = 120.0 // 120 seconds for resource
        config.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: config)
    }

    /// Fetches all NFL teams.
    func fetchTeams() async throws -> [TeamDTO] {
        do {
            let url = URL(string: "\(baseURL)/teams")!
            let (data, _) = try await urlSession.data(from: url)
            return try decoder.decode([TeamDTO].self, from: data)
        } catch {
            // If the task was cancelled (for example due to a newer request), don't report
            // it as an unexpected error — just rethrow so callers can handle cancellation.
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                throw error
            }

            if error is CancellationError {
                throw error
            }

            ErrorHandler.shared.handle(error, context: "Failed to fetch NFL teams")
            throw error
        }
    }

    /// Fetches upcoming NFL games with predictions.
    func fetchUpcomingGames() async throws -> [GameDTO] {
        do {
            let url = URL(string: "\(baseURL)/upcoming")!
            let (data, _) = try await urlSession.data(from: url)
            return try decoder.decode([GameDTO].self, from: data)
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                throw error
            }

            if error is CancellationError {
                throw error
            }

            ErrorHandler.shared.handle(error, context: "Failed to fetch upcoming games")
            throw error
        }
    }

    /// Fetches current week games and scores.
    func fetchCurrentWeekGames() async throws -> CurrentWeekResponse {
        do {
            let url = URL(string: "\(baseURL)/current-week")!
            let (data, _) = try await urlSession.data(from: url)
            return try decoder.decode(CurrentWeekResponse.self, from: data)
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                throw error
            }

            if error is CancellationError {
                throw error
            }

            ErrorHandler.shared.handle(error, context: "Failed to fetch current week games")
            throw error
        }
    }

    /// Fetches detailed team information.
    func fetchTeamDetails(teamId: String) async throws -> TeamDetail {
        do {
            let url = URL(string: "\(baseURL)/teams/\(teamId)")!
            let (data, _) = try await urlSession.data(from: url)
            return try decoder.decode(TeamDetail.self, from: data)
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                throw error
            }

            if error is CancellationError {
                throw error
            }

            ErrorHandler.shared.handle(error, context: "Failed to fetch team details for \(teamId)")
            throw error
        }
    }

    /// Makes a prediction for a game between two teams.
    func makePrediction(
        home: String,
        away: String,
        season: Int? = nil
    ) async throws -> PredictionResult {
        // Vapor error response structure
        struct VaporErrorResponse: Codable {
            let error: Bool
            let reason: String
        }

        do {
            let url = URL(string: "\(baseURL)/predictions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Create a Codable request struct
            struct PredictionRequest: Codable {
                let homeTeamAbbreviation: String
                let awayTeamAbbreviation: String
                let season: Int

                enum CodingKeys: String, CodingKey {
                    case homeTeamAbbreviation = "home_team_abbreviation"
                    case awayTeamAbbreviation = "away_team_abbreviation"
                    case season
                }
            }

            // Use provided season or default to current year
            let requestSeason = season ?? Calendar.current.component(.year, from: Date())

            let requestBody = PredictionRequest(
                homeTeamAbbreviation: home,
                awayTeamAbbreviation: away,
                season: requestSeason
            )

            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)

            let (data, _) = try await urlSession.data(for: request)

            // First check if the response is a Vapor error response
            if let errorResponse = try? decoder.decode(VaporErrorResponse.self, from: data),
               errorResponse.error {
                throw NSError(
                    domain: "APIClient",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: errorResponse.reason,
                        NSLocalizedFailureReasonErrorKey: "Server returned error for \(away) @ \(home)"
                    ]
                )
            }

            // The API returns PredictionDTO but we need to map it to PredictionResult
            let predictionDTO = try decoder.decode(PredictionDTO.self, from: data)

            return PredictionResult(
                predictedWinner: predictionDTO.homeWinProbability > predictionDTO.awayWinProbability ? home : away,
                confidence: predictionDTO.confidence,
                reasoning: predictionDTO.reasoning,
                modelVersion: "Production API v2.0"
            )
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                throw error
            }

            if error is CancellationError {
                throw error
            }

            ErrorHandler.shared.handle(error, context: "Failed to make prediction for \(away) @ \(home)")
            throw error
        }
    }

    /// Fetches news articles for a specific team.
    func fetchNews(teamAbbreviation: String, limit: Int = 10) async throws -> [ArticleDTO] {
        do {
            let url = URL(string: "\(baseURL)/news?team=\(teamAbbreviation)&limit=\(limit)")!
            let (data, _) = try await urlSession.data(from: url)
            return try decoder.decode([ArticleDTO].self, from: data)
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                throw error
            }

            if error is CancellationError {
                throw error
            }

            ErrorHandler.shared.handle(error, context: "Failed to fetch news for team \(teamAbbreviation)")
            throw error
        }
    }

    /// Fetches team roster with player stats.
    func fetchRoster(teamAbbreviation: String, season: Int? = nil) async throws -> TeamRosterDTO {
        do {
            let currentSeason = season ?? Calendar.current.component(.year, from: Date())
            let url = URL(string: "\(baseURL)/teams/\(teamAbbreviation)/roster?season=\(currentSeason)")!
            let (data, _) = try await urlSession.data(from: url)

            // Debug logging for WAS team
            if teamAbbreviation == "WAS" {
                print("=== WAS Team Roster Response ===")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(jsonString)")
                }
                print("================================")
            }

            var roster = try decoder.decode(TeamRosterDTO.self, from: data)

            // Fix WAS team issue - if team field was missing, replace with correct team
            if roster.team.abbreviation == "UNK" {
                print("⚠️ Team field missing for \(teamAbbreviation), fetching team info separately")
                // Fetch the team info separately
                let teams = try await fetchTeams()
                if let correctTeam = teams.first(where: { $0.abbreviation == teamAbbreviation }) {
                    print("✅ Successfully replaced placeholder team with: \(correctTeam.name)")
                    roster = TeamRosterDTO(team: correctTeam, players: roster.players, season: roster.season)
                } else {
                    print("❌ Could not find team info for \(teamAbbreviation)")
                }
            }

            return roster
        } catch let decodingError as DecodingError {
            // Enhanced logging for decoding errors
            print("=== Decoding Error for \(teamAbbreviation) ===")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("Missing key: \(key.stringValue)")
                print("Context: \(context.debugDescription)")
                print("Coding path: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                print("Type mismatch: expected \(type)")
                print("Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value not found: \(type)")
                print("Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error")
            }
            print("=============================================")

            ErrorHandler.shared.handle(decodingError, context: "Failed to decode roster for team \(teamAbbreviation)")
            throw decodingError
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                throw error
            }

            if error is CancellationError {
                throw error
            }

            ErrorHandler.shared.handle(error, context: "Failed to fetch roster for team \(teamAbbreviation)")
            throw error
        }
    }

    /// Fetches all games for a specific team and season.
    func fetchTeamGames(teamAbbreviation: String, season: Int) async throws -> [GameDTO] {
        do {
            let url = URL(string: "\(baseURL)/games?team=\(teamAbbreviation)&season=\(season)")!
            let (data, _) = try await urlSession.data(from: url)
            return try decoder.decode([GameDTO].self, from: data)
        } catch {
            if let urlErr = error as? URLError, urlErr.code == .cancelled {
                throw error
            }

            if error is CancellationError {
                throw error
            }

            ErrorHandler.shared.handle(error, context: "Failed to fetch games for team \(teamAbbreviation)")
            throw error
        }
    }

    /// Fetches and calculates league standings from all team games.
    func fetchStandings(season: Int? = nil) async throws -> LeagueStandings {
        let requestSeason = season ?? Calendar.current.component(.year, from: Date())

        // Fetch all teams
        let teams = try await fetchTeams()

        // Fetch games for all teams in parallel
        let teamStandings = try await withThrowingTaskGroup(of: (TeamDTO, [GameDTO]).self) { group in
            for team in teams {
                group.addTask {
                    let games = try await self.fetchTeamGames(teamAbbreviation: team.abbreviation, season: requestSeason)
                    return (team, games)
                }
            }

            var standings: [TeamStandings] = []
            for try await (team, games) in group {
                let teamStanding = self.calculateTeamStandings(team: team, games: games)
                standings.append(teamStanding)
            }
            return standings
        }

        // Group by conference and division
        let divisions = Dictionary(grouping: teamStandings) { standing in
            "\(standing.team.conference)-\(standing.team.division)"
        }
        .map { key, teams in
            let sorted = teams.sorted { ($0.winPercentage, $0.wins) > ($1.winPercentage, $1.wins) }
            let conference = sorted.first?.team.conference ?? ""
            let division = sorted.first?.team.division ?? ""
            return DivisionStandings(conference: conference, division: division, teams: sorted)
        }
        .sorted { ($0.conference, $0.division) < ($1.conference, $1.division) }

        return LeagueStandings(
            season: requestSeason,
            week: nil,
            lastUpdated: Date(),
            divisions: divisions
        )
    }

    // MARK: - Private Helpers

    /// Calculates standings for a single team from their games.
    private func calculateTeamStandings(team: TeamDTO, games: [GameDTO]) -> TeamStandings {
        var wins = 0
        var losses = 0
        var ties = 0
        var pointsFor = 0
        var pointsAgainst = 0
        var divisionWins = 0
        var divisionLosses = 0
        var conferenceWins = 0
        var conferenceLosses = 0
        var recentResults: [String] = []

        // Only count completed games
        let completedGames = games.filter { $0.homeScore != nil && $0.awayScore != nil }

        for game in completedGames {
            let isHome = game.homeTeam.abbreviation == team.abbreviation
            let teamScore = isHome ? game.homeScore! : game.awayScore!
            let opponentScore = isHome ? game.awayScore! : game.homeScore!
            let opponent = isHome ? game.awayTeam : game.homeTeam

            pointsFor += teamScore
            pointsAgainst += opponentScore

            // Determine result
            if teamScore > opponentScore {
                wins += 1
                recentResults.append("W")

                if opponent.division == team.division {
                    divisionWins += 1
                }
                if opponent.conference == team.conference {
                    conferenceWins += 1
                }
            } else if teamScore < opponentScore {
                losses += 1
                recentResults.append("L")

                if opponent.division == team.division {
                    divisionLosses += 1
                }
                if opponent.conference == team.conference {
                    conferenceLosses += 1
                }
            } else {
                ties += 1
                recentResults.append("T")
            }
        }

        // Calculate win percentage
        let totalGames = wins + losses + ties
        let winPercentage = totalGames > 0 ? Double(wins) + (Double(ties) * 0.5) / Double(totalGames) : 0.0

        // Calculate streak from most recent games
        let streak = calculateStreak(results: recentResults.suffix(5))

        return TeamStandings(
            team: team,
            wins: wins,
            losses: losses,
            ties: ties,
            winPercentage: winPercentage,
            pointsFor: pointsFor,
            pointsAgainst: pointsAgainst,
            divisionWins: divisionWins,
            divisionLosses: divisionLosses,
            conferenceWins: conferenceWins,
            conferenceLosses: conferenceLosses,
            streak: streak
        )
    }

    /// Calculates the current win/loss streak.
    private func calculateStreak(results: ArraySlice<String>) -> String {
        guard let mostRecent = results.last else { return "-" }

        var count = 0
        for result in results.reversed() {
            if result == mostRecent {
                count += 1
            } else {
                break
            }
        }

        return "\(mostRecent)\(count)"
    }
}
