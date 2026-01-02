import SwiftUI

/// Enhanced player comparison view that supports comparing multiple players.
/// Uses PlayerComparisonResponse DTO for structured comparison data.
struct PlayerComparisonDetailView: View {
    let comparison: PlayerComparisonResponse
    @State private var selectedCategory: StatCategory = .general

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Player headers
                playerHeaders

                // Category selector
                categorySelector

                // Stats comparison grid
                statsGrid

                // Season info
                seasonInfo
            }
            .padding(.vertical)
        }
        .navigationTitle("Player Comparison")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var playerHeaders: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(comparison.players) { player in
                    PlayerComparisonCard(player: player)
                }
            }
            .padding(.horizontal)
        }
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryButton(
                    category: .general,
                    isSelected: selectedCategory == .general
                ) {
                    selectedCategory = .general
                }

                CategoryButton(
                    category: .passing,
                    isSelected: selectedCategory == .passing
                ) {
                    selectedCategory = .passing
                }

                CategoryButton(
                    category: .rushing,
                    isSelected: selectedCategory == .rushing
                ) {
                    selectedCategory = .rushing
                }

                CategoryButton(
                    category: .receiving,
                    isSelected: selectedCategory == .receiving
                ) {
                    selectedCategory = .receiving
                }

                CategoryButton(
                    category: .defense,
                    isSelected: selectedCategory == .defense
                ) {
                    selectedCategory = .defense
                }
            }
            .padding(.horizontal)
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 16) {
            let filteredComparisons = comparison.comparisons.filter { $0.category == selectedCategory }

            if filteredComparisons.isEmpty {
                Text("No \(selectedCategory.rawValue) statistics available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(filteredComparisons) { statComparison in
                    StatComparisonCard(comparison: statComparison)
                }
            }
        }
        .padding(.horizontal)
    }

    private var seasonInfo: some View {
        VStack(spacing: 8) {
            Text("Season: \(comparison.season)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Generated: \(formattedDate)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: comparison.generatedAt)
    }
}

/// Card displaying player information in comparison view.
struct PlayerComparisonCard: View {
    let player: PlayerDTO

    var body: some View {
        VStack(spacing: 12) {
            // Player photo or placeholder
            if let photoURL = player.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }

            Text(player.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(player.position)
                .font(.caption)
                .foregroundColor(.secondary)

            if let jerseyNumber = player.jerseyNumber {
                Text("#\(jerseyNumber)")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundColor(.accentColor)
                    .cornerRadius(8)
            }
        }
        .frame(width: 140)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }
}

/// Category selection button.
struct CategoryButton: View {
    let category: StatCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category.rawValue.capitalized)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

/// Card showing comparison for a specific statistic.
struct StatComparisonCard: View {
    let comparison: StatComparison

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(comparison.statName)
                .font(.headline)

            ForEach(comparison.values) { value in
                HStack {
                    Text(value.playerName)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(value.formattedValue)
                        .font(.subheadline)
                        .fontWeight(value.playerId == comparison.leaderPlayerId ? .bold : .regular)
                        .foregroundColor(value.playerId == comparison.leaderPlayerId ? .green : .primary)

                    if value.playerId == comparison.leaderPlayerId {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                if let percentile = value.percentileRank {
                    ProgressView(value: percentile, total: 100)
                        .tint(percentileColor(percentile))
                }

                if value.playerId != comparison.values.last?.playerId {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    private func percentileColor(_ percentile: Double) -> Color {
        switch percentile {
        case 80...100:
            return .green
        case 50..<80:
            return .blue
        case 25..<50:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    NavigationStack {
        PlayerComparisonDetailView(
            comparison: PlayerComparisonResponse(
                players: [
                    PlayerDTO(
                        id: "1",
                        name: "Patrick Mahomes",
                        position: "QB",
                        jerseyNumber: "15",
                        photoURL: nil,
                        stats: PlayerStatsDTO(
                            passingYards: 4183,
                            passingTouchdowns: 27,
                            passingInterceptions: 14
                        )
                    ),
                    PlayerDTO(
                        id: "2",
                        name: "Josh Allen",
                        position: "QB",
                        jerseyNumber: "17",
                        photoURL: nil,
                        stats: PlayerStatsDTO(
                            passingYards: 3895,
                            passingTouchdowns: 29,
                            passingInterceptions: 18
                        )
                    )
                ],
                comparisons: [
                    StatComparison(
                        id: "passing-yards",
                        statName: "Passing Yards",
                        category: .passing,
                        values: [
                            PlayerStatValue(
                                playerId: "1",
                                playerName: "Patrick Mahomes",
                                value: 4183,
                                formattedValue: "4,183",
                                percentileRank: 85
                            ),
                            PlayerStatValue(
                                playerId: "2",
                                playerName: "Josh Allen",
                                value: 3895,
                                formattedValue: "3,895",
                                percentileRank: 78
                            )
                        ],
                        leaderPlayerId: "1"
                    )
                ],
                season: 2024
            )
        )
    }
}
