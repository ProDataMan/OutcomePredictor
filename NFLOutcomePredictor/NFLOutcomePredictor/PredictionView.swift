import SwiftUI

struct PredictionView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var homeTeam: TeamDTO?
    @State private var awayTeam: TeamDTO?
    @State private var selectedSeason = Calendar.current.component(.year, from: Date())
    @State private var selectedWeek: Int?
    @State private var prediction: PredictionResult?
    @State private var isLoadingPrediction = false
    @State private var predictionError: String?
    @State private var showingTeamPicker = false
    @State private var pickingHome = true
    @State private var selectedUpcomingGameIndex: Int?

    // Task management for predictions only
    @State private var predictionTask: Task<Void, Never>?

    // Current week number for highlighting and disabling past weeks
    private var currentWeek: Int? {
        dataManager.upcomingGames.first?.week
    }

    // Available weeks from upcoming games
    private var availableWeeks: [Int] {
        let weeks = Set(dataManager.upcomingGames.compactMap { $0.week })
        return weeks.sorted()
    }

    // Check if a week is in the past
    private func isPastWeek(_ week: Int) -> Bool {
        guard let currentWeek = currentWeek else { return false }
        return week < currentWeek
    }

    // Filter games by selected week
    private var filteredGames: [GameDTO] {
        guard let selectedWeek = selectedWeek else {
            return dataManager.upcomingGames
        }
        return dataManager.upcomingGames.filter { $0.week == selectedWeek }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current week status bar
                    CurrentWeekStatusView()
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Week filter
                    if !availableWeeks.isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Filter by Week:")
                                    .font(.headline)
                                Picker("Week", selection: $selectedWeek) {
                                    Text("All Weeks").tag(nil as Int?)
                                    ForEach(availableWeeks, id: \.self) { week in
                                        HStack {
                                            if week == currentWeek {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                            }
                                            Text("Week \(week)")
                                        }
                                        .tag(week as Int?)
                                        .foregroundColor(isPastWeek(week) ? .secondary : .primary)
                                    }
                                }
                                .pickerStyle(.menu)
                                .onChange(of: selectedWeek) { _ in
                                    // Clear selection when week changes
                                    selectedUpcomingGameIndex = nil
                                }
                            }
                            .padding(.horizontal)

                            // Show current week indicator
                            if let currentWeek = currentWeek {
                                if selectedWeek == nil {
                                    Text("Showing all weeks • Current: Week \(currentWeek)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                } else if selectedWeek == currentWeek {
                                    Text("Current Week")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                        .padding(.horizontal)
                                } else if let selectedWeek = selectedWeek, isPastWeek(selectedWeek) {
                                    Text("Past Week")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }

                    // Upcoming games section
                    if !filteredGames.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Upcoming Games")
                                    .font(.headline)
                                Spacer()
                                if let selectedWeek = selectedWeek {
                                    Text("Week \(selectedWeek)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text("Tap to predict")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(filteredGames.prefix(10).enumerated()), id: \.element.id) { index, game in
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

                    // Predict button
                    Button {
                        makePredictionTask()
                    } label: {
                        HStack {
                            if isLoadingPrediction {
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
                    .disabled(!canMakePrediction || isLoadingPrediction)
                    .padding(.horizontal)

                    // Prediction result
                    if let prediction = prediction {
                        PredictionResultView(prediction: prediction)
                            .padding()
                    }

                    // Error message
                    if let error = predictionError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }

                    // Loading indicator for games
                    if dataManager.isLoadingGames {
                        HStack {
                            ProgressView()
                            Text("Loading upcoming games...")
                        }
                        .padding()
                    }

                    // General error from data manager
                    if let error = dataManager.error {
                        Text(error)
                            .foregroundColor(.orange)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Game Prediction")
            .sheet(isPresented: $showingTeamPicker) {
                TeamPickerSheet(
                    teams: dataManager.teams,
                    selectedTeam: pickingHome ? $homeTeam : $awayTeam
                )
            }
            .task {
                await dataManager.loadTeams()
                await dataManager.loadUpcomingGames()

                // Auto-select current week
                if selectedWeek == nil, let currentWeek = currentWeek {
                    selectedWeek = currentWeek
                }

                // Auto-select first game if available
                if !filteredGames.isEmpty && selectedUpcomingGameIndex == nil {
                    selectUpcomingGame(at: 0)
                }
            }
        }
    }

    private var canMakePrediction: Bool {
        homeTeam != nil && awayTeam != nil && homeTeam?.abbreviation != awayTeam?.abbreviation
    }

    private func selectUpcomingGame(at index: Int) {
        guard index < filteredGames.count else { return }
        selectedUpcomingGameIndex = index

        let game = filteredGames[index]
        homeTeam = game.homeTeam
        awayTeam = game.awayTeam
        selectedSeason = game.season ?? Calendar.current.component(.year, from: Date())

        // Update selected week to match the game's week
        if let gameWeek = game.week {
            selectedWeek = gameWeek
        }

        // Auto-predict this game with proper task management
        makePredictionTask()
    }

    private func makePredictionTask() {
        // Cancel any existing prediction task
        predictionTask?.cancel()

        predictionTask = Task {
            await makePrediction()
        }
    }

    private func makePrediction() async {
        guard let homeTeam = homeTeam, let awayTeam = awayTeam else { return }

        await MainActor.run {
            isLoadingPrediction = true
            predictionError = nil
            prediction = nil
        }

        do {
            let result = try await dataManager.makePrediction(
                home: homeTeam.abbreviation,
                away: awayTeam.abbreviation,
                season: selectedSeason
            )

            // Check if task was cancelled
            guard !Task.isCancelled else { return }

            await MainActor.run {
                prediction = result
                isLoadingPrediction = false
            }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run {
                predictionError = error.localizedDescription
                isLoadingPrediction = false
            }
        }
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
                    TeamIconView(teamAbbreviation: team.abbreviation, size: 60)
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
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct PredictionResultView: View {
    let prediction: PredictionResult

    var body: some View {
        VStack(spacing: 16) {
            // Current status bar (for reference)
            CurrentWeekStatusView()

            Text("Prediction")
                .font(.title2)
                .fontWeight(.bold)

            // Winner display
            VStack(spacing: 8) {
                TeamIconView(teamAbbreviation: prediction.predictedWinner, size: 80)

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
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Analysis")
                    .font(.headline)

                Text(prediction.reasoning ?? "No analysis available")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.systemGray6))
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
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)

            // Model info
            VStack(alignment: .leading, spacing: 8) {
                Text("Model Information")
                    .font(.headline)

                Text("Model: \(prediction.modelVersion ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}


struct TeamPickerSheet: View {
    let teams: [TeamDTO]
    @Binding var selectedTeam: TeamDTO?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(teams) { team in
                    Button {
                        selectedTeam = team
                        dismiss()
                    } label: {
                        HStack {
                            TeamIconView(teamAbbreviation: team.abbreviation, size: 40)
                            VStack(alignment: .leading) {
                                Text(team.name)
                                    .font(.headline)
                                Text("\(team.conference) \(team.division)")
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

#Preview {
    PredictionView()
}
