import SwiftUI

struct GameDetailView: View {
    let game: GameDTO
    let sourceTeam: TeamDTO? // Team we navigated from
    @StateObject private var dataManager = DataManager.shared
    @State private var weather: GameWeatherDTO?
    @State private var isLoadingWeather = false
    @State private var prediction: PredictionResult?
    @State private var isLoadingPrediction = false
    @State private var upcomingGames: [GameDTO] = []
    @State private var news: [ArticleDTO] = []
    @State private var isLoadingNews = false
    @State private var historicalGames: [GameDTO] = []
    @State private var isLoadingHistory = false

    init(game: GameDTO, sourceTeam: TeamDTO? = nil) {
        self.game = game
        self.sourceTeam = sourceTeam
    }

    private var isCompleted: Bool {
        game.status?.lowercased() == "final" || (game.homeScore != nil && game.awayScore != nil && game.status?.lowercased() != "in progress")
    }

    private var isInProgress: Bool {
        game.status?.lowercased() == "in progress" || (game.date < Date() && !isCompleted)
    }

    private var winner: String? {
        guard let homeScore = game.homeScore, let awayScore = game.awayScore else {
            return nil
        }
        if homeScore > awayScore { return game.homeTeam.abbreviation }
        if awayScore > homeScore { return game.awayTeam.abbreviation }
        return nil // Tie
    }

