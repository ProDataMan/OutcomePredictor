import Foundation

/// Real NFL teams with complete roster for 2024 season.
public enum NFLTeams {
    /// All 32 NFL teams.
    public static let allTeams: [Team] = [
        // NFC East
        Team(id: UUID(uuidString: "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d")!,
             name: "Dallas Cowboys", abbreviation: "DAL", conference: .nfc, division: .east),
        Team(id: UUID(uuidString: "2b3c4d5e-6f7a-8b9c-0d1e-2f3a4b5c6d7e")!,
             name: "Philadelphia Eagles", abbreviation: "PHI", conference: .nfc, division: .east),
        Team(id: UUID(uuidString: "3c4d5e6f-7a8b-9c0d-1e2f-3a4b5c6d7e8f")!,
             name: "New York Giants", abbreviation: "NYG", conference: .nfc, division: .east),
        Team(id: UUID(uuidString: "4d5e6f7a-8b9c-0d1e-2f3a-4b5c6d7e8f9a")!,
             name: "Washington Commanders", abbreviation: "WAS", conference: .nfc, division: .east),

        // NFC North
        Team(id: UUID(uuidString: "5e6f7a8b-9c0d-1e2f-3a4b-5c6d7e8f9a0b")!,
             name: "Detroit Lions", abbreviation: "DET", conference: .nfc, division: .north),
        Team(id: UUID(uuidString: "6f7a8b9c-0d1e-2f3a-4b5c-6d7e8f9a0b1c")!,
             name: "Green Bay Packers", abbreviation: "GB", conference: .nfc, division: .north),
        Team(id: UUID(uuidString: "7a8b9c0d-1e2f-3a4b-5c6d-7e8f9a0b1c2d")!,
             name: "Minnesota Vikings", abbreviation: "MIN", conference: .nfc, division: .north),
        Team(id: UUID(uuidString: "8b9c0d1e-2f3a-4b5c-6d7e-8f9a0b1c2d3e")!,
             name: "Chicago Bears", abbreviation: "CHI", conference: .nfc, division: .north),

        // NFC South
        Team(id: UUID(uuidString: "9c0d1e2f-3a4b-5c6d-7e8f-9a0b1c2d3e4f")!,
             name: "Tampa Bay Buccaneers", abbreviation: "TB", conference: .nfc, division: .south),
        Team(id: UUID(uuidString: "0d1e2f3a-4b5c-6d7e-8f9a-0b1c2d3e4f5a")!,
             name: "Atlanta Falcons", abbreviation: "ATL", conference: .nfc, division: .south),
        Team(id: UUID(uuidString: "1e2f3a4b-5c6d-7e8f-9a0b-1c2d3e4f5a6b")!,
             name: "New Orleans Saints", abbreviation: "NO", conference: .nfc, division: .south),
        Team(id: UUID(uuidString: "2f3a4b5c-6d7e-8f9a-0b1c-2d3e4f5a6b7c")!,
             name: "Carolina Panthers", abbreviation: "CAR", conference: .nfc, division: .south),

        // NFC West
        Team(id: UUID(uuidString: "3a4b5c6d-7e8f-9a0b-1c2d-3e4f5a6b7c8d")!,
             name: "San Francisco 49ers", abbreviation: "SF", conference: .nfc, division: .west),
        Team(id: UUID(uuidString: "4b5c6d7e-8f9a-0b1c-2d3e-4f5a6b7c8d9e")!,
             name: "Seattle Seahawks", abbreviation: "SEA", conference: .nfc, division: .west),
        Team(id: UUID(uuidString: "5c6d7e8f-9a0b-1c2d-3e4f-5a6b7c8d9e0f")!,
             name: "Los Angeles Rams", abbreviation: "LAR", conference: .nfc, division: .west),
        Team(id: UUID(uuidString: "6d7e8f9a-0b1c-2d3e-4f5a-6b7c8d9e0f1a")!,
             name: "Arizona Cardinals", abbreviation: "ARI", conference: .nfc, division: .west),

        // AFC East
        Team(id: UUID(uuidString: "7e8f9a0b-1c2d-3e4f-5a6b-7c8d9e0f1a2b")!,
             name: "Buffalo Bills", abbreviation: "BUF", conference: .afc, division: .east),
        Team(id: UUID(uuidString: "8f9a0b1c-2d3e-4f5a-6b7c-8d9e0f1a2b3c")!,
             name: "Miami Dolphins", abbreviation: "MIA", conference: .afc, division: .east),
        Team(id: UUID(uuidString: "9a0b1c2d-3e4f-5a6b-7c8d-9e0f1a2b3c4d")!,
             name: "New York Jets", abbreviation: "NYJ", conference: .afc, division: .east),
        Team(id: UUID(uuidString: "0b1c2d3e-4f5a-6b7c-8d9e-0f1a2b3c4d5e")!,
             name: "New England Patriots", abbreviation: "NE", conference: .afc, division: .east),

        // AFC North
        Team(id: UUID(uuidString: "1c2d3e4f-5a6b-7c8d-9e0f-1a2b3c4d5e6f")!,
             name: "Baltimore Ravens", abbreviation: "BAL", conference: .afc, division: .north),
        Team(id: UUID(uuidString: "2d3e4f5a-6b7c-8d9e-0f1a-2b3c4d5e6f7a")!,
             name: "Pittsburgh Steelers", abbreviation: "PIT", conference: .afc, division: .north),
        Team(id: UUID(uuidString: "3e4f5a6b-7c8d-9e0f-1a2b-3c4d5e6f7a8b")!,
             name: "Cincinnati Bengals", abbreviation: "CIN", conference: .afc, division: .north),
        Team(id: UUID(uuidString: "4f5a6b7c-8d9e-0f1a-2b3c-4d5e6f7a8b9c")!,
             name: "Cleveland Browns", abbreviation: "CLE", conference: .afc, division: .north),

        // AFC South
        Team(id: UUID(uuidString: "5a6b7c8d-9e0f-1a2b-3c4d-5e6f7a8b9c0d")!,
             name: "Houston Texans", abbreviation: "HOU", conference: .afc, division: .south),
        Team(id: UUID(uuidString: "6b7c8d9e-0f1a-2b3c-4d5e-6f7a8b9c0d1e")!,
             name: "Indianapolis Colts", abbreviation: "IND", conference: .afc, division: .south),
        Team(id: UUID(uuidString: "7c8d9e0f-1a2b-3c4d-5e6f-7a8b9c0d1e2f")!,
             name: "Jacksonville Jaguars", abbreviation: "JAX", conference: .afc, division: .south),
        Team(id: UUID(uuidString: "8d9e0f1a-2b3c-4d5e-6f7a-8b9c0d1e2f3a")!,
             name: "Tennessee Titans", abbreviation: "TEN", conference: .afc, division: .south),

        // AFC West
        Team(id: UUID(uuidString: "9e0f1a2b-3c4d-5e6f-7a8b-9c0d1e2f3a4b")!,
             name: "Kansas City Chiefs", abbreviation: "KC", conference: .afc, division: .west),
        Team(id: UUID(uuidString: "0f1a2b3c-4d5e-6f7a-8b9c-0d1e2f3a4b5c")!,
             name: "Los Angeles Chargers", abbreviation: "LAC", conference: .afc, division: .west),
        Team(id: UUID(uuidString: "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6e")!,
             name: "Las Vegas Raiders", abbreviation: "LV", conference: .afc, division: .west),
        Team(id: UUID(uuidString: "2b3c4d5e-6f7a-8b9c-0d1e-2f3a4b5c6d7f")!,
             name: "Denver Broncos", abbreviation: "DEN", conference: .afc, division: .west),
    ]

    /// Lookup team by abbreviation.
    public static func team(abbreviation: String) -> Team? {
        allTeams.first { $0.abbreviation == abbreviation }
    }

    /// Lookup team by name.
    public static func team(name: String) -> Team? {
        allTeams.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Get all teams in a conference.
    public static func teams(in conference: Conference) -> [Team] {
        allTeams.filter { $0.conference == conference }
    }

    /// Get all teams in a division.
    public static func teams(in conference: Conference, division: Division) -> [Team] {
        allTeams.filter { $0.conference == conference && $0.division == division }
    }
}
