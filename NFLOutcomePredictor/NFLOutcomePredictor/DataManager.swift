import Foundation
import Combine

/// Shared data manager to coordinate API requests and prevent concurrent calls to the same endpoints.
/// This prevents URLSession task cancellation issues when multiple views request the same data.
@MainActor
final class DataManager: ObservableObject {
    static let shared = DataManager()

    private let apiClient = APIClient()

    // Cached data
    @Published var teams: [TeamDTO] = []
    @Published var upcomingGames: [GameDTO] = []
    @Published var isLoadingTeams = false
    @Published var isLoadingGames = false
    @Published var lastTeamsLoad: Date?
    @Published var lastGamesLoad: Date?
    @Published var error: String?

    // Task tracking to prevent concurrent requests
    private var teamsTask: Task<Void, Never>?
    private var gamesTask: Task<Void, Never>?

    private init() {}

    /// Fetches teams with caching and concurrent request prevention.
    func loadTeams(forceReload: Bool = false) async {
        // Check if we have recent data and don't need to reload
        if !forceReload && !teams.isEmpty &&
           let lastLoad = lastTeamsLoad,
           Date().timeIntervalSince(lastLoad) < 300 { // 5 minutes cache
            return
        }

        // Cancel existing task if any
        teamsTask?.cancel()

        teamsTask = Task {
            await MainActor.run {
                isLoadingTeams = true
                error = nil
            }

            do {
                let loadedTeams = try await apiClient.fetchTeams()

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    teams = loadedTeams
                    lastTeamsLoad = Date()
                    isLoadingTeams = false
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.error = "Failed to load teams: \(error.localizedDescription)"
                    isLoadingTeams = false
                }
            }
        }

        await teamsTask?.value
    }

    /// Fetches upcoming games with caching and concurrent request prevention.
    func loadUpcomingGames(forceReload: Bool = false) async {
        // Check if we have recent data and don't need to reload
        if !forceReload && !upcomingGames.isEmpty &&
           let lastLoad = lastGamesLoad,
           Date().timeIntervalSince(lastLoad) < 180 { // 3 minutes cache
            return
        }

        // Cancel existing task if any
        gamesTask?.cancel()

        gamesTask = Task {
            await MainActor.run {
                isLoadingGames = true
                error = nil
            }

            do {
                let loadedGames = try await apiClient.fetchUpcomingGames()

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    upcomingGames = loadedGames
                    lastGamesLoad = Date()
                    isLoadingGames = false
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.error = "Failed to load upcoming games: \(error.localizedDescription)"
                    isLoadingGames = false
                }
            }
        }

        await gamesTask?.value
    }

    /// Makes a prediction using the shared API client.
    func makePrediction(home: String, away: String) async throws -> PredictionResult {
        return try await apiClient.makePrediction(home: home, away: away)
    }

    /// Clears all cached data and forces a reload.
    func clearCache() {
        teams = []
        upcomingGames = []
        lastTeamsLoad = nil
        lastGamesLoad = nil
        error = nil
    }
}