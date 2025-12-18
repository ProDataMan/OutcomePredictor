import SwiftUI
import Combine

/// Displays current date/time and NFL season week information as a status bar.
/// This view provides context for users viewing historical data by showing the current time.
struct CurrentWeekStatusView: View {
    @State private var currentDate = Date()
    @State private var currentWeek: Int?
    @State private var currentSeason: Int
    @StateObject private var dataManager = DataManager.shared
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init() {
        _currentSeason = State(initialValue: Calendar.current.component(.year, from: Date()))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Current date and time
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 0) {
                    Text(currentDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(currentDate, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()
                .frame(height: 20)

            // Current NFL week
            HStack(spacing: 6) {
                Image(systemName: "sportscourt")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let week = currentWeek {
                    Text("Week \(week) • \(currentSeason.formatted(.number.grouping(.never)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(currentSeason.formatted(.number.grouping(.never))) Season")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onReceive(timer) { _ in
            currentDate = Date()
        }
        .task {
            await loadCurrentWeek()
        }
    }

    private func loadCurrentWeek() async {
        // Use shared data manager instead of making separate API call
        await dataManager.loadUpcomingGames()

        // Extract week from loaded games
        if let firstGame = dataManager.upcomingGames.first {
            currentWeek = firstGame.week
            currentSeason = firstGame.season ?? Calendar.current.component(.year, from: Date())
        } else {
            // If we can't fetch games, just show the season
            currentWeek = nil
        }
    }
}

#Preview {
    CurrentWeekStatusView()
        .padding()
}
