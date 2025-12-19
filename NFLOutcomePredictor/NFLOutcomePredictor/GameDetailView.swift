import SwiftUI

struct GameDetailView: View {
    let game: GameDTO
    @State private var weather: GameWeatherDTO?
    @State private var isLoadingWeather = false

    private var isCompleted: Bool {
        game.homeScore != nil && game.awayScore != nil
    }

    private var winner: String? {
        guard let homeScore = game.homeScore, let awayScore = game.awayScore else {
            return nil
        }
        if homeScore > awayScore { return game.homeTeam.abbreviation }
        if awayScore > homeScore { return game.awayTeam.abbreviation }
        return nil // Tie
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Game status and time
                gameHeaderCard

                // Team matchup
                teamMatchupCard

                // Weather forecast (for upcoming games)
                if !isCompleted {
                    weatherCard
                }

                // Game stats (if completed)
                if isCompleted {
                    gameStatsCard
                }

                // Series history
                seriesHistoryCard
            }
            .padding()
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWeather()
        }
    }

    // MARK: - Game Header

    private var gameHeaderCard: some View {
        VStack(spacing: 12) {
            // Week and Season
            Text("Week \(game.week ?? 0) • \(game.season ?? 2025) Season")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Game date and time
            VStack(spacing: 4) {
                Text(game.date, style: .date)
                    .font(.headline)

                Text(game.date, style: .time)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // Game status
            if isCompleted {
                Text("Final")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(12)
            } else if game.date < Date() {
                Text("In Progress")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
            } else {
                Text("Upcoming")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Team Matchup

    private var teamMatchupCard: some View {
        VStack(spacing: 20) {
            // Away team
            teamRow(team: game.awayTeam, score: game.awayScore, isWinner: winner == game.awayTeam.abbreviation)

            // VS divider
            Text("@")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            // Home team
            teamRow(team: game.homeTeam, score: game.homeScore, isWinner: winner == game.homeTeam.abbreviation)

            // Location
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.secondary)
                Text(locationName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func teamRow(team: TeamDTO, score: Int?, isWinner: Bool) -> some View {
        HStack(spacing: 16) {
            TeamIconView(teamAbbreviation: team.abbreviation, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                    .fontWeight(isWinner ? .bold : .regular)

                Text("\(team.conference) \(team.division)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let score = score {
                Text("\(score)")
                    .font(.system(size: 48, weight: isWinner ? .bold : .regular))
                    .foregroundColor(isWinner ? .accentColor : .primary)
            } else {
                Text("—")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Weather

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Forecast")
                .font(.headline)

            if isLoadingWeather {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let weather = weather {
                HStack(spacing: 20) {
                    // Temperature and condition
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: weatherIcon(for: weather.condition))
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading) {
                                Text("\(Int(weather.temperature))°F")
                                    .font(.title)
                                    .fontWeight(.bold)

                                Text(weather.condition)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Additional details
                        VStack(alignment: .leading, spacing: 4) {
                            weatherDetail(icon: "wind", label: "Wind", value: "\(Int(weather.windSpeed)) mph")
                            weatherDetail(icon: "drop.fill", label: "Precipitation", value: "\(Int(weather.precipitation))%")
                            weatherDetail(icon: "humidity.fill", label: "Humidity", value: "\(Int(weather.humidity))%")
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "cloud.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Weather forecast unavailable")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Check back closer to game time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func weatherDetail(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case let c where c.contains("clear"): return "sun.max.fill"
        case let c where c.contains("cloud"): return "cloud.fill"
        case let c where c.contains("rain"): return "cloud.rain.fill"
        case let c where c.contains("snow"): return "cloud.snow.fill"
        case let c where c.contains("storm"): return "cloud.bolt.fill"
        default: return "cloud.sun.fill"
        }
    }

    // MARK: - Game Stats

    private var gameStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Stats")
                .font(.headline)

            Text("Detailed box score coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()

            // Placeholder for future stats
            // This would include passing yards, rushing yards, turnovers, etc.
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Series History

    private var seriesHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Series History")
                .font(.headline)

            Text("Historical matchup data coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()

            // This would show last 5-10 games between these teams
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private var locationName: String {
        // Extract city from team name for home team
        let cityMap: [String: String] = [
            "SF": "San Francisco, CA",
            "TB": "Tampa, FL",
            "LAR": "Los Angeles, CA",
            "LAC": "Los Angeles, CA",
            "NYG": "East Rutherford, NJ",
            "NYJ": "East Rutherford, NJ",
            "NE": "Foxborough, MA",
            "GB": "Green Bay, WI",
            "KC": "Kansas City, MO",
            "NO": "New Orleans, LA",
            "BAL": "Baltimore, MD",
            "BUF": "Buffalo, NY",
            "CAR": "Charlotte, NC",
            "CHI": "Chicago, IL",
            "CIN": "Cincinnati, OH",
            "CLE": "Cleveland, OH",
            "DAL": "Arlington, TX",
            "DEN": "Denver, CO",
            "DET": "Detroit, MI",
            "HOU": "Houston, TX",
            "IND": "Indianapolis, IN",
            "JAX": "Jacksonville, FL",
            "LV": "Las Vegas, NV",
            "MIA": "Miami Gardens, FL",
            "MIN": "Minneapolis, MN",
            "PHI": "Philadelphia, PA",
            "PIT": "Pittsburgh, PA",
            "SEA": "Seattle, WA",
            "TEN": "Nashville, TN",
            "WAS": "Landover, MD",
            "ARI": "Glendale, AZ",
            "ATL": "Atlanta, GA"
        ]

        return cityMap[game.homeTeam.abbreviation] ?? "\(game.homeTeam.name) Stadium"
    }

    private func loadWeather() async {
        guard !isCompleted else { return } // Don't fetch weather for completed games

        isLoadingWeather = true

        // For now, generate sample weather data
        // In production, this would call a weather API
        try? await Task.sleep(nanoseconds: 500_000_000) // Simulate API call

        // Sample weather based on location and time of year
        let temp = Double.random(in: 45...75)
        let conditions = ["Clear", "Partly Cloudy", "Cloudy", "Light Rain"]

        weather = GameWeatherDTO(
            temperature: temp,
            condition: conditions.randomElement() ?? "Clear",
            windSpeed: Double.random(in: 5...20),
            precipitation: Double.random(in: 0...30),
            humidity: Double.random(in: 40...70)
        )

        isLoadingWeather = false
    }
}

#Preview {
    NavigationStack {
        GameDetailView(
            game: GameDTO(
                id: "123",
                homeTeam: TeamDTO(name: "Kansas City Chiefs", abbreviation: "KC", conference: "AFC", division: "West"),
                awayTeam: TeamDTO(name: "San Francisco 49ers", abbreviation: "SF", conference: "NFC", division: "West"),
                date: Date().addingTimeInterval(86400 * 3),
                week: 16,
                season: 2025,
                homeScore: nil,
                awayScore: nil,
                status: "scheduled"
            )
        )
    }
}
