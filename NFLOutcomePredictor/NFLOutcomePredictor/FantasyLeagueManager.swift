import Foundation
import SwiftUI
import Combine

/// Fantasy League management system.
@MainActor
final class FantasyLeagueManager: ObservableObject {
    static let shared = FantasyLeagueManager()

    @Published var leagues: [FantasyLeague] = []
    @Published var currentLeague: FantasyLeague?

    private let userDefaultsKey = "fantasy_leagues"
    private let currentLeagueKey = "current_league_id"

    // Payment feature flag - disable until 1000 downloads
    static let paymentsEnabled = false
    static let minimumDownloadsForPayments = 1000

    private init() {
        loadLeagues()
        loadCurrentLeague()
    }

    /// Create a new league.
    func createLeague(_ league: FantasyLeague) {
        leagues.append(league)
        currentLeague = league
        saveLeagues()
        saveCurrentLeague()
    }

    /// Join an existing league via invite code.
    func joinLeague(inviteCode: String, userName: String, roster: FantasyRoster) -> Bool {
        guard let leagueIndex = leagues.firstIndex(where: { $0.inviteCode == inviteCode }) else {
            return false
        }

        let member = LeagueMember(
            id: UUID().uuidString,
            name: userName,
            roster: roster,
            joinedAt: Date()
        )

        leagues[leagueIndex].members.append(member)
        currentLeague = leagues[leagueIndex]
        saveLeagues()
        saveCurrentLeague()
        return true
    }

    /// Leave a league.
    func leaveLeague(_ leagueId: String) {
        leagues.removeAll { $0.id == leagueId }
        if currentLeague?.id == leagueId {
            currentLeague = leagues.first
            saveCurrentLeague()
        }
        saveLeagues()
    }

    /// Update league name.
    func updateLeagueName(_ leagueId: String, name: String) {
        guard let index = leagues.firstIndex(where: { $0.id == leagueId }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        leagues[index].name = trimmed

        // Update current league if it's the one being edited
        if currentLeague?.id == leagueId {
            currentLeague = leagues[index]
        }

        saveLeagues()
    }

    /// Set current league.
    func setCurrentLeague(_ league: FantasyLeague) {
        currentLeague = league
        saveCurrentLeague()
    }

    /// Update league standings based on weekly scores.
    func updateStandings(for league: FantasyLeague) {
        // Calculate standings based on fantasy points
        // This will be implemented when we have weekly scoring
    }

    /// Generate unique invite code.
    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).compactMap { _ in characters.randomElement() })
    }

    private func loadLeagues() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode([FantasyLeague].self, from: data) {
            leagues = saved
        }
    }

    private func loadCurrentLeague() {
        if let leagueId = UserDefaults.standard.string(forKey: currentLeagueKey),
           let league = leagues.first(where: { $0.id == leagueId }) {
            currentLeague = league
        } else {
            currentLeague = leagues.first
        }
    }

    private func saveLeagues() {
        if let encoded = try? JSONEncoder().encode(leagues) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func saveCurrentLeague() {
        if let leagueId = currentLeague?.id {
            UserDefaults.standard.set(leagueId, forKey: currentLeagueKey)
        }
    }
}

// MARK: - Fantasy League Models

/// Fantasy league configuration and data.
struct FantasyLeague: Codable, Identifiable {
    let id: String
    var name: String
    var inviteCode: String
    var commissionerId: String // Member ID who created the league
    var members: [LeagueMember]
    var settings: LeagueSettings
    var paymentInfo: LeaguePaymentInfo
    var createdAt: Date
    var season: Int

    init(
        name: String,
        commissionerName: String,
        commissionerRoster: FantasyRoster,
        settings: LeagueSettings,
        season: Int
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.inviteCode = FantasyLeagueManager.generateInviteCode()
        self.commissionerId = UUID().uuidString

        // Commissioner is first member
        let commissioner = LeagueMember(
            id: commissionerId,
            name: commissionerName,
            roster: commissionerRoster,
            joinedAt: Date()
        )
        self.members = [commissioner]
        self.settings = settings

        // Initialize payment info with default values
        self.paymentInfo = LeaguePaymentInfo(
            entryFee: settings.entryFee,
            prizePool: 0.0,
            platformFeePercentage: 0.10, // 10% to Stat Shark
            paymentsEnabled: FantasyLeagueManager.paymentsEnabled
        )

        self.createdAt = Date()
        self.season = season
    }

    var totalPrizePool: Double {
        let totalFees = Double(members.count) * paymentInfo.entryFee
        return totalFees * (1.0 - paymentInfo.platformFeePercentage)
    }

