import SwiftUI

/// Detailed standings view for a specific division.
struct StandingsDetailView: View {
    let division: DivisionStandings
    let season: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Division Header
                divisionHeader

                // Standings Table
                standingsTable

                // Division Stats Summary
                divisionStatsSummary
            }
            .padding(.vertical)
        }
        .navigationTitle("\(division.conference) \(division.division)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var divisionHeader: some View {
        VStack(spacing: 12) {
            Text("\(division.conference) \(division.division)")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(season) Season")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var standingsTable: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 8) {
                Text("Rank")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)

                Text("Team")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("W-L")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .center)

                Text("PCT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .center)

                Text("PF")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .center)

                Text("PA")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6))

            // Team Rows
            ForEach(Array(division.teams.enumerated()), id: \.element.id) { index, standing in
                StandingRow(rank: index + 1, standing: standing)

                if index < division.teams.count - 1 {
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var divisionStatsSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Division Statistics")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DivisionStatCard(
                    title: "Avg Points For",
                    value: String(format: "%.1f", averagePointsFor)
                )

                DivisionStatCard(
                    title: "Avg Points Against",
                    value: String(format: "%.1f", averagePointsAgainst)
                )

                DivisionStatCard(
                    title: "Division Leader",
                    value: division.teams.first?.team.abbreviation ?? "-"
                )

                DivisionStatCard(
                    title: "Best Record",
                    value: division.teams.first?.record ?? "-"
                )
            }
            .padding(.horizontal)
        }
    }

    private var averagePointsFor: Double {
        let total = division.teams.reduce(0) { $0 + $1.pointsFor }
        return Double(total) / Double(division.teams.count)
    }

    private var averagePointsAgainst: Double {
        let total = division.teams.reduce(0) { $0 + $1.pointsAgainst }
        return Double(total) / Double(division.teams.count)
    }
}

/// Individual standing row in the table.
struct StandingRow: View {
    let rank: Int
    let standing: TeamStandings

    var body: some View {
        HStack(spacing: 8) {
            Text("\(rank)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(rankColor)
                .frame(width: 40, alignment: .leading)

            HStack(spacing: 8) {
                TeamIconView(teamAbbreviation: standing.team.abbreviation, size: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(standing.team.abbreviation)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(standing.streak)
                        .font(.caption2)
                        .foregroundColor(streakColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(standing.record)
                .font(.subheadline)
                .monospacedDigit()
                .frame(width: 60, alignment: .center)

            Text(String(format: ".%03d", Int(standing.winPercentage * 1000)))
                .font(.subheadline)
                .monospacedDigit()
                .frame(width: 50, alignment: .center)

            Text("\(standing.pointsFor)")
                .font(.subheadline)
                .monospacedDigit()
                .frame(width: 40, alignment: .center)

            Text("\(standing.pointsAgainst)")
                .font(.subheadline)
                .monospacedDigit()
                .frame(width: 40, alignment: .center)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var rankColor: Color {
        switch rank {
        case 1:
            return .green
        case 2:
            return .blue
        default:
            return .secondary
        }
    }

    private var streakColor: Color {
        if standing.streak.starts(with: "W") {
            return .green
        } else if standing.streak.starts(with: "L") {
            return .red
        } else {
            return .secondary
        }
    }
}

/// Small stat card for division statistics.
private struct DivisionStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        StandingsDetailView(
            division: DivisionStandings(
                conference: "AFC",
                division: "West",
                teams: [
                    TeamStandings(
                        team: TeamDTO(name: "Kansas City Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
                        wins: 11,
                        losses: 3,
                        ties: 0,
                        winPercentage: 0.786,
                        pointsFor: 385,
                        pointsAgainst: 298,
                        divisionWins: 4,
                        divisionLosses: 1,
                        conferenceWins: 8,
                        conferenceLosses: 2,
                        streak: "W3"
                    ),
                    TeamStandings(
                        team: TeamDTO(name: "Las Vegas Raiders", abbreviation: "LV", conference: "AFC", division: "West"),
                        wins: 6,
                        losses: 8,
                        ties: 0,
                        winPercentage: 0.429,
                        pointsFor: 312,
                        pointsAgainst: 345,
                        divisionWins: 2,
                        divisionLosses: 3,
                        conferenceWins: 4,
                        conferenceLosses: 6,
                        streak: "L2"
                    )
                ]
            ),
            season: 2024
        )
    }
}
