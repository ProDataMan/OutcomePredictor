import SwiftUI
import OutcomePredictorAPI

struct ContentView: View {
    @StateObject private var apiClient = APIClient()
    @State private var teams: [TeamDTO] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading teams...")
                } else if let error = error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.title)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            Task {
                                await loadTeams()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List(teams, id: \.abbreviation) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            VStack(alignment: .leading) {
                                Text(team.name)
                                    .font(.headline)
                                Text("\(team.conference.uppercased()) \(team.division.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("NFL Teams")
            .task {
                await loadTeams()
            }
        }
    }

    private func loadTeams() async {
        isLoading = true
        error = nil

        do {
            teams = try await apiClient.fetchTeams()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    ContentView()
}
