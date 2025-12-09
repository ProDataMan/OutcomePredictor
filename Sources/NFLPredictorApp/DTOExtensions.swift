import Foundation
import OutcomePredictorAPI

// MARK: - DTO Extensions for UI

extension TeamDTO {
    init(abbreviation: String, name: String, conference: String, division: String) {
        self.abbreviation = abbreviation
        self.name = name
        self.conference = conference
        self.division = division
    }
}

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
