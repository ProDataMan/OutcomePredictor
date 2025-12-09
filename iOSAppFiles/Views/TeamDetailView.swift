import SwiftUI
import OutcomePredictorAPI

struct TeamDetailView: View {
    let team: TeamDTO
    @StateObject private var apiClient = APIClient()
    @State private var games: [GameDTO] = []
    @State private var news: [ArticleDTO] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Team Header
                VStack(alignment: .leading) {
                    Text(team.name)
                        .font(.largeTitle)
                        .bold()
                    Text("\(team.conference.uppercased()) \(team.division.capitalized)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()

                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Recent Games
                    VStack(alignment: .leading) {
                        Text("Recent Games")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        ForEach(games.prefix(5), id: \.id) { game in
                            GameRowView(game: game, teamAbbr: team.abbreviation)
                        }
                    }

                    // Recent News
                    VStack(alignment: .leading) {
                        Text("Recent News")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                            .padding(.top)

                        ForEach(news.prefix(3), id: \.title) { article in
                            NewsRowView(article: article)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        error = nil

        do {
            async let gamesTask = apiClient.fetchGames(team: team.abbreviation, season: 2024)
            async let newsTask = apiClient.fetchNews(team: team.abbreviation, limit: 5)

            games = try await gamesTask
            news = try await newsTask
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct GameRowView: View {
    let game: GameDTO
    let teamAbbr: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(game.awayTeam.abbreviation) @ \(game.homeTeam.abbreviation)")
                    .font(.headline)
                if let homeScore = game.homeScore,
                   let awayScore = game.awayScore {
                    Text("\(awayScore) - \(homeScore)")
                        .font(.subheadline)
                        .foregroundColor(didWin ? .green : .red)
                }
                Text(game.scheduledDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if game.winner != nil {
                Image(systemName: didWin ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(didWin ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    var didWin: Bool {
        if game.homeTeam.abbreviation == teamAbbr {
            return game.winner == "home"
        } else {
            return game.winner == "away"
        }
    }
}

struct NewsRowView: View {
    let article: ArticleDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
                .font(.headline)
            Text(article.source)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(article.publishedDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
