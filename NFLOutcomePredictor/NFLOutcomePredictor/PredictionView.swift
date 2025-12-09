import SwiftUI

struct PredictionView: View {
    @StateObject private var apiClient = APIClient()
    @State private var homeTeam: TeamDTO?
    @State private var awayTeam: TeamDTO?
    @State private var selectedSeason = Calendar.current.component(.year, from: Date())
    @State private var selectedWeek = 1
    @State private var prediction: PredictionResult?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showingTeamPicker = false
    @State private var pickingHome = true
    @State private var teams: [TeamDTO] = []
    @State private var upcomingGames: [GameDTO] = []
    @State private var selectedUpcomingGameIndex: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current week status bar
                    CurrentWeekStatusView()
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Upcoming games section
                    if !upcomingGames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Upcoming Games")
                                    .font(.headline)
                                Spacer()
                                Text("Tap to predict")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(upcomingGames.prefix(5).enumerated()), id: \.element.id) { index, game in
                                        UpcomingGameCard(game: game, isSelected: selectedUpcomingGameIndex == index)
                                            .onTapGesture {
                                                selectUpcomingGame(at: index)
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)

                        Divider()
                            .padding(.vertical, 8)
                    }

                    // Team selection
                    VStack(spacing: 16) {
                        Text("Or Select Teams Manually")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        TeamPickerButton(
                            label: "Home Team",
                            team: homeTeam,
                            action: {
                                pickingHome = true
                                showingTeamPicker = true
                            }
                        )

                        Image(systemName: "sportscourt")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        TeamPickerButton(
                            label: "Away Team",
                            team: awayTeam,
                            action: {
                                pickingHome = false
                                showingTeamPicker = true
                            }
                        )
                    }
                    .padding()

                    // Season and week - For manual predictions
                    VStack(spacing: 12) {
                        Text("Manual Prediction Settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

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
                                // Clear prediction when season changes
                                prediction = nil
                            }
                        }

                        HStack {
                            Text("Week:")
                                .font(.headline)
                            Picker("Week", selection: $selectedWeek) {
                                ForEach(1...18, id: \.self) { week in
                                    Text(String(week)).tag(week)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedWeek) { _ in
                                // Clear prediction when week changes
                                prediction = nil
                            }
                            Spacer()
                        }

                        Text("Select teams above, then choose season/week and tap 'Make Prediction'")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()

                    // Predict button
                    Button {
                        Task {
                            await makePrediction()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "chart.bar.fill")
                                Text("Make Prediction")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canMakePrediction ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canMakePrediction || isLoading)
                    .padding(.horizontal)

                    // Prediction result
                    if let prediction = prediction {
                        PredictionResultView(prediction: prediction)
                            .padding()
                    }

                    // Error message
                    if let error = error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Game Prediction")
            .sheet(isPresented: $showingTeamPicker) {
                TeamPickerSheet(
                    teams: teams,
                    selectedTeam: pickingHome ? $homeTeam : $awayTeam
                )
            }
            .task {
                await loadTeams()
                await loadUpcomingGames()
            }
        }
    }

    private var canMakePrediction: Bool {
        homeTeam != nil && awayTeam != nil && homeTeam?.abbreviation != awayTeam?.abbreviation
    }

    private func loadTeams() async {
        do {
            teams = try await apiClient.fetchTeams()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadUpcomingGames() async {
        do {
            upcomingGames = try await apiClient.fetchUpcomingGames()
            // Auto-select and predict the first upcoming game
            if !upcomingGames.isEmpty {
                selectUpcomingGame(at: 0)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func selectUpcomingGame(at index: Int) {
        guard index < upcomingGames.count else { return }
        selectedUpcomingGameIndex = index

        let game = upcomingGames[index]
        homeTeam = game.homeTeam
        awayTeam = game.awayTeam
        selectedSeason = game.season ?? Calendar.current.component(.year, from: Date())
        selectedWeek = game.week ?? 1

        // Auto-predict this game
        Task {
            await makePrediction()
        }
    }

    private func makePrediction() async {
        guard let homeTeam = homeTeam, let awayTeam = awayTeam else { return }

        isLoading = true
        error = nil
        prediction = nil

        do {
            prediction = try await apiClient.makePrediction(
                home: homeTeam.abbreviation,
                away: awayTeam.abbreviation
            )
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct TeamPickerButton: View {
    let label: String
    let team: TeamDTO?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let team = team {
                    TeamHelmetView(teamAbbreviation: team.abbreviation, size: 60)
                    Text(team.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                        Image(systemName: "plus.circle")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    Text("Select \(label)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct PredictionResultView: View {
    let prediction: PredictionDTO
    @StateObject private var apiClient = APIClient()
    @State private var homeNews: [ArticleDTO] = []
    @State private var awayNews: [ArticleDTO] = []
    @State private var loadingNews = false

    var winnerTeam: String {
        prediction.homeWinProbability > 0.5 ? prediction.homeTeamAbbreviation : prediction.awayTeamAbbreviation
    }

    var winnerProbability: Double {
        max(prediction.homeWinProbability, 1 - prediction.homeWinProbability)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Current status bar (for reference)
            CurrentWeekStatusView()

            Text("Prediction")
                .font(.title2)
                .fontWeight(.bold)

            // Game details
            VStack(spacing: 8) {
                Text("\(homeTeam?.name ?? "Home") vs \(awayTeam?.name ?? "Away")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Game Prediction")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Prediction Result")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)

            // Winner display
            VStack(spacing: 8) {
                TeamHelmetView(teamAbbreviation: winnerTeam, size: 80)

                Text("\(Int(winnerProbability * 100))% Win Probability")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

            // Predicted Score
            if let homeScore = prediction.predictedHomeScore,
               let awayScore = prediction.predictedAwayScore {
                VStack(spacing: 8) {
                    Text("Predicted Final Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text(prediction.homeTeamAbbreviation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(homeScore)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(homeScore > awayScore ? .primary : .secondary)
                        }

                        Text("-")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        VStack(spacing: 4) {
                            Text(prediction.awayTeamAbbreviation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(awayScore)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(awayScore > homeScore ? .primary : .secondary)
                        }
                    }
                }
                .padding(.vertical, 12)
            }

            // Matchup breakdown
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    TeamHelmetView(teamAbbreviation: prediction.homeTeamAbbreviation, size: 50)
                    Text(prediction.homeTeam.name)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Text("\(Int(prediction.homeWinProbability * 100))%")
                        .font(.headline)
                        .foregroundColor(prediction.homeWinProbability > 0.5 ? .green : .secondary)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("vs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 8) {
                    TeamHelmetView(teamAbbreviation: prediction.awayTeamAbbreviation, size: 50)
                    Text(prediction.awayTeam.name)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Text("\(Int((1 - prediction.homeWinProbability) * 100))%")
                        .font(.headline)
                        .foregroundColor(prediction.homeWinProbability < 0.5 ? .green : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Vegas Odds (if available)
            if let odds = prediction.vegasOdds {
                VegasOddsView(odds: odds, prediction: prediction)
            }

            // Reasoning
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Analysis")
                    .font(.headline)

                Text(prediction.reasoning)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Confidence
            VStack(spacing: 8) {
                HStack {
                    Text("Prediction Confidence")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.subheadline)
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
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Team News Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Latest Team News & Injuries")
                    .font(.headline)
                    .padding(.horizontal)

                if loadingNews {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        if !homeNews.isEmpty {
                            TeamNewsSection(
                                team: prediction.homeTeam,
                                news: homeNews
                            )
                        }

                        if !awayNews.isEmpty {
                            TeamNewsSection(
                                team: prediction.awayTeam,
                                news: awayNews
                            )
                        }

                        if homeNews.isEmpty && awayNews.isEmpty {
                            Text("No recent news available")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
            }
            .task {
                await loadTeamNews()
            }
        }
    }

    private func loadTeamNews() async {
        loadingNews = true
        // News functionality not implemented in current API
        homeNews = []
        awayNews = []
        loadingNews = false
    }
}

struct VegasOddsView: View {
    let odds: VegasOddsDTO
    let prediction: PredictionDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.orange)
                    // Show "(Mock)" if using mock data, otherwise show clean "Vegas Odds"
                    Text(odds.bookmaker.contains("Mock") ? "Vegas Odds (Mock)" : "Vegas Odds")
                        .font(.headline)
                }

                // Show bookmaker as subtitle only for real odds
                if !odds.bookmaker.contains("Mock") {
                    Text("via \(odds.bookmaker)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Spread
            if let spread = odds.spread {
                HStack {
                    Text("Spread:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(prediction.homeTeamAbbreviation) \(spread > 0 ? "+" : "")\(String(format: "%.1f", spread))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Total
            if let total = odds.total {
                HStack {
                    Text("Over/Under:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", total))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Moneylines
            HStack(spacing: 20) {
                if let homeML = odds.homeMoneyline {
                    VStack(spacing: 4) {
                        Text(prediction.homeTeamAbbreviation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(homeML > 0 ? "+\(homeML)" : "\(homeML)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }

                if let awayML = odds.awayMoneyline {
                    VStack(spacing: 4) {
                        Text(prediction.awayTeamAbbreviation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(awayML > 0 ? "+\(awayML)" : "\(awayML)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Implied probabilities
            if let homeProb = odds.homeImpliedProbability,
               let awayProb = odds.awayImpliedProbability {
                Divider()

                HStack {
                    Text("Market Probabilities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text(prediction.homeTeamAbbreviation)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(homeProb * 100))%")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text(prediction.awayTeamAbbreviation)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(awayProb * 100))%")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TeamNewsSection: View {
    let team: TeamDTO
    let news: [ArticleDTO]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TeamHelmetView(teamAbbreviation: team.abbreviation, size: 24)
                Text(team.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)

            ForEach(news, id: \.id) { article in
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.caption)
                        .lineLimit(2)

                    HStack {
                        Text(article.source)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(article.publishedDate, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
}

struct TeamPickerSheet: View {
    let teams: [TeamDTO]
    @Binding var selectedTeam: TeamDTO?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(teams, id: \.abbreviation) { team in
                Button {
                    selectedTeam = team
                    dismiss()
                } label: {
                    HStack {
                        TeamHelmetView(teamAbbreviation: team.abbreviation, size: 40)
                        VStack(alignment: .leading) {
                            Text(team.name)
                                .font(.headline)
                            Text(team.displayName ?? team.abbreviation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedTeam?.abbreviation == team.abbreviation {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

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
                    TeamHelmetView(teamAbbreviation: game.awayTeam.abbreviation, size: 30)
                    Text(game.awayTeam.abbreviation)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }

                Text("@")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                VStack(spacing: 4) {
                    TeamHelmetView(teamAbbreviation: game.homeTeam.abbreviation, size: 30)
                    Text(game.homeTeam.abbreviation)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            }

            // Week indicator
            Text("Week \(game.week)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 140)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    PredictionView()
}
