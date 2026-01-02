import SwiftUI

/// Weather detail view showing comprehensive weather forecast and team performance in weather conditions.
struct WeatherDetailView: View {
    let game: GameDTO
    let weather: GameWeatherDTO
    let homeTeamStats: TeamWeatherStatsDTO?
    let awayTeamStats: TeamWeatherStatsDTO?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Weather Forecast
                currentWeatherCard

                // Weather Impact Analysis
                weatherImpactCard

                // Home Team Weather Performance
                if let homeTeamStats = homeTeamStats {
                    teamWeatherPerformanceCard(
                        teamStats: homeTeamStats,
                        isHome: true
                    )
                }

                // Away Team Weather Performance
                if let awayTeamStats = awayTeamStats {
                    teamWeatherPerformanceCard(
                        teamStats: awayTeamStats,
                        isHome: false
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Weather Forecast")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                FeedbackButton(pageName: "Weather Detail")
            }
        }
    }

    // MARK: - Current Weather Card

    private var currentWeatherCard: some View {
        VStack(spacing: 16) {
            // Weather icon and temperature
            Image(systemName: weatherIcon(for: weather.condition))
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("\(Int(weather.temperature))°F")
                .font(.system(size: 48, weight: .bold))

            Text(weather.condition)
                .font(.title2)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 4)

            // Weather details grid
            HStack(spacing: 32) {
                weatherDetailItem(
                    icon: "wind",
                    label: "Wind",
                    value: "\(Int(weather.windSpeed)) mph"
                )

                weatherDetailItem(
                    icon: "humidity",
                    label: "Humidity",
                    value: "\(Int(weather.humidity))%"
                )

                weatherDetailItem(
                    icon: "cloud.rain",
                    label: "Precip",
                    value: "\(Int(weather.precipitation))%"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func weatherDetailItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Weather Impact Card

    private var weatherImpactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Impact")
                .font(.headline)

            ForEach(analyzeWeatherImpact(), id: \.title) { impact in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: impact.icon)
                        .foregroundColor(impact.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(impact.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(impact.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private struct WeatherImpact {
        let icon: String
        let color: Color
        let title: String
        let description: String
    }

    private func analyzeWeatherImpact() -> [WeatherImpact] {
        var impacts: [WeatherImpact] = []

        // Temperature impact
        if weather.temperature < 32 {
            impacts.append(
                WeatherImpact(
                    icon: "snowflake",
                    color: .blue,
                    title: "Freezing Conditions",
                    description: "Below-freezing temperatures can affect ball handling and favor running game"
                )
            )
        } else if weather.temperature > 85 {
            impacts.append(
                WeatherImpact(
                    icon: "sun.max.fill",
                    color: .orange,
                    title: "Hot Weather",
                    description: "High temperatures may lead to fatigue and increased injury risk"
                )
            )
        }

        // Wind impact
        if weather.windSpeed > 15 {
            impacts.append(
                WeatherImpact(
                    icon: "wind",
                    color: .cyan,
                    title: "High Winds",
                    description: "Strong winds can affect passing game and kicking accuracy"
                )
            )
        }

        // Precipitation impact
        if weather.precipitation > 50 {
            impacts.append(
                WeatherImpact(
                    icon: "cloud.rain.fill",
                    color: .gray,
                    title: "Rain Expected",
                    description: "Wet conditions favor running game and increase fumble risk"
                )
            )
        }

        // Default message if no significant impact
        if impacts.isEmpty {
            impacts.append(
                WeatherImpact(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "Favorable Conditions",
                    description: "Weather conditions should not significantly impact gameplay"
                )
            )
        }

        return impacts
    }

    // MARK: - Team Weather Performance Card

    private func teamWeatherPerformanceCard(teamStats: TeamWeatherStatsDTO, isHome: Bool) -> some View {
        let stats = isHome ? teamStats.homeStats : teamStats.awayStats
        let location = isHome ? "Home" : "Away"

        return VStack(alignment: .leading, spacing: 12) {
            Text("\(teamStats.teamAbbreviation) Weather Performance (\(location))")
                .font(.headline)

            conditionStatsRow(title: "Clear", stats: stats.clear)
            conditionStatsRow(title: "Rain", stats: stats.rain)
            conditionStatsRow(title: "Snow", stats: stats.snow)
            conditionStatsRow(title: "Wind", stats: stats.wind)
            conditionStatsRow(title: "Cold", stats: stats.cold)
            conditionStatsRow(title: "Hot", stats: stats.hot)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func conditionStatsRow(title: String, stats: ConditionStatsDTO) -> some View {
        Group {
            if stats.games > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Text("\(stats.wins)-\(stats.losses) (\(Int(stats.winPercentage))%)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(stats.winPercentage >= 50 ? .green : .red)
                    }

                    HStack {
                        Text("Games: \(stats.games)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Avg Scored: \(Int(stats.avgPointsScored))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Avg Allowed: \(Int(stats.avgPointsAllowed))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Helper Functions

    private func weatherIcon(for condition: String) -> String {
        let lowercased = condition.lowercased()

        if lowercased.contains("clear") || lowercased.contains("sunny") {
            return "sun.max.fill"
        } else if lowercased.contains("cloud") {
            return "cloud.fill"
        } else if lowercased.contains("rain") || lowercased.contains("shower") {
            return "cloud.rain.fill"
        } else if lowercased.contains("snow") {
            return "snow"
        } else if lowercased.contains("wind") {
            return "wind"
        } else if lowercased.contains("fog") || lowercased.contains("mist") {
            return "cloud.fog.fill"
        } else {
            return "cloud.fill"
        }
    }
}

// MARK: - Preview

struct WeatherDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WeatherDetailView(
                game: GameDTO(
                    id: "test-game",
                    homeTeam: TeamDTO(name: "Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
                    awayTeam: TeamDTO(name: "Bills", abbreviation: "BUF", conference: "AFC", division: "East"),
                    date: Date(),
                    week: 1,
                    season: 2024
                ),
                weather: GameWeatherDTO(
                    temperature: 45,
                    condition: "Clear",
                    windSpeed: 12,
                    precipitation: 10,
                    humidity: 55
                ),
                homeTeamStats: nil,
                awayTeamStats: nil
            )
        }
    }
}
