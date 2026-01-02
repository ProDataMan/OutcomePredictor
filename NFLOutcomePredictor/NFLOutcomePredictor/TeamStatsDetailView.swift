import SwiftUI

/// Detailed team statistics view showing comprehensive season data.
struct TeamStatsDetailView: View {
    let teamStats: TeamStatsDTO

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Team Header
                teamHeader

                // Rankings Overview
                if let rankings = teamStats.rankings {
                    rankingsSection(rankings)
                }

                // Offensive Stats
                offensiveStatsSection

                // Defensive Stats
                defensiveStatsSection

                // Key Players
                if !teamStats.keyPlayers.isEmpty {
                    keyPlayersSection
                }

                // Recent Games
                if !teamStats.recentGames.isEmpty {
                    recentGamesSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("\(teamStats.team.abbreviation) Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var teamHeader: some View {
        VStack(spacing: 12) {
            TeamIconView(teamAbbreviation: teamStats.team.abbreviation, size: 100)

            Text(teamStats.team.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("\(teamStats.season) Season")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack {
                    Text(teamStats.team.conference)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Conference")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 30)

                VStack {
                    Text(teamStats.team.division)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Division")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    private func rankingsSection(_ rankings: TeamRankingsDTO) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rankings")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let offRank = rankings.offensiveRank {
                    RankCard(title: "Offense", rank: offRank)
                }

                if let defRank = rankings.defensiveRank {
                    RankCard(title: "Defense", rank: defRank)
                }

                if let passOffRank = rankings.passingOffenseRank {
                    RankCard(title: "Pass Offense", rank: passOffRank)
                }

                if let rushOffRank = rankings.rushingOffenseRank {
                    RankCard(title: "Rush Offense", rank: rushOffRank)
                }

                if let passDefRank = rankings.passingDefenseRank {
                    RankCard(title: "Pass Defense", rank: passDefRank)
                }

                if let rushDefRank = rankings.rushingDefenseRank {
                    RankCard(title: "Rush Defense", rank: rushDefRank)
                }
            }
            .padding(.horizontal)
        }
    }

    private var offensiveStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Offensive Stats")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                StatRow(
                    label: "Points Per Game",
                    value: String(format: "%.1f", teamStats.offensiveStats.pointsPerGame)
                )

                StatRow(
                    label: "Yards Per Game",
                    value: String(format: "%.1f", teamStats.offensiveStats.yardsPerGame)
                )

                StatRow(
                    label: "Passing Yards/Game",
                    value: String(format: "%.1f", teamStats.offensiveStats.passingYardsPerGame)
                )

                StatRow(
                    label: "Rushing Yards/Game",
                    value: String(format: "%.1f", teamStats.offensiveStats.rushingYardsPerGame)
                )

                if let thirdDown = teamStats.offensiveStats.thirdDownConversionRate {
                    StatRow(
                        label: "3rd Down Conversion",
                        value: String(format: "%.1f%%", thirdDown * 100)
                    )
                }

                if let redZone = teamStats.offensiveStats.redZoneEfficiency {
                    StatRow(
                        label: "Red Zone Efficiency",
                        value: String(format: "%.1f%%", redZone * 100)
                    )
                }

                if let turnovers = teamStats.offensiveStats.turnoversPerGame {
                    StatRow(
                        label: "Turnovers Per Game",
                        value: String(format: "%.1f", turnovers)
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var defensiveStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Defensive Stats")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                StatRow(
                    label: "Points Allowed/Game",
                    value: String(format: "%.1f", teamStats.defensiveStats.pointsAllowedPerGame)
                )

                StatRow(
                    label: "Yards Allowed/Game",
                    value: String(format: "%.1f", teamStats.defensiveStats.yardsAllowedPerGame)
                )

                StatRow(
                    label: "Pass Yards Allowed/Game",
                    value: String(format: "%.1f", teamStats.defensiveStats.passingYardsAllowedPerGame)
                )

                StatRow(
                    label: "Rush Yards Allowed/Game",
                    value: String(format: "%.1f", teamStats.defensiveStats.rushingYardsAllowedPerGame)
                )

                if let sacks = teamStats.defensiveStats.sacksPerGame {
                    StatRow(
                        label: "Sacks Per Game",
                        value: String(format: "%.1f", sacks)
                    )
                }

                if let ints = teamStats.defensiveStats.interceptionsPerGame {
                    StatRow(
                        label: "Interceptions Per Game",
                        value: String(format: "%.1f", ints)
                    )
                }

                if let fumbles = teamStats.defensiveStats.forcedFumblesPerGame {
                    StatRow(
                        label: "Forced Fumbles/Game",
                        value: String(format: "%.1f", fumbles)
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var keyPlayersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Players")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(teamStats.keyPlayers) { player in
                        KeyPlayerCard(player: player)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Games")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(teamStats.recentGames.prefix(5), id: \.id) { game in
                    RecentGameRow(game: game, teamAbbr: teamStats.team.abbreviation)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Card displaying team ranking information.
struct RankCard: View {
    let title: String
    let rank: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("#\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    private var rankColor: Color {
        switch rank {
        case 1...5:
            return .green
        case 6...16:
            return .blue
        case 17...26:
            return .orange
        default:
            return .red
        }
    }
}

/// Row displaying a stat label and value.
struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

/// Card displaying key player information.
struct KeyPlayerCard: View {
    let player: PlayerDTO

    var body: some View {
        VStack(spacing: 8) {
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
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 60, height: 60)
            }

            Text(player.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(player.position)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

/// Row displaying recent game information.
struct RecentGameRow: View {
    let game: GameDTO
    let teamAbbr: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(opponentText)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(dateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let homeScore = game.homeScore, let awayScore = game.awayScore {
                Text(scoreText(homeScore: homeScore, awayScore: awayScore))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(resultColor(homeScore: homeScore, awayScore: awayScore))
            } else {
                Text(game.status ?? "Scheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }

    private var opponentText: String {
        let isHome = game.homeTeam.abbreviation == teamAbbr
        let opponent = isHome ? game.awayTeam.abbreviation : game.homeTeam.abbreviation
        return "\(isHome ? "vs" : "@") \(opponent)"
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: game.date)
    }

    private func scoreText(homeScore: Int, awayScore: Int) -> String {
        let isHome = game.homeTeam.abbreviation == teamAbbr
        let teamScore = isHome ? homeScore : awayScore
        let oppScore = isHome ? awayScore : homeScore
        return "\(teamScore) - \(oppScore)"
    }

    private func resultColor(homeScore: Int, awayScore: Int) -> Color {
        let isHome = game.homeTeam.abbreviation == teamAbbr
        let won = isHome ? homeScore > awayScore : awayScore > homeScore
        return won ? .green : .red
    }
}

#Preview {
    NavigationStack {
        TeamStatsDetailView(
            teamStats: TeamStatsDTO(
                team: TeamDTO(name: "Kansas City Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
                season: 2024,
                offensiveStats: OffensiveStatsDTO(
                    pointsPerGame: 28.5,
                    yardsPerGame: 385.2,
                    passingYardsPerGame: 275.8,
                    rushingYardsPerGame: 109.4,
                    thirdDownConversionRate: 0.45,
                    redZoneEfficiency: 0.62,
                    turnoversPerGame: 1.2
                ),
                defensiveStats: DefensiveStatsDTO(
                    pointsAllowedPerGame: 21.3,
                    yardsAllowedPerGame: 325.5,
                    passingYardsAllowedPerGame: 220.4,
                    rushingYardsAllowedPerGame: 105.1,
                    sacksPerGame: 2.8,
                    interceptionsPerGame: 1.1,
                    forcedFumblesPerGame: 0.9
                ),
                rankings: TeamRankingsDTO(
                    offensiveRank: 3,
                    defensiveRank: 10,
                    passingOffenseRank: 2,
                    rushingOffenseRank: 12,
                    passingDefenseRank: 15,
                    rushingDefenseRank: 8,
                    totalRank: 5
                )
            )
        )
    }
}
