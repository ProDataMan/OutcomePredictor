import SwiftUI

struct FantasySettingsView: View {
    @StateObject private var fantasyManager = FantasyTeamManager.shared
    @StateObject private var leagueManager = FantasyLeagueManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var teamName: String = ""
    @State private var editingLeague: FantasyLeague?
    @State private var leagueName: String = ""
    @State private var showingLeagueNameEditor = false

    var body: some View {
        NavigationStack {
            Form {
                // Fantasy Team Name Section
                Section {
                    TextField("Team Name", text: $teamName)
                        .textInputAutocapitalization(.words)

                    Button("Save Team Name") {
                        fantasyManager.updateTeamName(teamName)
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                    .disabled(teamName.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("Fantasy Team")
                } footer: {
                    Text("Choose a unique name for your fantasy team")
                }

                // Current League Section
                if let currentLeague = leagueManager.currentLeague {
                    Section {
                        HStack {
                            Text("League Name")
                            Spacer()
                            Text(currentLeague.name)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Invite Code")
                            Spacer()
                            Text(currentLeague.inviteCode)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                        }

                        HStack {
                            Text("Members")
                            Spacer()
                            Text("\(currentLeague.members.count)")
                                .foregroundColor(.secondary)
                        }

                        Button("Edit League Name") {
                            editingLeague = currentLeague
                            leagueName = currentLeague.name
                            showingLeagueNameEditor = true
                        }
                    } header: {
                        Text("Current League")
                    }
                }

                // All Leagues Section
                if !leagueManager.leagues.isEmpty {
                    Section {
                        ForEach(leagueManager.leagues) { league in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(league.name)
                                        .fontWeight(.semibold)
                                    if league.id == leagueManager.currentLeague?.id {
                                        Text("Current")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.accentColor)
                                            .cornerRadius(4)
                                    }
                                }

                                HStack {
                                    Text(league.inviteCode)
                                        .font(.caption)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(league.members.count) members")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                leagueManager.setCurrentLeague(league)
                            }
                            .contextMenu {
                                Button("Edit Name") {
                                    editingLeague = league
                                    leagueName = league.name
                                    showingLeagueNameEditor = true
                                }

                                Button("Leave League", role: .destructive) {
                                    leagueManager.leaveLeague(league.id)
                                }
                            }
                        }
                    } header: {
                        Text("All Leagues")
                    }
                }

                // Team Settings Summary
                Section {
                    HStack {
                        Text("Total Players")
                        Spacer()
                        Text("\(fantasyManager.roster.totalPlayers)/\(fantasyManager.roster.maxPlayers)")
                            .foregroundColor(.secondary)
                    }

                    if !fantasyManager.roster.allPlayers.isEmpty {
                        Button("Clear Roster", role: .destructive) {
                            confirmClearRoster()
                        }
                    }
                } header: {
                    Text("Roster")
                }
            }
            .navigationTitle("Fantasy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                teamName = fantasyManager.teamName
            }
            .sheet(isPresented: $showingLeagueNameEditor) {
                NavigationStack {
                    Form {
                        Section {
                            TextField("League Name", text: $leagueName)
                                .textInputAutocapitalization(.words)
                        } header: {
                            Text("Edit League Name")
                        } footer: {
                            Text("This will change the league name for all members")
                        }
                    }
                    .navigationTitle("Edit League")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingLeagueNameEditor = false
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if let league = editingLeague {
                                    leagueManager.updateLeagueName(league.id, name: leagueName)
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                }
                                showingLeagueNameEditor = false
                            }
                            .disabled(leagueName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func confirmClearRoster() {
        let alert = UIAlertController(
            title: "Clear Roster?",
            message: "This will remove all players from your fantasy team.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            fantasyManager.clearRoster()
        })

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

#Preview {
    FantasySettingsView()
}
