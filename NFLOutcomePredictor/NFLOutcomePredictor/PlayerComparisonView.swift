import SwiftUI

/// Player comparison view for side-by-side stats analysis.
struct PlayerComparisonView: View {
    let player1: PlayerDTO
    let player2: PlayerDTO
    let team1: TeamDTO
    let team2: TeamDTO

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Player headers
                HStack(spacing: 20) {
                    PlayerComparisonHeader(player: player1, team: team1)
                    Divider()
                    PlayerComparisonHeader(player: player2, team: team2)
                }
                .padding()

                // Position comparison
                if player1.position == player2.position {
                    statsComparisonSection
                } else {
                    Text("Players play different positions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }

                // Recommendation
                recommendationSection
            }
        }
        .navigationTitle("Player Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statsComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats Comparison")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            switch player1.position {
            case "QB":
                quarterbackStatsComparison
            case "RB":
                runningBackStatsComparison
            case "WR", "TE":
                receiverStatsComparison
            default:
                Text("Stats not available for this position")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    private var quarterbackStatsComparison: some View {
        VStack(spacing: 12) {
            StatComparisonRow(
                label: "Passing Yards",
                value1: player1.stats?.passingYards,
                value2: player2.stats?.passingYards
            )
            StatComparisonRow(
                label: "Passing TDs",
                value1: player1.stats?.passingTouchdowns,
                value2: player2.stats?.passingTouchdowns
            )
            StatComparisonRow(
                label: "Interceptions",
                value1: player1.stats?.passingInterceptions,
                value2: player2.stats?.passingInterceptions,
                lowerIsBetter: true
            )
            StatComparisonRow(
                label: "Completion %",
                value1: player1.stats?.completions != nil && player1.stats?.attempts != nil && player1.stats!.attempts! > 0
                    ? Int((Double(player1.stats!.completions!) / Double(player1.stats!.attempts!)) * 100)
                    : nil,
                value2: player2.stats?.completions != nil && player2.stats?.attempts != nil && player2.stats!.attempts! > 0
                    ? Int((Double(player2.stats!.completions!) / Double(player2.stats!.attempts!)) * 100)
                    : nil
            )
        }
        .padding(.horizontal)
    }

    private var runningBackStatsComparison: some View {
        VStack(spacing: 12) {
            StatComparisonRow(
                label: "Rushing Yards",
                value1: player1.stats?.rushingYards,
                value2: player2.stats?.rushingYards
            )
            StatComparisonRow(
                label: "Rushing TDs",
                value1: player1.stats?.rushingTouchdowns,
                value2: player2.stats?.rushingTouchdowns
            )
            StatComparisonRow(
                label: "Receptions",
                value1: player1.stats?.receptions,
                value2: player2.stats?.receptions
            )
            StatComparisonRow(
                label: "Receiving Yards",
                value1: player1.stats?.receivingYards,
                value2: player2.stats?.receivingYards
            )
        }
        .padding(.horizontal)
    }

    private var receiverStatsComparison: some View {
        VStack(spacing: 12) {
            StatComparisonRow(
                label: "Receptions",
                value1: player1.stats?.receptions,
                value2: player2.stats?.receptions
            )
            StatComparisonRow(
                label: "Receiving Yards",
                value1: player1.stats?.receivingYards,
                value2: player2.stats?.receivingYards
            )
            StatComparisonRow(
                label: "Receiving TDs",
                value1: player1.stats?.receivingTouchdowns,
                value2: player2.stats?.receivingTouchdowns
            )
            StatComparisonRow(
                label: "Targets",
                value1: player1.stats?.targets,
                value2: player2.stats?.targets
            )
        }
        .padding(.horizontal)
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendation")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                if player1.position == player2.position {
                    let winner = determineWinner()
                    Text(winner.message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text("Cannot compare players at different positions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func determineWinner() -> (player: PlayerDTO, message: String) {
        guard player1.stats != nil && player2.stats != nil else {
            return (player1, "Insufficient stats for comparison")
        }

        let score1 = calculateScore(for: player1)
        let score2 = calculateScore(for: player2)

        if abs(score1 - score2) < 10 {
            return (player1, "Both players have similar production. Either is a good choice.")
        } else if score1 > score2 {
            return (player1, "\(player1.name) has the statistical edge with better overall production.")
        } else {
            return (player2, "\(player2.name) has the statistical edge with better overall production.")
        }
    }

    private func calculateScore(for player: PlayerDTO) -> Double {
        guard let stats = player.stats else { return 0 }
        var score = 0.0

        switch player.position {
        case "QB":
            score += Double(stats.passingYards ?? 0) * 0.04
            score += Double(stats.passingTouchdowns ?? 0) * 4.0
            score -= Double(stats.passingInterceptions ?? 0) * 2.0
        case "RB":
            score += Double(stats.rushingYards ?? 0) * 0.1
            score += Double(stats.rushingTouchdowns ?? 0) * 6.0
            score += Double(stats.receivingYards ?? 0) * 0.1
            score += Double(stats.receivingTouchdowns ?? 0) * 6.0
        case "WR", "TE":
            score += Double(stats.receivingYards ?? 0) * 0.1
            score += Double(stats.receivingTouchdowns ?? 0) * 6.0
            score += Double(stats.receptions ?? 0) * 0.5
        default:
            break
        }

        return score
    }
}

struct PlayerComparisonHeader: View {
    let player: PlayerDTO
    let team: TeamDTO

    var body: some View {
        VStack(spacing: 12) {
            TeamIconView(teamAbbreviation: team.abbreviation, size: 60)

            Text(player.name)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(player.position)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(team.abbreviation)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(TeamBranding.branding(for: team.abbreviation).primaryColor.opacity(0.2))
                .foregroundColor(TeamBranding.branding(for: team.abbreviation).primaryColor)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatComparisonRow: View {
    let label: String
    let value1: Int?
    let value2: Int?
    var lowerIsBetter: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                // Player 1
                StatBar(
                    value: value1,
                    maxValue: max(value1 ?? 0, value2 ?? 0),
                    isWinner: determineWinner() == 1,
                    alignment: .trailing
                )

                // Player 2
                StatBar(
                    value: value2,
                    maxValue: max(value1 ?? 0, value2 ?? 0),
                    isWinner: determineWinner() == 2,
                    alignment: .leading
                )
            }
        }
    }

    private func determineWinner() -> Int? {
        guard let v1 = value1, let v2 = value2 else { return nil }
        if v1 == v2 { return nil }
        if lowerIsBetter {
            return v1 < v2 ? 1 : 2
        } else {
            return v1 > v2 ? 1 : 2
        }
    }
}

struct StatBar: View {
    let value: Int?
    let maxValue: Int
    let isWinner: Bool
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(value != nil ? "\(value!)" : "-")
                .font(.caption)
                .fontWeight(isWinner ? .bold : .regular)
                .foregroundColor(isWinner ? .green : .primary)

            GeometryReader { geo in
                let width = maxValue > 0 ? (Double(value ?? 0) / Double(maxValue)) * geo.size.width : 0
                ZStack(alignment: alignment == .leading ? .leading : .trailing) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(isWinner ? Color.green : Color.accentColor)
                        .frame(width: width)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        PlayerComparisonView(
            player1: PlayerDTO(
                id: "1",
                name: "Patrick Mahomes",
                position: "QB",
                jerseyNumber: "15",
                photoURL: nil,
                stats: PlayerStatsDTO(
                    passingYards: 4183,
                    passingTouchdowns: 27,
                    passingInterceptions: 14,
                    completions: 401,
                    attempts: 597
                )
            ),
            player2: PlayerDTO(
                id: "2",
                name: "Josh Allen",
                position: "QB",
                jerseyNumber: "17",
                photoURL: nil,
                stats: PlayerStatsDTO(
                    passingYards: 3895,
                    passingTouchdowns: 29,
                    passingInterceptions: 18,
                    completions: 359,
                    attempts: 541
                )
            ),
            team1: TeamDTO(name: "Kansas City Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
            team2: TeamDTO(name: "Buffalo Bills", abbreviation: "BUF", conference: "AFC", division: "East")
        )
    }
}