    // Filter upcoming games to only this team's games
    private var filteredUpcomingGames: [GameDTO] {
        guard let sourceTeam = sourceTeam else { return [] }
        return upcomingGames.filter { game in
            game.homeTeam.abbreviation == sourceTeam.abbreviation ||
            game.awayTeam.abbreviation == sourceTeam.abbreviation
        }.prefix(5).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Game status and time
                gameHeaderCard

                // Team matchup
                teamMatchupCard

                // Prediction (for upcoming games)
                if !isCompleted && !isInProgress {
                    predictionCard
                }

                // Live game status (for in-progress games)
                if isInProgress {
                    liveGameCard
                }

                // Weather forecast (for upcoming games)
                if !isCompleted {
                    weatherCard
                }

                // Game stats (if completed)
                if isCompleted {
                    gameStatsCard
                }

                // Other upcoming games for this team
                if !filteredUpcomingGames.isEmpty && sourceTeam != nil {
                    otherUpcomingGamesCard
                }

                // Latest news
                if !news.isEmpty {
                    newsCard
                }

                // Series history
                seriesHistoryCard
            }
            .padding()
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWeather()
            await loadPrediction()
            await loadUpcomingGames()
            await loadNews()
            await loadHistoricalMatchup()
        }
    }

    // MARK: - Game Header

    private var gameHeaderCard: some View {
        VStack(spacing: 12) {
            // Week and Season
            Text("Week \(game.week ?? 0) • \(String(game.season ?? 2025)) Season")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Game date and time
            VStack(spacing: 4) {
                Text(game.date, style: .date)
                    .font(.headline)

                Text(game.date, style: .time)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // Game status
            if isCompleted {
                Text("Final")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(12)
            } else if game.date < Date() {
                Text("In Progress")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
            } else {
                Text("Upcoming")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Team Matchup

    private var teamMatchupCard: some View {
        VStack(spacing: 20) {
            // Away team
            teamRow(team: game.awayTeam, score: game.awayScore, isWinner: winner == game.awayTeam.abbreviation)

            // VS divider
            Text("@")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            // Home team
            teamRow(team: game.homeTeam, score: game.homeScore, isWinner: winner == game.homeTeam.abbreviation)

            // Location
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.secondary)
                Text(locationName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func teamRow(team: TeamDTO, score: Int?, isWinner: Bool) -> some View {
        HStack(spacing: 16) {
            TeamIconView(teamAbbreviation: team.abbreviation, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                    .fontWeight(isWinner ? .bold : .regular)

                Text("\(team.conference) \(team.division)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let score = score {
                Text("\(score)")
                    .font(.system(size: 48, weight: isWinner ? .bold : .regular))
                    .foregroundColor(isWinner ? .accentColor : .primary)
            } else {
                Text("—")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Weather

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Forecast")
                .font(.headline)

            if isLoadingWeather {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let weather = weather {
                HStack(spacing: 20) {
                    // Temperature and condition
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: weatherIcon(for: weather.condition))
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading) {
                                Text("\(Int(weather.temperature))°F")
                                    .font(.title)
                                    .fontWeight(.bold)

                                Text(weather.condition)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Additional details
                        VStack(alignment: .leading, spacing: 4) {
                            weatherDetail(icon: "wind", label: "Wind", value: "\(Int(weather.windSpeed)) mph")
                            weatherDetail(icon: "drop.fill", label: "Precipitation", value: "\(Int(weather.precipitation))%")
                            weatherDetail(icon: "humidity.fill", label: "Humidity", value: "\(Int(weather.humidity))%")
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "cloud.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Weather forecast unavailable")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Check back closer to game time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func weatherDetail(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case let c where c.contains("clear"): return "sun.max.fill"
        case let c where c.contains("cloud"): return "cloud.fill"
        case let c where c.contains("rain"): return "cloud.rain.fill"
        case let c where c.contains("snow"): return "cloud.snow.fill"
        case let c where c.contains("storm"): return "cloud.bolt.fill"
        default: return "cloud.sun.fill"
        }
    }

    // MARK: - Game Stats

    private var gameStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Stats")
                .font(.headline)

            Text("Detailed box score coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()

            // Placeholder for future stats
            // This would include passing yards, rushing yards, turnovers, etc.
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Series History

    private var seriesHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Series History")
                .font(.headline)

            if isLoadingHistory {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if historicalGames.isEmpty {
                Text("No previous matchups found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 4) {
                    // Series record
                    seriesRecord

                    Divider()
                        .padding(.vertical, 8)

                    // Recent games
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last \(min(historicalGames.count, 5)) Meetings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        ForEach(historicalGames.prefix(5), id: \.id) { historicalGame in
                            HistoricalGameRow(
                                game: historicalGame,
                                viewingTeam: sourceTeam?.abbreviation ?? game.homeTeam.abbreviation
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var seriesRecord: some View {
        // Determine which team to show on left (viewing team if available, otherwise home team)
        let leftTeam = sourceTeam?.abbreviation ?? game.homeTeam.abbreviation
        let rightTeam = (leftTeam == game.homeTeam.abbreviation) ? game.awayTeam.abbreviation : game.homeTeam.abbreviation

        let leftTeamWins = historicalGames.filter { historicalGame in
            guard let homeScore = historicalGame.homeScore, let awayScore = historicalGame.awayScore else { return false }
            if historicalGame.homeTeam.abbreviation == leftTeam {
                return homeScore > awayScore
            } else if historicalGame.awayTeam.abbreviation == leftTeam {
                return awayScore > homeScore
            }
            return false
        }.count

        let rightTeamWins = historicalGames.filter { historicalGame in
            guard let homeScore = historicalGame.homeScore, let awayScore = historicalGame.awayScore else { return false }
            if historicalGame.homeTeam.abbreviation == rightTeam {
                return homeScore > awayScore
            } else if historicalGame.awayTeam.abbreviation == rightTeam {
                return awayScore > homeScore
            }
            return false
        }.count

        return HStack(spacing: 20) {
            VStack {
                TeamIconView(teamAbbreviation: leftTeam, size: 40)
                Text("\(leftTeamWins)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("wins")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Text("vs")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack {
                TeamIconView(teamAbbreviation: rightTeam, size: 40)
                Text("\(rightTeamWins)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("wins")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }

    // MARK: - Live Game

    private var liveGameCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "livephoto.play")
                    .foregroundColor(.red)
                Text("LIVE")
                    .font(.headline)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }

            // Score display
            HStack(spacing: 40) {
                // Away team
                VStack(spacing: 8) {
                    TeamIconView(teamAbbreviation: game.awayTeam.abbreviation, size: 50)
                    Text(game.awayTeam.abbreviation)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(game.awayScore ?? 0)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(winner == game.awayTeam.abbreviation ? .green : .primary)
                }
                .frame(maxWidth: .infinity)

                // VS divider with game info
                VStack(spacing: 4) {
                    Text("@")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    if let quarter = game.quarter {
                        Text(quarter)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let timeRemaining = game.timeRemaining {
                        Text(timeRemaining)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Home team
                VStack(spacing: 8) {
                    TeamIconView(teamAbbreviation: game.homeTeam.abbreviation, size: 50)
                    Text(game.homeTeam.abbreviation)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(game.homeScore ?? 0)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(winner == game.homeTeam.abbreviation ? .green : .primary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 2)
        )
    }

    // MARK: - Prediction

    private var predictionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Prediction")
                .font(.headline)

            if isLoadingPrediction {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let prediction = prediction {
                VStack(spacing: 16) {
                    // Winner display
                    VStack(spacing: 8) {
                        TeamIconView(teamAbbreviation: prediction.predictedWinner, size: 60)

                        Text("\(Int(prediction.confidence * 100))% Win Probability")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("Predicted Winner: \(prediction.predictedWinner)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    // AI Analysis
                    if let reasoning = prediction.reasoning {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Analysis")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(reasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Confidence bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("Confidence")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(prediction.confidence * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor)
                                    .frame(width: geometry.size.width * prediction.confidence, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            } else {
                Text("Prediction unavailable")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Other Upcoming Games

    private var otherUpcomingGamesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let team = sourceTeam {
                Text("Other \(team.abbreviation) Games")
                    .font(.headline)
            } else {
                Text("Other Upcoming Games")
                    .font(.headline)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filteredUpcomingGames, id: \.id) { upcomingGame in
                        if upcomingGame.id != game.id {
                            NavigationLink(destination: GameDetailView(game: upcomingGame, sourceTeam: sourceTeam)) {
                                UpcomingGameCard(game: upcomingGame, isSelected: false)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - News

    private var newsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest News")
                .font(.headline)

            if isLoadingNews {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 8) {
                    ForEach(news.prefix(3)) { article in
                        NewsCardView(article: article)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private var locationName: String {
        // Extract city from team name for home team
        let cityMap: [String: String] = [
            "SF": "San Francisco, CA",
            "TB": "Tampa, FL",
            "LAR": "Los Angeles, CA",
            "LAC": "Los Angeles, CA",
            "NYG": "East Rutherford, NJ",
            "NYJ": "East Rutherford, NJ",
            "NE": "Foxborough, MA",
            "GB": "Green Bay, WI",
            "KC": "Kansas City, MO",
            "NO": "New Orleans, LA",
            "BAL": "Baltimore, MD",
            "BUF": "Buffalo, NY",
            "CAR": "Charlotte, NC",
            "CHI": "Chicago, IL",
            "CIN": "Cincinnati, OH",
            "CLE": "Cleveland, OH",
            "DAL": "Arlington, TX",
            "DEN": "Denver, CO",
            "DET": "Detroit, MI",
            "HOU": "Houston, TX",
            "IND": "Indianapolis, IN",
            "JAX": "Jacksonville, FL",
            "LV": "Las Vegas, NV",
            "MIA": "Miami Gardens, FL",
            "MIN": "Minneapolis, MN",
            "PHI": "Philadelphia, PA",
            "PIT": "Pittsburgh, PA",
            "SEA": "Seattle, WA",
            "TEN": "Nashville, TN",
            "WAS": "Landover, MD",
            "ARI": "Glendale, AZ",
            "ATL": "Atlanta, GA"
        ]

        return cityMap[game.homeTeam.abbreviation] ?? "\(game.homeTeam.name) Stadium"
    }

    private func loadWeather() async {
        guard !isCompleted else { return } // Don't fetch weather for completed games

        isLoadingWeather = true

        // For now, generate sample weather data
        // In production, this would call a weather API
        try? await Task.sleep(nanoseconds: 500_000_000) // Simulate API call

        // Sample weather based on location and time of year
        let temp = Double.random(in: 45...75)
        let conditions = ["Clear", "Partly Cloudy", "Cloudy", "Light Rain"]

        weather = GameWeatherDTO(
            temperature: temp,
            condition: conditions.randomElement() ?? "Clear",
            windSpeed: Double.random(in: 5...20),
            precipitation: Double.random(in: 0...30),
            humidity: Double.random(in: 40...70)
        )

        isLoadingWeather = false
    }

    private func loadPrediction() async {
        guard !isCompleted else { return } // Don't predict completed games

        isLoadingPrediction = true

        do {
            let result = try await dataManager.makePrediction(
                home: game.homeTeam.abbreviation,
                away: game.awayTeam.abbreviation,
                season: game.season ?? Calendar.current.component(.year, from: Date())
            )
            prediction = result
        } catch {
            // Silently fail - prediction is not critical
            prediction = nil
        }

        isLoadingPrediction = false
    }

    private func loadUpcomingGames() async {
        guard sourceTeam != nil else { return }

        upcomingGames = dataManager.upcomingGames
        // If empty, try to load
        if upcomingGames.isEmpty {
            await dataManager.loadUpcomingGames()
            upcomingGames = dataManager.upcomingGames
        }
    }

    private func loadNews() async {
        guard let sourceTeam = sourceTeam else { return }

        isLoadingNews = true

        do {
            let apiClient = APIClient()
            news = try await apiClient.fetchNews(teamAbbreviation: sourceTeam.abbreviation, limit: 3)
        } catch {
            // Silently fail - news is not critical
            news = []
        }

        isLoadingNews = false
    }

    private func loadHistoricalMatchup() async {
        isLoadingHistory = true

        do {
            let apiClient = APIClient()

            // Fetch games for both teams and find common matchups
            let currentYear = Calendar.current.component(.year, from: Date())

            var allGames: [GameDTO] = []

            // Fetch last 5 seasons of games
            for season in (currentYear - 4)...currentYear {
                if let homeGames = try? await apiClient.fetchTeamGames(
                    teamAbbreviation: game.homeTeam.abbreviation,
                    season: season
                ) {
                    allGames.append(contentsOf: homeGames)
                }
            }

            // Filter for games where both teams played each other
            historicalGames = allGames.filter { historicalGame in
                (historicalGame.homeTeam.abbreviation == game.homeTeam.abbreviation &&
                 historicalGame.awayTeam.abbreviation == game.awayTeam.abbreviation) ||
                (historicalGame.homeTeam.abbreviation == game.awayTeam.abbreviation &&
                 historicalGame.awayTeam.abbreviation == game.homeTeam.abbreviation)
            }
            .filter { $0.homeScore != nil && $0.awayScore != nil } // Only completed games
            .sorted { $0.date > $1.date } // Most recent first

        } catch {
            // Silently fail - historical data is not critical
            historicalGames = []
        }

        isLoadingHistory = false
    }
}

// Historical Game Row
struct HistoricalGameRow: View {
    let game: GameDTO
    let viewingTeam: String  // The team the user is viewing

    private var result: String {
        guard let homeScore = game.homeScore, let awayScore = game.awayScore else {
            return "N/A"
        }

        // Determine if the viewing team won this historical game
        let viewingTeamIsHome = game.homeTeam.abbreviation == viewingTeam
        let viewingTeamWon: Bool
        let viewingTeamScore: Int
        let opponentScore: Int

        if viewingTeamIsHome {
            viewingTeamWon = homeScore > awayScore
            viewingTeamScore = homeScore
            opponentScore = awayScore
        } else {
            viewingTeamWon = awayScore > homeScore
            viewingTeamScore = awayScore
            opponentScore = homeScore
        }

        let score = "\(viewingTeamScore)-\(opponentScore)"
        return viewingTeamWon ? "W \(score)" : "L \(score)"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // Away team (with @ indicator)
                HStack(spacing: 8) {
                    Text("@")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    TeamIconView(teamAbbreviation: game.awayTeam.abbreviation, size: 20)
                    Text(game.awayTeam.abbreviation)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("\(game.awayScore ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Home team (with house indicator)
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TeamIconView(teamAbbreviation: game.homeTeam.abbreviation, size: 20)
                    Text(game.homeTeam.abbreviation)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("\(game.homeScore ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(result)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(result.hasPrefix("W") ? .green : .red)

                if let season = game.season, let week = game.week {
                    Text("\(String(season)) Wk \(week)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
}

// Import UpcomingGameCard from PredictionView
struct UpcomingGameCard: View {
    let game: GameDTO
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Date and time
            VStack(spacing: 2) {
                Text(game.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(game.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Teams
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    TeamIconView(teamAbbreviation: game.awayTeam.abbreviation, size: 30)
                    Text(game.awayTeam.abbreviation)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }

                Text("@")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                VStack(spacing: 4) {
                    TeamIconView(teamAbbreviation: game.homeTeam.abbreviation, size: 30)
                    Text(game.homeTeam.abbreviation)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            }

            // Week indicator
            Text("Week \(game.week ?? 0)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 140)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color(UIColor.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// NewsCardView for displaying news articles
struct NewsCardView: View {
    let article: ArticleDTO
    @State private var isPressed = false

    var body: some View {
        Group {
            if let urlString = article.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    newsContent
                }
            } else {
                newsContent
            }
        }
    }

    private var newsContent: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                if !article.content.isEmpty {
                    Text(article.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

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

            Spacer()

            // Chevron indicator for clickable articles
            if article.url != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(article.url != nil ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        GameDetailView(
            game: GameDTO(
                id: "123",
                homeTeam: TeamDTO(name: "Kansas City Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
                awayTeam: TeamDTO(name: "San Francisco 49ers", abbreviation: "SF", conference: "NFC", division: "West"),
                date: Date().addingTimeInterval(86400 * 3),
                week: 16,
                season: 2025,
                homeScore: nil,
                awayScore: nil,
                status: "scheduled"
            )
        )
    }
}
