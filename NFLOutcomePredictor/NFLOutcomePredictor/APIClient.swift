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

    /// Fetches upcoming NFL games.
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

    /// Fetches games for a specific team and season.
    func fetchGames(team: String, season: Int) async throws -> [GameDTO] {
        do {
            let url = URL(string: "\(baseURL)/games?team=\(team)&season=\(season)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try decoder.decode([GameDTO].self, from: data)
        } catch {
            ErrorHandler.shared.handle(error, context: "Failed to fetch games for \(team) season \(season)")
            throw error
        }
    }

    /// Fetches news articles for a specific team.
    func fetchNews(team: String, limit: Int = 10) async throws -> [ArticleDTO] {
        do {
            let url = URL(string: "\(baseURL)/news?team=\(team)&limit=\(limit)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try decoder.decode([ArticleDTO].self, from: data)
        } catch {
            ErrorHandler.shared.handle(error, context: "Failed to fetch news for \(team)")
            throw error
        }
    }

    /// Makes a prediction for a game between two teams.
    func makePrediction(
        home: String,
        away: String,
        season: Int,
        week: Int? = nil
    ) async throws -> PredictionDTO {
        do {
            let url = URL(string: "\(baseURL)/predictions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = PredictionRequest(
                homeTeamAbbreviation: home,
                awayTeamAbbreviation: away,
                scheduledDate: nil,
                week: week,
                season: season
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)

            let (data, _) = try await URLSession.shared.data(for: request)
            return try decoder.decode(PredictionDTO.self, from: data)
        } catch {
            ErrorHandler.shared.handle(error, context: "Failed to make prediction for \(away) @ \(home)")
            throw error
        }
    }
}
