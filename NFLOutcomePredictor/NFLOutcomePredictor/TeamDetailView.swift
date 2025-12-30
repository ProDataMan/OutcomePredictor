import SwiftUI

struct TeamDetailView: View {
    let team: TeamDTO
    @StateObject private var dataManager = DataManager.shared
    @State private var games: [GameDTO] = []
    @State private var news: [ArticleDTO] = []
    @State private var roster: TeamRosterDTO?
    @State private var isLoadingGames = false
    @State private var isLoadingNews = false
    @State private var isLoadingRoster = false
    @State private var selectedSeason = Calendar.current.component(.year, from: Date())
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current week status bar
                CurrentWeekStatusView()
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Team header
                TeamHeaderView(team: team)

                // Season selector
                HStack {
                    Text("Season:")
                        .font(.headline)
                    Picker("Season", selection: $selectedSeason) {
                        ForEach(2020...2025, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedSeason) { _ in
                        Task {
                            await loadGames()
                        }
                    }
                }
                .padding(.horizontal)

                // Games section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Games")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if isLoadingGames {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if games.isEmpty {
                        Text("No games found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(games, id: \.id) { game in
                            NavigationLink(destination: GameDetailView(game: game, sourceTeam: team)) {
                                GameCardView(game: game, teamAbbreviation: team.abbreviation)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                }

                // Player Stats section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Players")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if isLoadingRoster {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let roster = roster {
                        PlayerStatsSection(roster: roster)
                    } else {
                        Text("Player stats unavailable")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }

                // News section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Latest News")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if isLoadingNews {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if news.isEmpty {
                        Text("No news available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ForEach(news) { article in
                            NewsCardView(article: article)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadGames()
            await loadNews()
            await loadRoster()
        }
    }

    private func loadGames() async {
        isLoadingGames = true

        do {
            let apiClient = APIClient()
            let allGames = try await apiClient.fetchTeamGames(teamAbbreviation: team.abbreviation, season: selectedSeason)

            // Show all games sorted by date (newest first for current season, all games for past seasons)
            let currentYear = Calendar.current.component(.year, from: Date())

            if selectedSeason >= currentYear {
                // For current/future seasons, show only remaining games
                let now = Date()
                games = allGames.filter { game in
                    game.homeScore == nil && game.awayScore == nil || game.date > now
                }
                .sorted { $0.date < $1.date }
            } else {
                // For past seasons, show all games sorted by week
                games = allGames.sorted { ($0.week ?? 0) < ($1.week ?? 0) }
            }
        } catch {
            // Silently fail - games are not critical
            games = []
        }

        isLoadingGames = false
    }

    private func loadNews() async {
        isLoadingNews = true

        do {
            let apiClient = APIClient()
            news = try await apiClient.fetchNews(teamAbbreviation: team.abbreviation, limit: 5)
        } catch {
            // Silently fail - news is not critical
            news = []
        }

        isLoadingNews = false
    }

    private func loadRoster() async {
        isLoadingRoster = true

        do {
            let apiClient = APIClient()
            roster = try await apiClient.fetchRoster(teamAbbreviation: team.abbreviation, season: selectedSeason)

            // Debug logging to verify data
            if let roster = roster {
                print("✅ Loaded roster for \(team.abbreviation): \(roster.players.count) players")
                let playersWithPhotos = roster.players.filter { $0.photoURL != nil && !$0.photoURL!.isEmpty }
                print("📸 Players with photoURL: \(playersWithPhotos.count) / \(roster.players.count)")

                // Show first 3 players as sample
                for (index, player) in roster.players.prefix(3).enumerated() {
                    print("  \(index + 1). \(player.name)")
                    print("     photoURL: \(player.photoURL ?? "nil")")
                    print("     stats: \(player.stats != nil ? "present" : "nil")")
                }
            }
        } catch {
            // Silently fail - roster is not critical
            print("❌ Failed to load roster: \(error.localizedDescription)")
            roster = nil
        }

        isLoadingRoster = false
    }
}

// MARK: - Player Stats Section

struct PlayerStatsSection: View {
    let roster: TeamRosterDTO

