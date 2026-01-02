import SwiftUI

/// Injury detail view showing comprehensive injury reports for both teams.
struct InjuryDetailView: View {
    let game: GameDTO
    let homeTeamReport: TeamInjuryReportDTO
    let awayTeamReport: TeamInjuryReportDTO

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Injury Impact Comparison
                injuryImpactComparisonCard

                // Home Team Injuries
                teamInjuryCard(report: homeTeamReport, isHome: true)

                // Away Team Injuries
                teamInjuryCard(report: awayTeamReport, isHome: false)

                // Injury Legend
                injuryLegendCard
            }
            .padding()
        }
        .navigationTitle("Injury Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                FeedbackButton(pageName: "Injury Report")
            }
        }
    }

    // MARK: - Injury Impact Comparison Card

    private var injuryImpactComparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Injury Impact Analysis")
                .font(.headline)

            // Home team impact
            teamImpactRow(
                teamName: homeTeamReport.team.abbreviation,
                impact: homeTeamReport.totalImpact,
                keyInjuryCount: homeTeamReport.keyInjuries.count
            )

            Divider()

            // Away team impact
            teamImpactRow(
                teamName: awayTeamReport.team.abbreviation,
                impact: awayTeamReport.totalImpact,
                keyInjuryCount: awayTeamReport.keyInjuries.count
            )

            // Impact differential analysis
            let impactDiff = homeTeamReport.totalImpact - awayTeamReport.totalImpact
            if abs(impactDiff) > 0.1 {
                let advantageTeam = impactDiff < 0 ? homeTeamReport.team.abbreviation : awayTeamReport.team.abbreviation

                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("\(advantageTeam) has a health advantage")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func teamImpactRow(teamName: String, impact: Double, keyInjuryCount: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(teamName)
                    .font(.title3)
                    .fontWeight(.bold)

                Text("\(keyInjuryCount) key \(keyInjuryCount == 1 ? "injury" : "injuries")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            impactBadge(impact: impact)
        }
    }

    private func impactBadge(impact: Double) -> some View {
        let (color, label) = impactSeverity(impact)

        return HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .cornerRadius(8)
    }

    private func impactSeverity(_ impact: Double) -> (Color, String) {
        switch impact {
        case ..<0.2:
            return (.green, "Low")
        case 0.2..<0.4:
            return (.yellow, "Medium")
        case 0.4..<0.6:
            return (.orange, "High")
        default:
            return (.red, "Severe")
        }
    }

    // MARK: - Team Injury Card

    private func teamInjuryCard(report: TeamInjuryReportDTO, isHome: Bool) -> some View {
        let location = isHome ? "Home" : "Away"

        return VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(report.team.name)
                    .font(.headline)

                Text("\(location) Team • \(report.injuries.count) \(report.injuries.count == 1 ? "injury" : "injuries")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Injuries list
            if report.injuries.isEmpty {
                noInjuriesView
            } else {
                ForEach(report.injuries, id: \.name) { injury in
                    injuryListItem(injury: injury)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var noInjuriesView: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text("No reported injuries")
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    private func injuryListItem(injury: InjuredPlayerDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Player name and status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(injury.name)
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Text(injury.position)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                injuryStatusBadge(status: injury.status)
            }

            // Description if available
            if let description = injury.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Impact indicator
            let impact = injury.impact
            if impact > 0.3 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)

                    Text("High impact player")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    private func injuryStatusBadge(status: String) -> some View {
        let (color, backgroundColor) = statusColors(status)

        return Text(status)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(6)
    }

    private func statusColors(_ status: String) -> (Color, Color) {
        switch status.uppercased() {
        case "OUT":
            return (Color(red: 0.827, green: 0.184, blue: 0.184), Color(red: 1.0, green: 0.804, blue: 0.824))
        case "DOUBTFUL":
            return (Color(red: 0.902, green: 0.290, blue: 0.098), Color(red: 1.0, green: 0.8, blue: 0.737))
        case "QUESTIONABLE":
            return (Color(red: 0.961, green: 0.486, blue: 0.0), Color(red: 1.0, green: 0.878, blue: 0.698))
        case "PROBABLE":
            return (Color(red: 0.984, green: 0.753, blue: 0.176), Color(red: 1.0, green: 0.976, blue: 0.769))
        default:
            return (Color(red: 0.220, green: 0.557, blue: 0.235), Color(red: 0.784, green: 0.902, blue: 0.788))
        }
    }

    // MARK: - Injury Legend Card

    private var injuryLegendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Injury Status Guide")
                .font(.subheadline)
                .fontWeight(.bold)

            legendItem(status: "Out", description: "Will not play in the game")
            legendItem(status: "Doubtful", description: "Unlikely to play (25% chance)")
            legendItem(status: "Questionable", description: "Uncertain to play (50% chance)")
            legendItem(status: "Probable", description: "Likely to play (75% chance)")
            legendItem(status: "Healthy", description: "No injury concerns")
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(12)
    }

    private func legendItem(status: String, description: String) -> some View {
        HStack(spacing: 8) {
            injuryStatusBadge(status: status)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct InjuryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InjuryDetailView(
                game: GameDTO(
                    id: "test-game",
                    homeTeam: TeamDTO(name: "Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
                    awayTeam: TeamDTO(name: "Bills", abbreviation: "BUF", conference: "AFC", division: "East"),
                    date: Date(),
                    week: 1,
                    season: 2024
                ),
                homeTeamReport: TeamInjuryReportDTO(
                    team: TeamDTO(name: "Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
                    injuries: [
                        InjuredPlayerDTO(name: "Patrick Mahomes", position: "QB", status: "Questionable", description: "Ankle")
                    ],
                    fetchedAt: Date()
                ),
                awayTeamReport: TeamInjuryReportDTO(
                    team: TeamDTO(name: "Bills", abbreviation: "BUF", conference: "AFC", division: "East"),
                    injuries: [],
                    fetchedAt: Date()
                )
            )
        }
    }
}
