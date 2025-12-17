import SwiftUI

struct TeamDetailView: View {
    let team: TeamDTO
    @StateObject private var apiClient = APIClient()
    @State private var games: [GameDTO] = []
    @State private var news: [ArticleDTO] = []
    @State private var isLoadingGames = false
    @State private var isLoadingNews = false
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
                            GameCardView(game: game, teamAbbreviation: team.abbreviation)
                        }
                        .padding(.horizontal)
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
                        ForEach(news, id: \.id) { article in
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
            await loadData()
        }
    }

    private func loadData() async {
        await loadGames()
        await loadNews()
    }

    private func loadGames() async {
        isLoadingGames = true
        do {
            // Use the team details endpoint instead of team-specific games
            // For now, show upcoming games as a fallback
            let upcomingGames = try await apiClient.fetchUpcomingGames()
            // Filter games that involve this team
            games = upcomingGames.filter { game in
                game.homeTeam.abbreviation == team.abbreviation ||
                game.awayTeam.abbreviation == team.abbreviation
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingGames = false
    }

    private func loadNews() async {
        isLoadingNews = true
        // News functionality not implemented in current API
        // Leave news array empty for now
        news = []
        isLoadingNews = false
    }
}

struct TeamHeaderView: View {
    let team: TeamDTO

    var body: some View {
        VStack(spacing: 16) {
            TeamHelmetView(teamAbbreviation: team.abbreviation, size: 120)

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
        game.homeTeamAbbreviation == teamAbbreviation
    }

    var opponent: String {
        isHomeGame ? game.awayTeamAbbreviation : game.homeTeamAbbreviation
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

                    TeamHelmetView(teamAbbreviation: opponent, size: 32)

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

struct NewsCardView: View {
    let article: ArticleDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.headline)
                .lineLimit(2)

            HStack {
                Text(article.source)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary)

                Text(article.publishedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(team: TeamDTO(
            id: "kc",
            name: "Kansas City Chiefs",
            abbreviation: "KC"
        ))
    }
}
