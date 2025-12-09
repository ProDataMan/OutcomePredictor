import Foundation
import OutcomePredictor

/// Extensions for converting between domain models and DTOs.

extension TeamDTO {
    /// Convert from domain Team model to DTO.
    public init(from team: Team) {
        self.init(
            abbreviation: team.abbreviation,
            name: team.name,
            conference: team.conference.rawValue,
            division: team.division.rawValue
        )
    }
}

extension GameDTO {
    /// Convert from domain Game model to DTO.
    public init(from game: Game) {
        self.init(
            id: game.id.uuidString,
            homeTeam: TeamDTO(from: game.homeTeam),
            awayTeam: TeamDTO(from: game.awayTeam),
            scheduledDate: game.scheduledDate,
            week: game.week,
            season: game.season,
            homeScore: game.outcome?.homeScore,
            awayScore: game.outcome?.awayScore,
            winner: game.outcome.map { outcome in
                switch outcome.winner {
                case .home: return "home"
                case .away: return "away"
                case .tie: return "tie"
                }
            }
        )
    }
}

extension ArticleDTO {
    /// Convert from domain Article model to DTO.
    public init(from article: Article) {
        self.init(
            title: article.title,
            content: article.content,
            source: article.source,
            publishedDate: article.publishedDate,
            teamAbbreviations: article.teams.map { $0.abbreviation },
            url: article.url
        )
    }
}

extension PredictionDTO {
    /// Convert from domain Prediction model to DTO.
    public init(from prediction: Prediction, location: String, vegasOdds: VegasOddsDTO? = nil) {
        self.init(
            gameId: prediction.game.id.uuidString,
            homeTeam: TeamDTO(from: prediction.game.homeTeam),
            awayTeam: TeamDTO(from: prediction.game.awayTeam),
            scheduledDate: prediction.game.scheduledDate,
            location: location,
            week: prediction.game.week,
            season: prediction.game.season,
            homeWinProbability: prediction.homeWinProbability,
            awayWinProbability: prediction.awayWinProbability,
            confidence: prediction.confidence,
            predictedHomeScore: prediction.predictedHomeScore,
            predictedAwayScore: prediction.predictedAwayScore,
            reasoning: prediction.reasoning,
            vegasOdds: vegasOdds
        )
    }
}

extension VegasOddsDTO {
    /// Convert from domain BettingOdds model to DTO.
    public init(from odds: BettingOdds) {
        var homeProb: Double? = nil
        var awayProb: Double? = nil

        if let homeML = odds.homeMoneyline {
            homeProb = BettingOdds.oddsToProbability(homeML)
        }
        if let awayML = odds.awayMoneyline {
            awayProb = BettingOdds.oddsToProbability(awayML)
        }

        self.init(
            homeMoneyline: odds.homeMoneyline,
            awayMoneyline: odds.awayMoneyline,
            spread: odds.spread,
            total: odds.total,
            homeImpliedProbability: homeProb,
            awayImpliedProbability: awayProb,
            bookmaker: odds.bookmaker
        )
    }
}
