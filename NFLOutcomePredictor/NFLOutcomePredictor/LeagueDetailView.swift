import SwiftUI

struct LeagueDetailView: View {
    let league: FantasyLeague
    @StateObject private var leagueManager = FantasyLeagueManager.shared
    @State private var selectedTab = 0
    @State private var showingInviteSheet = false
    @State private var showingLeaveConfirmation = false

    var isCommissioner: Bool {
        // Check if current user is commissioner
        // For now, check if first member (simplified)
        league.members.first?.id == league.commissionerId
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Standings").tag(0)
                Text("Members").tag(1)
                Text("Settings").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                standingsView
            } else if selectedTab == 1 {
                membersView
            } else {
                settingsView
            }
        }
        .navigationTitle(league.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingInviteSheet = true
                }) {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingInviteSheet) {
            InviteCodeSheet(league: league)
        }
        .alert("Leave League?", isPresented: $showingLeaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                leagueManager.leaveLeague(league.id)
            }
        } message: {
            Text("Are you sure you want to leave this league?")
        }
    }

    // MARK: - Standings View

    private var standingsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // League stats
                LeagueStatsCard(league: league)
                    .padding(.horizontal)
                    .padding(.top)

                // Standings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Standings")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(league.standings.enumerated()), id: \.element.id) { index, member in
                        StandingsRow(rank: index + 1, member: member)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom)
        }
    }

    // MARK: - Members View

    private var membersView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Member count
                HStack {
                    Text("\(league.members.count) of \(league.settings.maxMembers) Teams")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    if !league.isFull {
                        Button(action: {
                            showingInviteSheet = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.badge.plus")
                                Text("Invite")
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Members list
                ForEach(league.members) { member in
                    MemberCard(
                        member: member,
                        isCommissioner: member.id == league.commissionerId
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
    }

    // MARK: - Settings View

    private var settingsView: some View {
        Form {
            Section("League Details") {
                LabeledContent("Name", value: league.name)
                LabeledContent("Season", value: "\(league.season)")
                LabeledContent("Created", value: league.createdAt.formatted(date: .abbreviated, time: .omitted))
            }

            Section("Rules") {
                LabeledContent("Max Teams", value: "\(league.settings.maxMembers)")
                LabeledContent("Scoring", value: league.settings.scoringType.rawValue)
                LabeledContent("Draft Type", value: league.settings.draftType.rawValue)
            }

            Section("Payment") {
                if !FantasyLeagueManager.paymentsEnabled {
                    HStack {
                        Text("Entry Fee")
                        Spacer()
                        Text("FREE (Beta)")
                            .foregroundColor(.green)
                    }

                    if league.paymentInfo.entryFee > 0 {
                        HStack {
                            Text("Future Fee")
                            Spacer()
                            Text("$\(Int(league.paymentInfo.entryFee))")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    LabeledContent("Entry Fee", value: "$\(Int(league.paymentInfo.entryFee))")
                    LabeledContent("Prize Pool", value: "$\(Int(league.totalPrizePool))")
                    LabeledContent("Platform Fee", value: "\(Int(league.paymentInfo.platformFeePercentage * 100))%")
                }
            }

            Section {
                Button(role: .destructive, action: {
                    showingLeaveConfirmation = true
                }) {
                    Text(isCommissioner ? "Delete League" : "Leave League")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

// MARK: - League Stats Card

struct LeagueStatsCard: View {
    let league: FantasyLeague

    var body: some View {
        VStack(spacing: 16) {
            // Prize pool (if applicable)
            if league.paymentInfo.entryFee > 0 {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prize Pool")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Text("$\(Int(league.totalPrizePool))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)

                            if !FantasyLeagueManager.paymentsEnabled {
                                Text("(Future)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Entry Fee")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !FantasyLeagueManager.paymentsEnabled {
                            Text("FREE")
                                .font(.headline)
                                .foregroundColor(.green)
                        } else {
                            Text("$\(Int(league.paymentInfo.entryFee))")
                                .font(.headline)
                        }
                    }
                }
            }

            // League stats
            HStack(spacing: 20) {
                StatColumn(label: "Teams", value: "\(league.members.count)")
                StatColumn(label: "Scoring", value: league.settings.scoringType.rawValue)
                if let topTeam = league.standings.first {
                    StatColumn(label: "Leader", value: topTeam.name)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatColumn: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Standings Row

struct StandingsRow: View {
    let rank: Int
    let member: LeagueMember

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .foregroundColor(rank <= 3 ? .accentColor : .secondary)
                .frame(width: 30)

            // Team name
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("\(member.wins)-\(member.losses)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(member.paymentStatus.displayText)
                        .font(.caption)
                        .foregroundColor(member.paymentStatus.color)
                }
            }

            Spacer()

            // Points
            Text(String(format: "%.1f", member.totalPoints))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Member Card

struct MemberCard: View {
    let member: LeagueMember
    let isCommissioner: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Member icon
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.name.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(member.name)
                        .font(.headline)

                    if isCommissioner {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                HStack(spacing: 8) {
                    Text("\(member.roster.totalPlayers) players")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(member.paymentStatus.displayText)
                        .font(.caption)
                        .foregroundColor(member.paymentStatus.color)
                }
            }

            Spacer()

            Text(String(format: "%.0f", member.totalPoints))
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Invite Code Sheet

struct InviteCodeSheet: View {
    @Environment(\.dismiss) var dismiss
    let league: FantasyLeague

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)

                VStack(spacing: 8) {
                    Text("Invite Friends")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Share this code with friends to join your league")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Invite code display
                VStack(spacing: 12) {
                    Text(league.inviteCode)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .tracking(8)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    Button(action: {
                        UIPasteboard.general.string = league.inviteCode
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Code")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // League info
                VStack(spacing: 8) {
                    HStack {
                        Text("League:")
                        Spacer()
                        Text(league.name)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Spots Available:")
                        Spacer()
                        Text("\(league.settings.maxMembers - league.members.count)")
                            .fontWeight(.semibold)
                    }

                    if !FantasyLeagueManager.paymentsEnabled {
                        HStack {
                            Text("Entry Fee:")
                            Spacer()
                            Text("FREE (Beta)")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    } else if league.paymentInfo.entryFee > 0 {
                        HStack {
                            Text("Entry Fee:")
                            Spacer()
                            Text("$\(Int(league.paymentInfo.entryFee))")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Invite Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let settings = LeagueSettings.default
    let league = FantasyLeague(
        name: "Friends League",
        commissionerName: "Test User",
        commissionerRoster: FantasyRoster(),
        settings: settings,
        season: 2025
    )
    return NavigationStack {
        LeagueDetailView(league: league)
    }
}
