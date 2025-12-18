import SwiftUI

struct FantasyView: View {
    @StateObject private var fantasyManager = FantasyTeamManager.shared
    @StateObject private var leagueManager = FantasyLeagueManager.shared
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedTab = 0
    @State private var selectedTeam: TeamDTO?
    @State private var selectedPosition: String = "All"
    @State private var searchText = ""

    private let positions = ["All", "QB", "RB", "WR", "TE", "K", "DEF"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Find Players").tag(0)
                    Text("My Team (\(fantasyManager.roster.totalPlayers))").tag(1)
                    Text("Leagues (\(leagueManager.leagues.count))").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    playerSearchView
                } else if selectedTab == 1 {
                    rosterView
                } else {
                    LeaguesView()
                }
            }
            .navigationTitle("Fantasy Football")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == 1 && !fantasyManager.roster.allPlayers.isEmpty {
                        Button(action: {
                            confirmClearRoster()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Player Search View

    private var playerSearchView: some View {
        VStack(spacing: 0) {
            // Current week status
            CurrentWeekStatusView()
                .padding(.horizontal)
                .padding(.bottom, 8)

            // Position filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(positions, id: \.self) { position in
                        FilterChip(
                            title: position,
                            isSelected: selectedPosition == position
                        ) {
                            selectedPosition = position
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            // Team selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dataManager.teams) { team in
                        TeamFilterChip(
                            team: team,
                            isSelected: selectedTeam?.abbreviation == team.abbreviation
                        ) {
                            if selectedTeam?.abbreviation == team.abbreviation {
                                selectedTeam = nil
                            } else {
                                selectedTeam = team
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            Divider()

            // Players list
            if let team = selectedTeam {
                TeamPlayersView(
                    team: team,
                    positionFilter: selectedPosition,
                    fantasyManager: fantasyManager
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Select a team to view players")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Choose from \(dataManager.teams.count) NFL teams")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }

    // MARK: - Roster View

    private var rosterView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Roster summary
                RosterSummaryCard(roster: fantasyManager.roster)
                    .padding(.horizontal)
                    .padding(.top)

                // Position sections
                if !fantasyManager.roster.quarterbacks.isEmpty {
                    PositionSection(
                        title: "Quarterbacks",
                        players: fantasyManager.roster.quarterbacks,
                        maxPlayers: FantasyRoster.maxQBs,
                        fantasyManager: fantasyManager
                    )
                }

                if !fantasyManager.roster.runningBacks.isEmpty {
                    PositionSection(
                        title: "Running Backs",
                        players: fantasyManager.roster.runningBacks,
                        maxPlayers: FantasyRoster.maxRBs,
                        fantasyManager: fantasyManager
                    )
                }

                if !fantasyManager.roster.wideReceivers.isEmpty {
                    PositionSection(
                        title: "Wide Receivers",
                        players: fantasyManager.roster.wideReceivers,
                        maxPlayers: FantasyRoster.maxWRs,
                        fantasyManager: fantasyManager
                    )
                }

                if !fantasyManager.roster.tightEnds.isEmpty {
                    PositionSection(
                        title: "Tight Ends",
                        players: fantasyManager.roster.tightEnds,
                        maxPlayers: FantasyRoster.maxTEs,
                        fantasyManager: fantasyManager
                    )
                }

                if fantasyManager.roster.allPlayers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("Your roster is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Add players from the Find Players tab")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(.bottom)
        }
    }

    private func confirmClearRoster() {
        let alert = UIAlertController(
            title: "Clear Roster?",
            message: "This will remove all players from your fantasy team.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            fantasyManager.clearRoster()
        })

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

// MARK: - Team Players View

struct TeamPlayersView: View {
    let team: TeamDTO
    let positionFilter: String
    @ObservedObject var fantasyManager: FantasyTeamManager
    @State private var roster: TeamRosterDTO?
    @State private var isLoading = false

    var filteredPlayers: [PlayerDTO] {
        guard let roster = roster else { return [] }
        if positionFilter == "All" {
            return roster.players
        }
        return roster.players.filter { $0.position == positionFilter }
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if roster != nil {
                if filteredPlayers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No \(positionFilter == "All" ? "" : positionFilter) players found")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPlayers) { player in
                                FantasyPlayerCard(
                                    player: player,
                                    team: team,
                                    fantasyManager: fantasyManager
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .task {
            await loadRoster()
        }
        .onChange(of: team.abbreviation) { _ in
            Task {
                await loadRoster()
            }
        }
    }

    private func loadRoster() async {
        isLoading = true
        do {
            let apiClient = APIClient()
            roster = try await apiClient.fetchRoster(teamAbbreviation: team.abbreviation)
        } catch {
            roster = nil
        }
        isLoading = false
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct TeamFilterChip: View {
    let team: TeamDTO
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                TeamIconView(teamAbbreviation: team.abbreviation, size: 24)
                Text(team.abbreviation)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? TeamBranding.branding(for: team.abbreviation).primaryColor.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? TeamBranding.branding(for: team.abbreviation).primaryColor : .primary)
            .cornerRadius(20)
        }
    }
}

struct RosterSummaryCard: View {
    let roster: FantasyRoster

    var totalPoints: Double {
        roster.allPlayers.reduce(0) { $0 + $1.projectedPoints }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(roster.totalPlayers)/\(roster.maxPlayers)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Projected Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", totalPoints))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
            }

            // Position breakdown
            HStack(spacing: 16) {
                PositionCount(position: "QB", count: roster.quarterbacks.count, max: FantasyRoster.maxQBs)
                PositionCount(position: "RB", count: roster.runningBacks.count, max: FantasyRoster.maxRBs)
                PositionCount(position: "WR", count: roster.wideReceivers.count, max: FantasyRoster.maxWRs)
                PositionCount(position: "TE", count: roster.tightEnds.count, max: FantasyRoster.maxTEs)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PositionCount: View {
    let position: String
    let count: Int
    let max: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(position)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(count)/\(max)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(count >= max ? .green : .primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PositionSection: View {
    let title: String
    let players: [FantasyPlayer]
    let maxPlayers: Int
    @ObservedObject var fantasyManager: FantasyTeamManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Text("(\(players.count)/\(maxPlayers))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ForEach(players) { player in
                FantasyRosterPlayerCard(player: player, fantasyManager: fantasyManager)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    FantasyView()
}