    var isFull: Bool {
        members.count >= settings.maxMembers
    }

    /// Get sorted standings.
    var standings: [LeagueMember] {
        members.sorted { $0.totalPoints > $1.totalPoints }
    }
}

/// League member (team owner).
struct LeagueMember: Codable, Identifiable {
    let id: String
    var name: String
    var roster: FantasyRoster
    var joinedAt: Date
    var weeklyScores: [Int: Double] // Week number -> Points scored
    var paymentStatus: PaymentStatus

    init(
        id: String,
        name: String,
        roster: FantasyRoster,
        joinedAt: Date
    ) {
        self.id = id
        self.name = name
        self.roster = roster
        self.joinedAt = joinedAt
        self.weeklyScores = [:]
        self.paymentStatus = .pending
    }

    var totalPoints: Double {
        weeklyScores.values.reduce(0, +)
    }

    var wins: Int {
        // Will be calculated from matchup results
        0
    }

    var losses: Int {
        // Will be calculated from matchup results
        0
    }
}

/// League configuration settings.
struct LeagueSettings: Codable {
    var maxMembers: Int
    var scoringType: ScoringType
    var draftType: DraftType
    var entryFee: Double // Base entry fee (shown but FREE for now)
    var playoffWeeks: Int
    var tradeDeadlineWeek: Int

    static let `default` = LeagueSettings(
        maxMembers: 10,
        scoringType: .ppr,
        draftType: .manual,
        entryFee: 10.0, // Show $10 but marked as FREE
        playoffWeeks: 3,
        tradeDeadlineWeek: 13
    )
}

/// Scoring type for fantasy points.
enum ScoringType: String, Codable, CaseIterable {
    case standard = "Standard"
    case ppr = "PPR" // Point Per Reception
    case halfPpr = "Half PPR"

    var description: String {
        switch self {
        case .standard: return "Standard scoring"
        case .ppr: return "1 point per reception"
        case .halfPpr: return "0.5 points per reception"
        }
    }
}

/// Draft type for league.
enum DraftType: String, Codable, CaseIterable {
    case manual = "Manual"
    case snake = "Snake Draft"
    case auction = "Auction Draft"

    var description: String {
        switch self {
        case .manual: return "Build your team manually"
        case .snake: return "Traditional snake draft"
        case .auction: return "Auction-style draft"
        }
    }
}

/// Payment information for league (for future implementation).
struct LeaguePaymentInfo: Codable {
    var entryFee: Double
    var prizePool: Double
    var platformFeePercentage: Double // Stat Shark's cut (10%)
    var paymentsEnabled: Bool
    var transactions: [PaymentTransaction]

    init(
        entryFee: Double,
        prizePool: Double,
        platformFeePercentage: Double,
        paymentsEnabled: Bool
    ) {
        self.entryFee = entryFee
        self.prizePool = prizePool
        self.platformFeePercentage = platformFeePercentage
        self.paymentsEnabled = paymentsEnabled
        self.transactions = []
    }

    var platformFee: Double {
        prizePool / (1.0 - platformFeePercentage) * platformFeePercentage
    }
}

/// Payment transaction record (for future implementation).
struct PaymentTransaction: Codable, Identifiable {
    let id: String
    let memberId: String
    let amount: Double
    let type: TransactionType
    let status: TransactionStatus
    let timestamp: Date
    let stripePaymentId: String? // For Stripe integration

    enum TransactionType: String, Codable {
        case entryFee = "Entry Fee"
        case payout = "Prize Payout"
        case refund = "Refund"
    }

    enum TransactionStatus: String, Codable {
        case pending = "Pending"
        case completed = "Completed"
        case failed = "Failed"
        case refunded = "Refunded"
    }
}

/// Payment status for league member.
enum PaymentStatus: String, Codable {
    case pending = "Pending"
    case paid = "Paid"
    case exempt = "Free" // For beta period

    var displayText: String {
        switch self {
        case .pending: return "Payment Pending"
        case .paid: return "Paid"
        case .exempt: return "FREE (Beta)"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .paid: return .green
        case .exempt: return .blue
        }
    }
}

/// Weekly matchup between two teams.
struct WeeklyMatchup: Codable, Identifiable {
    let id: String
    let week: Int
    let homeTeamId: String
    let awayTeamId: String
    var homeScore: Double?
    var awayScore: Double?
    var isComplete: Bool

    var winnerId: String? {
        guard let home = homeScore, let away = awayScore else { return nil }
        if home > away { return homeTeamId }
        if away > home { return awayTeamId }
        return nil // Tie
    }
}
