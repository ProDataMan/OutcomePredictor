import SwiftUI
import OutcomePredictorAPI

struct PredictionView: View {
    @StateObject private var apiClient = APIClient()
    @State private var homeTeam: TeamDTO?
    @State private var awayTeam: TeamDTO?
    @State private var selectedSeason = 2024
    @State private var selectedWeek = 1
    @State private var prediction: PredictionDTO?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showingTeamPicker = false
    @State private var pickingHome = true
    @State private var teams: [TeamDTO] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Team selection
                    VStack(spacing: 16) {
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

                    // Season and week
                    VStack(spacing: 12) {
                        HStack {
                            Text("Season:")
                                .font(.headline)
                            Picker("Season", selection: $selectedSeason) {
                                ForEach(2020...2024, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .pickerStyle(.segmented)
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
                            Spacer()
                        }
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

    private func makePrediction() async {
        guard let homeTeam = homeTeam, let awayTeam = awayTeam else { return }

        isLoading = true
        error = nil
        prediction = nil

        do {
            prediction = try await apiClient.makePrediction(
                home: homeTeam.abbreviation,
                away: awayTeam.abbreviation,
                season: selectedSeason,
                week: selectedWeek
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

    var winnerTeam: String {
        prediction.homeWinProbability > 0.5 ? prediction.homeTeamAbbreviation : prediction.awayTeamAbbreviation
    }

    var winnerProbability: Double {
        max(prediction.homeWinProbability, 1 - prediction.homeWinProbability)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Prediction")
                .font(.title2)
                .fontWeight(.bold)

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

            // Matchup breakdown
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    TeamHelmetView(teamAbbreviation: prediction.homeTeamAbbreviation, size: 50)
                    Text(prediction.homeTeamAbbreviation)
                        .font(.caption)
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
                    Text(prediction.awayTeamAbbreviation)
                        .font(.caption)
                    Text("\(Int((1 - prediction.homeWinProbability) * 100))%")
                        .font(.headline)
                        .foregroundColor(prediction.homeWinProbability < 0.5 ? .green : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Reasoning
            VStack(alignment: .leading, spacing: 8) {
                Text("Analysis")
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
                    Text("Confidence")
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
                            Text("\(team.conference.uppercased()) \(team.division.capitalized)")
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

#Preview {
    PredictionView()
}
