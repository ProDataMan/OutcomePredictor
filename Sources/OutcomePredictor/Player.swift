import Foundation

// MARK: - Player Models

/// NFL player with stats.
public struct Player: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let position: String
    public let jerseyNumber: String?
    public let photoURL: String?
    public let team: Team
    public let stats: PlayerStats?
    public let height: String?
    public let weight: Int?
    public let age: Int?
    public let college: String?
    public let experience: Int?

    public init(
        id: String,
        name: String,
        position: String,
        jerseyNumber: String? = nil,
        photoURL: String? = nil,
        team: Team,
        stats: PlayerStats? = nil,
        height: String? = nil,
        weight: Int? = nil,
        age: Int? = nil,
        college: String? = nil,
        experience: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.position = position
        self.jerseyNumber = jerseyNumber
        self.photoURL = photoURL
        self.team = team
        self.stats = stats
        self.height = height
        self.weight = weight
        self.age = age
        self.college = college
        self.experience = experience
    }
}

/// Player statistics for current season.
public struct PlayerStats: Codable, Sendable {
    // Passing stats (QB)
    public let passingYards: Int?
    public let passingTouchdowns: Int?
    public let passingInterceptions: Int?
    public let passingCompletions: Int?
    public let passingAttempts: Int?

    // Rushing stats (RB, QB)
    public let rushingYards: Int?
    public let rushingTouchdowns: Int?
    public let rushingAttempts: Int?

    // Receiving stats (WR, TE, RB)
    public let receivingYards: Int?
    public let receivingTouchdowns: Int?
    public let receptions: Int?
    public let targets: Int?

    // Defense stats
    public let tackles: Int?
    public let sacks: Double?
    public let interceptions: Int?

    public init(
        passingYards: Int? = nil,
        passingTouchdowns: Int? = nil,
        passingInterceptions: Int? = nil,
        passingCompletions: Int? = nil,
        passingAttempts: Int? = nil,
        rushingYards: Int? = nil,
        rushingTouchdowns: Int? = nil,
        rushingAttempts: Int? = nil,
        receivingYards: Int? = nil,
        receivingTouchdowns: Int? = nil,
        receptions: Int? = nil,
        targets: Int? = nil,
        tackles: Int? = nil,
        sacks: Double? = nil,
        interceptions: Int? = nil
    ) {
        self.passingYards = passingYards
        self.passingTouchdowns = passingTouchdowns
        self.passingInterceptions = passingInterceptions
        self.passingCompletions = passingCompletions
        self.passingAttempts = passingAttempts
        self.rushingYards = rushingYards
        self.rushingTouchdowns = rushingTouchdowns
        self.rushingAttempts = rushingAttempts
        self.receivingYards = receivingYards
        self.receivingTouchdowns = receivingTouchdowns
        self.receptions = receptions
        self.targets = targets
        self.tackles = tackles
        self.sacks = sacks
        self.interceptions = interceptions
    }

    public var passingCompletionPercentage: Double? {
        guard let completions = passingCompletions,
              let attempts = passingAttempts,
              attempts > 0 else { return nil }
        return (Double(completions) / Double(attempts)) * 100.0
    }

    public var yardsPerAttempt: Double? {
        guard let yards = rushingYards,
              let attempts = rushingAttempts,
              attempts > 0 else { return nil }
        return Double(yards) / Double(attempts)
    }

    public var catchPercentage: Double? {
        guard let receptions = receptions,
              let targets = targets,
              targets > 0 else { return nil }
        return (Double(receptions) / Double(targets)) * 100.0
    }
}

// MARK: - Team Roster

/// Team roster with players.
public struct TeamRoster: Sendable {
    public let team: Team
    public let players: [Player]
    public let season: Int

    public init(team: Team, players: [Player], season: Int) {
        self.team = team
        self.players = players
        self.season = season
    }

    public var quarterbacks: [Player] {
        players.filter { $0.position == "QB" }
    }

    public var runningBacks: [Player] {
        players.filter { ["RB", "FB"].contains($0.position) }
    }

    public var wideReceivers: [Player] {
        players.filter { $0.position == "WR" }
    }

    public var tightEnds: [Player] {
        players.filter { $0.position == "TE" }
    }

    public var defense: [Player] {
        players.filter { ["DE", "DT", "LB", "CB", "S", "DB"].contains($0.position) }
    }
}
