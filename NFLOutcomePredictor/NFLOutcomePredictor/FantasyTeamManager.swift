import Foundation
import SwiftUI
import Combine

/// Fantasy team roster management.
@MainActor
final class FantasyTeamManager: ObservableObject {
    static let shared = FantasyTeamManager()

    @Published var roster: FantasyRoster
    @Published var rosterChanges: Int = 0 // Trigger view updates

    private let userDefaultsKey = "fantasy_roster"

    private init() {
        // Load saved roster from UserDefaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedRoster = try? JSONDecoder().decode(FantasyRoster.self, from: data) {
            self.roster = savedRoster
        } else {
            self.roster = FantasyRoster()
        }
    }

    /// Add a player to the roster.
    func addPlayer(_ player: PlayerDTO, team: TeamDTO) -> Bool {
        let fantasyPlayer = FantasyPlayer(from: player, team: team)

        // Check position limits
        switch player.position {
        case "QB":
            guard roster.quarterbacks.count < FantasyRoster.maxQBs else { return false }
            roster.quarterbacks.append(fantasyPlayer)
        case "RB":
            guard roster.runningBacks.count < FantasyRoster.maxRBs else { return false }
            roster.runningBacks.append(fantasyPlayer)
        case "WR":
            guard roster.wideReceivers.count < FantasyRoster.maxWRs else { return false }
            roster.wideReceivers.append(fantasyPlayer)
        case "TE":
            guard roster.tightEnds.count < FantasyRoster.maxTEs else { return false }
            roster.tightEnds.append(fantasyPlayer)
        case "K":
            guard roster.kickers.count < FantasyRoster.maxKs else { return false }
            roster.kickers.append(fantasyPlayer)
        case "DEF":
            guard roster.defense.count < FantasyRoster.maxDEF else { return false }
            roster.defense.append(fantasyPlayer)
        default:
            return false // Unknown position
        }

        rosterChanges += 1
        saveRoster()
        return true
    }

    /// Remove a player from the roster.
    func removePlayer(_ player: FantasyPlayer) {
        roster.quarterbacks.removeAll { $0.id == player.id }
        roster.runningBacks.removeAll { $0.id == player.id }
        roster.wideReceivers.removeAll { $0.id == player.id }
        roster.tightEnds.removeAll { $0.id == player.id }
        roster.kickers.removeAll { $0.id == player.id }
        roster.defense.removeAll { $0.id == player.id }

        rosterChanges += 1
        saveRoster()
    }

    /// Check if player is on roster.
    func isOnRoster(_ playerId: String) -> Bool {
        roster.allPlayers.contains { $0.id == playerId }
    }

    /// Check if position is full.
    func isPositionFull(_ position: String) -> Bool {
        switch position {
        case "QB": return roster.quarterbacks.count >= FantasyRoster.maxQBs
        case "RB": return roster.runningBacks.count >= FantasyRoster.maxRBs
        case "WR": return roster.wideReceivers.count >= FantasyRoster.maxWRs
        case "TE": return roster.tightEnds.count >= FantasyRoster.maxTEs
        case "K": return roster.kickers.count >= FantasyRoster.maxKs
        case "DEF": return roster.defense.count >= FantasyRoster.maxDEF
        default: return true
        }
    }

    /// Clear entire roster.
    func clearRoster() {
        roster = FantasyRoster()
        rosterChanges += 1
        saveRoster()
    }

    private func saveRoster() {
        if let encoded = try? JSONEncoder().encode(roster) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}

/// Fantasy team roster.
struct FantasyRoster: Codable {
    var quarterbacks: [FantasyPlayer] = []
    var runningBacks: [FantasyPlayer] = []
    var wideReceivers: [FantasyPlayer] = []
    var tightEnds: [FantasyPlayer] = []
    var kickers: [FantasyPlayer] = []
    var defense: [FantasyPlayer] = []

    static let maxQBs = 2
    static let maxRBs = 3
    static let maxWRs = 3
    static let maxTEs = 2
    static let maxKs = 1
    static let maxDEF = 1

    var allPlayers: [FantasyPlayer] {
        quarterbacks + runningBacks + wideReceivers + tightEnds + kickers + defense
    }

    var totalPlayers: Int {
        allPlayers.count
    }

    var maxPlayers: Int {
        Self.maxQBs + Self.maxRBs + Self.maxWRs + Self.maxTEs + Self.maxKs + Self.maxDEF
    }

    var isFull: Bool {
        totalPlayers >= maxPlayers
    }
}

/// Fantasy player representation.
struct FantasyPlayer: Codable, Identifiable {
    let id: String
    let name: String
    let position: String
    let jerseyNumber: String?
    let photoURL: String?
    let teamAbbreviation: String
    let teamName: String
    let stats: PlayerStatsDTO?

    init(from player: PlayerDTO, team: TeamDTO) {
        self.id = player.id
        self.name = player.name
        self.position = player.position
        self.jerseyNumber = player.jerseyNumber
        self.photoURL = player.photoURL
        self.teamAbbreviation = team.abbreviation
        self.teamName = team.name
        self.stats = player.stats
    }

    /// Calculate fantasy points based on standard scoring.
    var projectedPoints: Double {
        guard let stats = stats else { return 0.0 }

        var points: Double = 0.0

        // QB Scoring
        if position == "QB" {
            points += Double(stats.passingYards ?? 0) * 0.04 // 1 point per 25 yards
            points += Double(stats.passingTouchdowns ?? 0) * 4.0
            points -= Double(stats.passingInterceptions ?? 0) * 2.0
            points += Double(stats.rushingYards ?? 0) * 0.1
            points += Double(stats.rushingTouchdowns ?? 0) * 6.0
        }

        // RB Scoring
        if position == "RB" {
            points += Double(stats.rushingYards ?? 0) * 0.1
            points += Double(stats.rushingTouchdowns ?? 0) * 6.0
            points += Double(stats.receivingYards ?? 0) * 0.1
            points += Double(stats.receivingTouchdowns ?? 0) * 6.0
            points += Double(stats.receptions ?? 0) * 0.5 // PPR
        }

        // WR/TE Scoring
        if position == "WR" || position == "TE" {
            points += Double(stats.receivingYards ?? 0) * 0.1
            points += Double(stats.receivingTouchdowns ?? 0) * 6.0
            points += Double(stats.receptions ?? 0) * 0.5 // PPR
        }

        return points
    }
}
