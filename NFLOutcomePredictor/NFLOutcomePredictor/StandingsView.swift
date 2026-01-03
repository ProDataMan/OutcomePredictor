import SwiftUI

struct StandingsView: View {
    @State private var standings: LeagueStandings?
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedConference: Conference = .afc
    @State private var sortOption: SortOption = .winPercentage

    enum Conference: String, CaseIterable {
        case afc = "AFC"
        case nfc = "NFC"
    }

    enum SortOption: String, CaseIterable {
        case winPercentage = "Win %"
        case pointsFor = "Points For"
        case pointsAgainst = "Points Against"
        case streak = "Streak"
    }

    var sortedDivisions: [DivisionStandings] {
        guard let standings = standings else { return [] }
        let divisions = selectedConference == .afc ? standings.afcStandings : standings.nfcStandings

        return divisions.map { division in
            let sortedTeams: [TeamStandings]
            switch sortOption {
            case .winPercentage:
                sortedTeams = division.teams.sorted { ($0.winPercentage, $0.wins) > ($1.winPercentage, $1.wins) }
            case .pointsFor:
                sortedTeams = division.teams.sorted { $0.pointsFor > $1.pointsFor }
            case .pointsAgainst:
                sortedTeams = division.teams.sorted { $0.pointsAgainst < $1.pointsAgainst }
            case .streak:
                sortedTeams = division.teams.sorted { compareStreak($0.streak, $1.streak) }
            }
            return DivisionStandings(
                conference: division.conference,
                division: division.division,
                teams: sortedTeams
            )
        }
    }

    private func compareStreak(_ s1: String, _ s2: String) -> Bool {
        let num1 = Int(s1.dropFirst()) ?? 0
        let num2 = Int(s2.dropFirst()) ?? 0
        let isWin1 = s1.hasPrefix("W")
        let isWin2 = s2.hasPrefix("W")

        if isWin1 && !isWin2 { return true }
        if !isWin1 && isWin2 { return false }
        return num1 > num2
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Conference Picker
                Picker("Conference", selection: $selectedConference) {
                    ForEach(Conference.allCases, id: \.self) { conference in
                        Text(conference.rawValue).tag(conference)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Sort Options
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            withAnimation {
                                sortOption = option
                            }
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Sort by: \(sortOption.rawValue)")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                .padding(.horizontal)

                if isLoading {
                    ProgressView("Loading standings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Failed to load standings")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await loadStandings()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let standings = standings {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Season Info
                            VStack(spacing: 4) {
                                Text("\(standings.season) Season")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Last updated: \(standings.lastUpdated)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top)

                            // Division Standings
                            ForEach(sortedDivisions) { division in
                                DivisionStandingsCard(division: division)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadStandings()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No standings data available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Standings")
            .task {
                await loadStandings()
            }
        }
    }

    private func loadStandings() async {
        isLoading = true
        error = nil

        do {
            let apiClient = APIClient()
            standings = try await apiClient.fetchStandings()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct DivisionStandingsCard: View {
    let division: DivisionStandings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Division Header
            Text("\(division.conference) \(division.division)")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 8)

            // Standings Table Header
            HStack(spacing: 0) {
                Text("TEAM")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .leading)
                    .padding(.leading, 16)

                Spacer()

                Text("W")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 30)

                Text("L")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 30)

                Text("T")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 30)

                Text("PCT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 50)

                Text("STRK")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 45)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 4)
            .background(Color(.systemGray6))

            // Team Rows
            ForEach(Array(division.teams.enumerated()), id: \.element.id) { index, team in
                TeamStandingRow(team: team, rank: index + 1)
                if index < division.teams.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TeamStandingRow: View {
    let team: TeamStandings
    let rank: Int

    var body: some View {
        HStack(spacing: 0) {
            // Team Info
            HStack(spacing: 8) {
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                TeamIconView(teamAbbreviation: team.team.abbreviation, size: 24)

                Text(team.team.abbreviation)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(width: 120, alignment: .leading)
            .padding(.leading, 16)

            Spacer()

            // Wins
            Text("\(team.wins)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 30)

            // Losses
            Text("\(team.losses)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 30)

            // Ties
            Text("\(team.ties)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(team.ties > 0 ? .primary : .secondary)
                .frame(width: 30)

            // Win Percentage
            Text(String(format: "%.3f", team.winPercentage))
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 50)

            // Streak
            HStack(spacing: 2) {
                Text(team.streak)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(team.streak.hasPrefix("W") ? .green : team.streak.hasPrefix("L") ? .red : .secondary)
            }
            .frame(width: 45)
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    StandingsView()
}
