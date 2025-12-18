import SwiftUI

struct PlayerDetailView: View {
    let player: PlayerDTO
    let teamAbbreviation: String
    var showFantasyButton: Bool = false
    @StateObject private var fantasyManager = FantasyTeamManager.shared
    @State private var showingAddedAlert = false
    @State private var showingFullAlert = false

    private var isOnRoster: Bool {
        fantasyManager.isOnRoster(player.id)
    }

    private var isPositionFull: Bool {
        fantasyManager.isPositionFull(player.position)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Player header with photo
                VStack(spacing: 16) {
                    // Player photo
                    if let photoURL = player.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                ProgressView()
                            }
                        }
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 150)
                            .overlay(
                                VStack {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                    Text(player.position)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                    }

                    // Player name and info
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text(player.name)
                                .font(.title)
                                .fontWeight(.bold)

                            if let jersey = player.jerseyNumber {
                                Text("#\(jersey)")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text(player.position)
                            .font(.title3)
                            .foregroundColor(.secondary)

                        TeamIconView(teamAbbreviation: teamAbbreviation, size: 40)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)

                // Stats section
                if let stats = player.stats {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Season Stats")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        StatsGrid(player: player, stats: stats)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)

                        Text("No stats available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }

                // Fantasy button (if enabled)
                if showFantasyButton {
                    if isOnRoster {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("On Your Fantasy Team")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        Button(action: {
                            addToFantasyTeam()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text(isPositionFull ? "Position Full" : "Add to Fantasy Team")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPositionFull ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isPositionFull)
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
        }
        .navigationTitle("Player Stats")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Position Full", isPresented: $showingFullAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You already have the maximum number of \(player.position) players on your roster.")
        }
    }

    private func addToFantasyTeam() {
        // Get team info - we need to fetch it or pass it through
        // For now, create a minimal TeamDTO from what we know
        let team = TeamDTO(
            name: "", // We don't have the full name here
            abbreviation: teamAbbreviation,
            conference: "",
            division: ""
        )

        let success = fantasyManager.addPlayer(player, team: team)
        if success {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            showingAddedAlert = true
        } else {
            showingFullAlert = true
        }
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let player: PlayerDTO
    let stats: PlayerStatsDTO

    var body: some View {
        VStack(spacing: 16) {
            // Position-specific stats
            switch player.position {
            case "QB":
                quarterbackStats
            case "RB":
                runningBackStats
            case "WR", "TE":
                receiverStats
            default:
                defensiveStats
            }
        }
    }

    var quarterbackStats: some View {
        VStack(spacing: 16) {
            // Passing stats
            if hasPassingStats {
                StatCategorySection(title: "Passing") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        if let yards = stats.passingYards {
                            StatCard(label: "Passing Yards", value: "\(yards)")
                        }
                        if let tds = stats.passingTouchdowns {
                            StatCard(label: "Touchdowns", value: "\(tds)")
                        }
                        if let ints = stats.passingInterceptions {
                            StatCard(label: "Interceptions", value: "\(ints)")
                        }
                        if let comp = stats.passingCompletions, let att = stats.passingAttempts {
                            StatCard(label: "Completion %", value: String(format: "%.1f%%", Double(comp) / Double(att) * 100))
                        }
                        if let comp = stats.passingCompletions {
                            StatCard(label: "Completions", value: "\(comp)")
                        }
                        if let att = stats.passingAttempts {
                            StatCard(label: "Attempts", value: "\(att)")
                        }
                    }
                }
            }

            // Rushing stats if available
            if hasRushingStats {
                StatCategorySection(title: "Rushing") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        if let yards = stats.rushingYards {
                            StatCard(label: "Rushing Yards", value: "\(yards)")
                        }
                        if let tds = stats.rushingTouchdowns {
                            StatCard(label: "Touchdowns", value: "\(tds)")
                        }
                        if let att = stats.rushingAttempts {
                            StatCard(label: "Attempts", value: "\(att)")
                        }
                    }
                }
            }
        }
    }

    var runningBackStats: some View {
        VStack(spacing: 16) {
            // Rushing stats
            if hasRushingStats {
                StatCategorySection(title: "Rushing") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        if let yards = stats.rushingYards {
                            StatCard(label: "Rushing Yards", value: "\(yards)")
                        }
                        if let tds = stats.rushingTouchdowns {
                            StatCard(label: "Touchdowns", value: "\(tds)")
                        }
                        if let att = stats.rushingAttempts {
                            StatCard(label: "Attempts", value: "\(att)")
                        }
                        if let yards = stats.rushingYards, let att = stats.rushingAttempts, att > 0 {
                            StatCard(label: "Yards/Attempt", value: String(format: "%.1f", Double(yards) / Double(att)))
                        }
                    }
                }
            }

            // Receiving stats if available
            if hasReceivingStats {
                StatCategorySection(title: "Receiving") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        if let yards = stats.receivingYards {
                            StatCard(label: "Receiving Yards", value: "\(yards)")
                        }
                        if let tds = stats.receivingTouchdowns {
                            StatCard(label: "Touchdowns", value: "\(tds)")
                        }
                        if let rec = stats.receptions {
                            StatCard(label: "Receptions", value: "\(rec)")
                        }
                        if let targets = stats.targets {
                            StatCard(label: "Targets", value: "\(targets)")
                        }
                    }
                }
            }
        }
    }

    var receiverStats: some View {
        VStack(spacing: 16) {
            if hasReceivingStats {
                StatCategorySection(title: "Receiving") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        if let yards = stats.receivingYards {
                            StatCard(label: "Receiving Yards", value: "\(yards)")
                        }
                        if let tds = stats.receivingTouchdowns {
                            StatCard(label: "Touchdowns", value: "\(tds)")
                        }
                        if let rec = stats.receptions {
                            StatCard(label: "Receptions", value: "\(rec)")
                        }
                        if let targets = stats.targets {
                            StatCard(label: "Targets", value: "\(targets)")
                        }
                        if let rec = stats.receptions, let targets = stats.targets, targets > 0 {
                            StatCard(label: "Catch %", value: String(format: "%.1f%%", Double(rec) / Double(targets) * 100))
                        }
                        if let yards = stats.receivingYards, let rec = stats.receptions, rec > 0 {
                            StatCard(label: "Yards/Catch", value: String(format: "%.1f", Double(yards) / Double(rec)))
                        }
                    }
                }
            }
        }
    }

    var defensiveStats: some View {
        VStack(spacing: 16) {
            if hasDefensiveStats {
                StatCategorySection(title: "Defense") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        if let tackles = stats.tackles {
                            StatCard(label: "Tackles", value: "\(tackles)")
                        }
                        if let sacks = stats.sacks {
                            StatCard(label: "Sacks", value: String(format: "%.1f", sacks))
                        }
                        if let ints = stats.interceptions {
                            StatCard(label: "Interceptions", value: "\(ints)")
                        }
                    }
                }
            }
        }
    }

    var hasPassingStats: Bool {
        stats.passingYards != nil || stats.passingTouchdowns != nil || stats.passingInterceptions != nil
    }

    var hasRushingStats: Bool {
        stats.rushingYards != nil || stats.rushingTouchdowns != nil || stats.rushingAttempts != nil
    }

    var hasReceivingStats: Bool {
        stats.receivingYards != nil || stats.receivingTouchdowns != nil || stats.receptions != nil
    }

    var hasDefensiveStats: Bool {
        stats.tackles != nil || stats.sacks != nil || stats.interceptions != nil
    }
}

struct StatCategorySection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        PlayerDetailView(
            player: PlayerDTO(
                id: "1",
                name: "Patrick Mahomes",
                position: "QB",
                jerseyNumber: "15",
                photoURL: nil,
                stats: PlayerStatsDTO(
                    passingYards: 4183,
                    passingTouchdowns: 27,
                    passingInterceptions: 14,
                    passingCompletions: 401,
                    passingAttempts: 597,
                    rushingYards: 389,
                    rushingTouchdowns: 4,
                    rushingAttempts: 75
                )
            ),
            teamAbbreviation: "KC"
        )
    }
}
