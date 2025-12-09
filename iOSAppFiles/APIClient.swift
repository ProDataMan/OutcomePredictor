import Foundation
import OutcomePredictorAPI

@MainActor
class APIClient: ObservableObject {
    private let baseURL = "http://localhost:8080/api/v1"
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func fetchTeams() async throws -> [TeamDTO] {
        let url = URL(string: "\(baseURL)/teams")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode([TeamDTO].self, from: data)
    }

    func fetchGames(team: String, season: Int) async throws -> [GameDTO] {
        let url = URL(string: "\(baseURL)/games?team=\(team)&season=\(season)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode([GameDTO].self, from: data)
    }

    func fetchNews(team: String, limit: Int = 10) async throws -> [ArticleDTO] {
        let url = URL(string: "\(baseURL)/news?team=\(team)&limit=\(limit)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode([ArticleDTO].self, from: data)
    }

    func makePrediction(
        home: String,
        away: String,
        season: Int,
        week: Int? = nil
    ) async throws -> PredictionDTO {
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
    }
}