    var keyPlayers: [PlayerDTO] {
        // Show QBs, top RBs, top WRs, top TEs
        let qbs = roster.players.filter { $0.position == "QB" }
        let rbs = roster.players.filter { $0.position == "RB" }.sorted {
            ($0.stats?.rushingYards ?? 0) > ($1.stats?.rushingYards ?? 0)
        }.prefix(2)
        let wrs = roster.players.filter { $0.position == "WR" }.sorted {
            ($0.stats?.receivingYards ?? 0) > ($1.stats?.receivingYards ?? 0)
        }.prefix(2)
        let tes = roster.players.filter { $0.position == "TE" }.sorted {
            ($0.stats?.receivingYards ?? 0) > ($1.stats?.receivingYards ?? 0)
        }.prefix(1)

        return Array(qbs) + Array(rbs) + Array(wrs) + Array(tes)
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(keyPlayers) { player in
                NavigationLink(destination: PlayerDetailView(player: player, teamAbbreviation: roster.team.abbreviation)) {
                    PlayerStatCard(player: player, teamAbbreviation: roster.team.abbreviation)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}

struct PlayerStatCard: View {
    let player: PlayerDTO
    let teamAbbreviation: String

    var body: some View {
        HStack(spacing: 12) {
            // Player photo with team helmet placeholder
            if let photoURL = player.photoURL, let url = URL(string: photoURL) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        TeamIconView(teamAbbreviation: teamAbbreviation, size: 50)
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                TeamIconView(teamAbbreviation: teamAbbreviation, size: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.name)
                        .font(.headline)
                    if let jersey = player.jerseyNumber {
                        Text("#\(jersey)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(player.position)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let stats = player.stats {
                    PlayerStatsRow(player: player, stats: stats)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PlayerStatsRow: View {
    let player: PlayerDTO
    let stats: PlayerStatsDTO

    var body: some View {
        HStack(spacing: 16) {
            switch player.position {
            case "QB":
                if let yards = stats.passingYards {
                    StatPill(label: "YDS", value: "\(yards)")
                }
                if let tds = stats.passingTouchdowns {
                    StatPill(label: "TD", value: "\(tds)")
                }
                if let ints = stats.passingInterceptions {
                    StatPill(label: "INT", value: "\(ints)")
                }

            case "RB":
                if let yards = stats.rushingYards {
                    StatPill(label: "YDS", value: "\(yards)")
                }
                if let tds = stats.rushingTouchdowns {
                    StatPill(label: "TD", value: "\(tds)")
                }

            case "WR", "TE":
                if let yards = stats.receivingYards {
                    StatPill(label: "YDS", value: "\(yards)")
                }
                if let tds = stats.receivingTouchdowns {
                    StatPill(label: "TD", value: "\(tds)")
                }
                if let rec = stats.receptions {
                    StatPill(label: "REC", value: "\(rec)")
                }

            default:
                if let tackles = stats.tackles {
                    StatPill(label: "TKL", value: "\(tackles)")
                }
                if let sacks = stats.sacks {
                    StatPill(label: "SCK", value: String(format: "%.1f", sacks))
                }
            }
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(6)
    }
}

struct TeamHeaderView: View {
    let team: TeamDTO

    var body: some View {
        VStack(spacing: 16) {
            TeamIconView(teamAbbreviation: team.abbreviation, size: 120)

            VStack(spacing: 4) {
                Text(team.name)
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(team.conference) \(team.division)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [
                    TeamBranding.branding(for: team.abbreviation).primaryColor.opacity(0.1),
                    TeamBranding.branding(for: team.abbreviation).secondaryColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct GameCardView: View {
    let game: GameDTO
    let teamAbbreviation: String

    var isHomeGame: Bool {
        game.homeTeam.abbreviation == teamAbbreviation
    }

    var opponent: String {
        isHomeGame ? game.awayTeam.abbreviation : game.homeTeam.abbreviation
    }

    var gameResult: String? {
        guard let homeScore = game.homeScore, let awayScore = game.awayScore else {
            return nil
        }

        let teamScore = isHomeGame ? homeScore : awayScore
        let oppScore = isHomeGame ? awayScore : homeScore

        if teamScore > oppScore {
            return "W \(teamScore)-\(oppScore)"
        } else if teamScore < oppScore {
            return "L \(teamScore)-\(oppScore)"
        } else {
            return "T \(teamScore)-\(oppScore)"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Week \(game.week ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text(isHomeGame ? "vs" : "@")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)

                    TeamIconView(teamAbbreviation: opponent, size: 32)

                    Text(opponent)
                        .font(.headline)
                }
            }

            Spacer()

            if let result = gameResult {
                Text(result)
                    .font(.headline)
                    .foregroundColor(result.hasPrefix("W") ? .green : result.hasPrefix("L") ? .red : .orange)
                    .frame(width: 70, alignment: .trailing)
            } else {
                Text(game.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(team: TeamDTO(
            name: "Kansas City Chiefs",
            abbreviation: "KC",
            conference: "AFC",
            division: "West"
        ))
    }
}
