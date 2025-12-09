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

extension ArticleDTO: Identifiable {
    public var id: String {
        "\(title)-\(publishedDate.timeIntervalSince1970)"
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
