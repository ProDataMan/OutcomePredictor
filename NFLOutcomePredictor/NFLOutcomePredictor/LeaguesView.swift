import SwiftUI

struct LeaguesView: View {
    @StateObject private var leagueManager = FantasyLeagueManager.shared
    @StateObject private var fantasyManager = FantasyTeamManager.shared
    @State private var showingCreateLeague = false
    @State private var showingJoinLeague = false
    @State private var userName = UserDefaults.standard.string(forKey: "fantasy_user_name") ?? ""

    var body: some View {
        NavigationStack {
            Group {
                if leagueManager.leagues.isEmpty {
                    emptyLeaguesView
                } else {
                    leaguesList
                }
            }
            .navigationTitle("My Leagues")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingCreateLeague = true
                        }) {
                            Label("Create League", systemImage: "plus.circle")
                        }

                        Button(action: {
                            showingJoinLeague = true
                        }) {
                            Label("Join League", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateLeague) {
                CreateLeagueView(userName: $userName)
            }
            .sheet(isPresented: $showingJoinLeague) {
                JoinLeagueView(userName: $userName)
            }
        }
    }

    private var emptyLeaguesView: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("No Leagues Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create or join a fantasy league to compete with friends")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Button(action: {
                    showingCreateLeague = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create League")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Button(action: {
                    showingJoinLeague = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join League")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            // Payment beta notice
            if !FantasyLeagueManager.paymentsEnabled {
                BetaPaymentNotice()
                    .padding(.top, 24)
            }
        }
        .padding()
    }

    private var leaguesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Payment beta notice
                if !FantasyLeagueManager.paymentsEnabled {
                    BetaPaymentNotice()
                        .padding(.horizontal)
                        .padding(.top)
                }

                // Leagues
                ForEach(leagueManager.leagues) { league in
                    NavigationLink(destination: LeagueDetailView(league: league)) {
                        LeagueCard(league: league)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

// MARK: - League Card

struct LeagueCard: View {
    let league: FantasyLeague

    private var userMember: LeagueMember? {
        // Find current user in league
        league.members.first // Simplified for now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(league.name)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(league.members.count)/\(league.settings.maxMembers)")
                            .font(.caption)

                        if !FantasyLeagueManager.paymentsEnabled {
                            Text("•")
                                .font(.caption)
                            Text("FREE Beta")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else if league.paymentInfo.entryFee > 0 {
                            Text("•")
                                .font(.caption)
                            Text("$\(Int(league.paymentInfo.entryFee))")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                if let member = userMember {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.1f pts", member.totalPoints))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)

                        if let rank = league.standings.firstIndex(where: { $0.id == member.id }) {
                            Text("#\(rank + 1) of \(league.members.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Prize pool (if payments enabled in future)
            if FantasyLeagueManager.paymentsEnabled && league.paymentInfo.entryFee > 0 {
                HStack {
                    Text("Prize Pool:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(Int(league.totalPrizePool))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Beta Payment Notice

struct BetaPaymentNotice: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("Free During Beta")
                    .font(.headline)
                    .foregroundColor(.green)

                Text("Entry fees are FREE until we reach 1,000 downloads. Join now and play free!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Create League View

struct CreateLeagueView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var leagueManager = FantasyLeagueManager.shared
    @StateObject private var fantasyManager = FantasyTeamManager.shared
    @Binding var userName: String

    @State private var leagueName = ""
    @State private var maxMembers = 10
    @State private var scoringType: ScoringType = .ppr
    @State private var entryFee: Double = 10.0
    @State private var showingNameAlert = false

    private let memberOptions = [6, 8, 10, 12, 14]
    private let feeOptions = [0.0, 5.0, 10.0, 20.0, 50.0]

    var body: some View {
        NavigationStack {
            Form {
                Section("League Info") {
                    TextField("League Name", text: $leagueName)

                    TextField("Your Team Name", text: $userName)
                        .onChange(of: userName) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "fantasy_user_name")
                        }
                }

                Section("Settings") {
                    Picker("Max Teams", selection: $maxMembers) {
                        ForEach(memberOptions, id: \.self) { count in
                            Text("\(count) Teams").tag(count)
                        }
                    }

                    Picker("Scoring", selection: $scoringType) {
                        ForEach(ScoringType.allCases, id: \.self) { type in
                            VStack(alignment: .leading) {
                                Text(type.rawValue)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(type)
                        }
                    }
                }

                Section {
                    Picker("Entry Fee", selection: $entryFee) {
                        ForEach(feeOptions, id: \.self) { fee in
                            if fee == 0 {
                                Text("Free").tag(fee)
                            } else {
                                HStack {
                                    Text("$\(Int(fee))")
                                    if !FantasyLeagueManager.paymentsEnabled {
                                        Text("(FREE NOW)")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                                .tag(fee)
                            }
                        }
                    }
                } header: {
                    Text("Entry Fee")
                } footer: {
                    if !FantasyLeagueManager.paymentsEnabled {
                        Text("Entry fees are FREE during beta. Payments will be enabled after 1,000 downloads. Winners receive 90% of the prize pool.")
                    } else {
                        Text("Winners receive 90% of the prize pool (10% platform fee)")
                    }
                }

                if entryFee > 0 {
                    Section("Prize Distribution") {
                        HStack {
                            Text("Total Prize Pool")
                            Spacer()
                            Text("$\(Int(entryFee * Double(maxMembers)))")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Winner Gets")
                            Spacer()
                            Text("$\(Int(entryFee * Double(maxMembers) * 0.9))")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Text("Platform Fee (10%)")
                            Spacer()
                            Text("$\(Int(entryFee * Double(maxMembers) * 0.1))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Create League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createLeague()
                    }
                    .disabled(leagueName.isEmpty || userName.isEmpty)
                }
            }
            .alert("Team Name Required", isPresented: $showingNameAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter your team name to continue.")
            }
        }
    }

    private func createLeague() {
        guard !userName.isEmpty else {
            showingNameAlert = true
            return
        }

        let settings = LeagueSettings(
            maxMembers: maxMembers,
            scoringType: scoringType,
            draftType: .manual,
            entryFee: entryFee,
            playoffWeeks: 3,
            tradeDeadlineWeek: 13
        )

        let league = FantasyLeague(
            name: leagueName,
            commissionerName: userName,
            commissionerRoster: fantasyManager.roster,
            settings: settings,
            season: Calendar.current.component(.year, from: Date())
        )

        leagueManager.createLeague(league)
        dismiss()
    }
}

// MARK: - Join League View

struct JoinLeagueView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var leagueManager = FantasyLeagueManager.shared
    @StateObject private var fantasyManager = FantasyTeamManager.shared
    @Binding var userName: String

    @State private var inviteCode = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)

                VStack(spacing: 8) {
                    Text("Join a League")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter the invite code shared by your league commissioner")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    TextField("Your Team Name", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: userName) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "fantasy_user_name")
                        }

                    TextField("Invite Code", text: $inviteCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal)

                Button(action: {
                    joinLeague()
                }) {
                    Text("Join League")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userName.isEmpty || inviteCode.isEmpty ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(userName.isEmpty || inviteCode.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Join League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func joinLeague() {
        let code = inviteCode.uppercased().trimmingCharacters(in: .whitespaces)

        let success = leagueManager.joinLeague(
            inviteCode: code,
            userName: userName,
            roster: fantasyManager.roster
        )

        if success {
            dismiss()
        } else {
            errorMessage = "League not found. Please check the invite code and try again."
            showingError = true
        }
    }
}

#Preview {
    LeaguesView()
}
