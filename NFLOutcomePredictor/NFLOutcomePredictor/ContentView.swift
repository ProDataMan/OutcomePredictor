import SwiftUI

struct ContentView: View {
    @State private var showDebugMenu = false

    var body: some View {
        TabView {
            TeamsListView()
                .tabItem {
                    Label("Teams", systemImage: "list.bullet")
                }

            PredictionView()
                .tabItem {
                    Label("Predict", systemImage: "chart.bar.fill")
                }

            FantasyView()
                .tabItem {
                    Label("Fantasy", systemImage: "sportscourt.fill")
                }

            #if DEBUG
            Button("Debug") {
                showDebugMenu = true
            }
            .tabItem {
                Label("Debug", systemImage: "wrench.and.screwdriver")
            }
            #endif
        }
        .sheet(isPresented: $showDebugMenu) {
            DebugMenu()
        }
    }
}

struct TeamsListView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var error: String?
    @State private var selectedConference: String = "All"

    private let conferences = ["All", "NFC", "AFC"]

    var filteredTeams: [TeamDTO] {
        let teams = dataManager.teams
        let filtered = selectedConference == "All" ? teams : teams.filter { $0.conference == selectedConference }
        return filtered.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if dataManager.isLoadingTeams {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading teams...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if let error = error ?? dataManager.error {
                    ErrorView(error: error) {
                        Task {
                            await dataManager.loadTeams(forceReload: true)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Current week status bar
                            CurrentWeekStatusView()
                                .padding()

                            // Conference filter
                            Picker("Conference", selection: $selectedConference) {
                                ForEach(conferences, id: \.self) { conference in
                                    Text(conference).tag(conference)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding()

                            // Teams grid
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 160), spacing: 16)
                            ], spacing: 16) {
                                ForEach(filteredTeams, id: \.abbreviation) { team in
                                    NavigationLink(destination: TeamDetailView(team: team)) {
                                        TeamCardView(team: team)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("NFL Teams")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await dataManager.loadTeams(forceReload: true)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(dataManager.isLoadingTeams)
                }
            }
            .task {
                await dataManager.loadTeams()
            }
        }
    }
}

struct TeamCardView: View {
    let team: TeamDTO

    var body: some View {
        VStack(spacing: 12) {
            TeamIconView(teamAbbreviation: team.abbreviation, size: 80)

            VStack(spacing: 4) {
                Text(team.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(team.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ErrorView: View {
    let error: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Error Loading Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview("Content View") {
    ContentView()
}

#Preview("Teams List") {
    TeamsListView()
}
