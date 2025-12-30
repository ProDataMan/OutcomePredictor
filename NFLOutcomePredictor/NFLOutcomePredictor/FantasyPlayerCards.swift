import SwiftUI

/// Player card for fantasy search/add view.
struct FantasyPlayerCard: View {
    let player: PlayerDTO
    let team: TeamDTO
    @ObservedObject var fantasyManager: FantasyTeamManager

    private var isOnRoster: Bool {
        fantasyManager.isOnRoster(player.id)
    }

    private var isPositionFull: Bool {
        fantasyManager.isPositionFull(player.position)
    }

    private var projectedPoints: Double {
        let fantasyPlayer = FantasyPlayer(from: player, team: team)
        return fantasyPlayer.projectedPoints
    }

    var body: some View {
        NavigationLink(destination: PlayerDetailView(player: player, teamAbbreviation: team.abbreviation, showFantasyButton: true)) {
            HStack(spacing: 12) {
                // Player photo with team helmet placeholder
                if let photoURL = player.photoURL, let url = URL(string: photoURL) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            TeamIconView(teamAbbreviation: team.abbreviation, size: 60)
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    TeamIconView(teamAbbreviation: team.abbreviation, size: 60)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(player.name)
                            .font(.headline)
                        if let jersey = player.jerseyNumber {
                            Text("#\(jersey)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(player.position)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)

                        TeamIconView(teamAbbreviation: team.abbreviation, size: 20)

                        Text(team.abbreviation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if player.stats != nil {
                        Text(String(format: "%.1f fantasy pts", projectedPoints))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                if isOnRoster {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        addPlayerToRoster()
                    }) {
                        Image(systemName: isPositionFull ? "person.crop.circle.fill.badge.xmark" : "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(isPositionFull ? .gray : .accentColor)
                    }
                    .disabled(isPositionFull)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func addPlayerToRoster() {
        let success = fantasyManager.addPlayer(player, team: team)
        if success {
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

/// Player card for fantasy roster view.
struct FantasyRosterPlayerCard: View {
    let player: FantasyPlayer
    @ObservedObject var fantasyManager: FantasyTeamManager
    @State private var showingRemoveConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Player photo with team helmet placeholder
            if let photoURL = player.photoURL, let url = URL(string: photoURL) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        TeamIconView(teamAbbreviation: player.teamAbbreviation, size: 50)
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                TeamIconView(teamAbbreviation: player.teamAbbreviation, size: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.name)
                        .font(.headline)
                    if let jersey = player.jerseyNumber {
                        Text("#\(jersey)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    TeamIconView(teamAbbreviation: player.teamAbbreviation, size: 20)
                    Text(player.teamAbbreviation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(String(format: "%.1f pts", player.projectedPoints))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            Spacer()

            Button(action: {
                showingRemoveConfirmation = true
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Remove Player?", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                fantasyManager.removePlayer(player)
            }
        } message: {
            Text("Remove \(player.name) from your fantasy roster?")
        }
    }
}
