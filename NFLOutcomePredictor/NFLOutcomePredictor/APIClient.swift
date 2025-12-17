import Foundation
import Combine

/// API client for communicating with the NFL prediction server.
@MainActor
final class APIClient: ObservableObject {
    private let baseURL: String
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
    }

    /// Fetches all NFL teams.
    func fetchTeams() async throws -> [TeamDTO] {
        do {
            let url = URL(string: "\(baseURL)/teams")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try decoder.decode([TeamDTO].self, from: data)
        } catch {
            ErrorHandler.shared.handle(error, context: "Failed to fetch NFL teams")
            throw error
        }
    }

    /// Fetches upcoming NFL games with predictions.
    func fetchUpcomingGames() async throws -> [GameDTO] {
        do {
            let url = URL(string: "\(baseURL)/upcoming")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try decoder.decode([GameDTO].self, from: data)
        } catch {
            ErrorHandler.shared.handle(error, context: "Failed to fetch upcoming games")
            throw error
        }
    }

    /// Fetches current week games and scores.
    func fetchCurrentWeekGames() async throws -> CurrentWeekResponse {
        do {
            let url = URL(string: "\(baseURL)/current-week")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try decoder.decode(CurrentWeekResponse.self, from: data)
        } catch {
            ErrorHandler.shared.handle(error, context: "Failed to fetch current week games")
            throw error
        }
    }

    /// Fetches detailed team information.
    func fetchTeamDetails(teamId: String) async throws -> TeamDetail {
        do {
            let url = URL(string: "\(baseURL)/teams/\(teamId)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try decoder.decode(TeamDetail.self, from: data)
        } catch {
            ErrorHandler.shared.handle(error, context: "Failed to fetch team details for \(teamId)")
            throw error
        }
    }

    /// Makes a prediction for a game between two teams.
    func makePrediction(
        home: String,
        away: String
    ) async throws -> PredictionResult {
        do {
            let url = URL(string: "\(baseURL)/predictions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let requestBody = [
                "home_team_abbreviation": home,
                "away_team_abbreviation": away,
                "season": Calendar.current.component(.year, from: Date())
            ]

            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)

            let (data, _) = try await URLSession.shared.data(for: request)

            // The API returns PredictionDTO but we need to map it to PredictionResult
            let predictionDTO = try decoder.decode(PredictionDTO.self, from: data)

            return PredictionResult(
                predictedWinner: predictionDTO.homeWinProbability > predictionDTO.awayWinProbability ? home : away,
                confidence: predictionDTO.confidence,
                reasoning: predictionDTO.reasoning,
                modelVersion: "Production API v1.0"
            )
        } catch {
            ErrorHandler.shared.handle(error, context: "Failed to make prediction for \(away) @ \(home)")
            throw error
        }
    }
}
