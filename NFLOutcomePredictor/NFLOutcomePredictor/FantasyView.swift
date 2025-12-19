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
                        PositionFilterChip(
                            title: position,
                            isSelected: selectedPosition == position,
                            isFull: position != "All" && fantasyManager.isPositionFull(position)
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
            } else if selectedPosition != "All" {
                // Show all players for selected position across all teams
                AllPositionPlayersView(
                    position: selectedPosition,
                    fantasyManager: fantasyManager
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Select a team or position")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Choose a team to view all players, or select a position to see the best players across all teams")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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

// MARK: - All Position Players View

struct AllPositionPlayersView: View {
    let position: String
    @ObservedObject var fantasyManager: FantasyTeamManager
    @StateObject private var dataManager = DataManager.shared
    @State private var allPlayers: [(player: PlayerDTO, team: TeamDTO)] = []
    @State private var isLoading = false

    var sortedPlayers: [(player: PlayerDTO, team: TeamDTO)] {
        allPlayers.sorted { (first, second) in
            // Sort by best stats for the position
            let stats1 = first.player.stats
            let stats2 = second.player.stats

            switch position {
            case "QB":
                let yards1 = stats1?.passingYards ?? 0
                let yards2 = stats2?.passingYards ?? 0
                return yards1 > yards2
            case "RB":
                let yards1 = stats1?.rushingYards ?? 0
                let yards2 = stats2?.rushingYards ?? 0
                return yards1 > yards2
            case "WR", "TE":
                let yards1 = stats1?.receivingYards ?? 0
                let yards2 = stats2?.receivingYards ?? 0
                return yards1 > yards2
            default:
                return false
            }
        }
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if sortedPlayers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No players found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedPlayers, id: \.player.id) { item in
                            FantasyPlayerCard(
                                player: item.player,
                                team: item.team,
                                fantasyManager: fantasyManager
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await loadAllPlayers()
        }
        .onChange(of: position) { _ in
            Task {
                await loadAllPlayers()
            }
        }
    }

    private func loadAllPlayers() async {
        isLoading = true
        allPlayers = []

        let apiClient = APIClient()

        // Load players from all teams
        for team in dataManager.teams {
            do {
                let roster = try await apiClient.fetchRoster(teamAbbreviation: team.abbreviation)
                let positionPlayers = roster.players.filter { $0.position == position }
                let teamPlayers = positionPlayers.map { (player: $0, team: team) }
                allPlayers.append(contentsOf: teamPlayers)
            } catch {
                // Continue with other teams if one fails
                continue
            }
        }

        isLoading = false
    }
}

// MARK: - Supporting Views

struct PositionFilterChip: View {
    let title: String
    let isSelected: Bool
    let isFull: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if isFull {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isFull ? Color.green.opacity(0.2) : (isSelected ? Color.accentColor : Color(.systemGray6)))
            .foregroundColor(isFull ? .green : (isSelected ? .white : .primary))
            .cornerRadius(20)
        }
    }
}

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
