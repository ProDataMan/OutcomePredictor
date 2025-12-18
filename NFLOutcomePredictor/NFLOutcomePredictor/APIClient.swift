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

        // Configure URLSession with proper timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0  // 30 seconds for request
        config.timeoutIntervalForResource = 60.0 // 60 seconds for resource
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
                modelVersion: "Production API v1.0"
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
            return try decoder.decode(TeamRosterDTO.self, from: data)
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
}
