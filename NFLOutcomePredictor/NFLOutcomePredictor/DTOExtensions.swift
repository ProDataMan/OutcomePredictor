import Foundation

// MARK: - DTO Extensions for UI

extension GameDTO {
    var homeTeamAbbreviation: String {
        homeTeam.abbreviation
    }

    var awayTeamAbbreviation: String {
        awayTeam.abbreviation
    }
}

extension PredictionDTO {
    var homeTeamAbbreviation: String {
        homeTeam.abbreviation
    }

    var awayTeamAbbreviation: String {
        awayTeam.abbreviation
    }
}
