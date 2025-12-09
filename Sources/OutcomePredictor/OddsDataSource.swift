import Foundation

/// Betting odds for an NFL game.
public struct BettingOdds: Codable, Sendable {
    /// Home team moneyline (American odds format, e.g., -150, +200).
    public let homeMoneyline: Int?

    /// Away team moneyline (American odds format).
    public let awayMoneyline: Int?

    /// Point spread (positive means underdog, negative means favorite).
    public let spread: Double?

    /// Total points over/under.
    public let total: Double?

    /// Bookmaker name.
    public let bookmaker: String

    /// Last update timestamp.
    public let lastUpdate: Date

    /// Convert American odds to implied probability.
    ///
    /// - Parameter americanOdds: American odds format (e.g., -150 or +200).
    /// - Returns: Implied probability (0.0 to 1.0).
    public static func oddsToProbability(_ americanOdds: Int) -> Double {
        if americanOdds < 0 {
            // Favorite: -150 means bet $150 to win $100
            let absOdds = Double(abs(americanOdds))
            return absOdds / (absOdds + 100.0)
        } else {
            // Underdog: +200 means bet $100 to win $200
            return 100.0 / (Double(americanOdds) + 100.0)
        }
    }
}

/// The Odds API data source for fetching betting odds.
///
/// Uses AsyncHTTPClient for optimal Linux performance with actor-based caching.
/// Free tier: 500 requests/month
/// Get API key at: https://the-odds-api.com/
public struct TheOddsAPIDataSource: Sendable {
    private let apiKey: String
    private let baseURL: String
    private let httpClient: HTTPClient
    private let cache: HTTPCache<[String: BettingOdds]>

    /// Creates an Odds API data source.
    ///
    /// - Parameters:
    ///   - apiKey: The Odds API key (defaults to configuration).
    ///   - baseURL: API base URL (defaults to configuration).
    ///   - cacheTTL: Cache time-to-live in seconds (default: 6 hours).
    public init(
        apiKey: String? = nil,
        baseURL: String? = nil,
        cacheTTL: TimeInterval = 6 * 60 * 60
    ) {
        let config = Configuration.shared.api
        self.apiKey = apiKey ?? config.oddsAPIKey
        self.baseURL = baseURL ?? config.oddsAPIBaseURL
        self.httpClient = HTTPClient()
        self.cache = HTTPCache(defaultTTL: cacheTTL)
    }

    /// Fetches odds for NFL games with caching.
    ///
    /// Checks cache first to avoid excessive API calls (500/month limit).
    /// - Returns: Dictionary mapping team matchup to odds.
    /// - Throws: Network or parsing errors.
    public func fetchNFLOdds() async throws -> [String: BettingOdds] {
        let cacheKey = "nfl_odds"

        // Check cache first
        if let cached = await cache.get(cacheKey) {
            return cached
        }

        // Fetch from API
        let urlString = "\(baseURL)/sports/americanfootball_nfl/odds?apiKey=\(apiKey)&regions=us&markets=h2h,spreads,totals&oddsFormat=american"

        let (data, statusCode) = try await httpClient.get(url: urlString)

        guard statusCode == 200 else {
            throw DataSourceError.httpError(statusCode)
        }

        let oddsResponse = try JSONDecoder().decode([OddsAPIEvent].self, from: data)
        let odds = parseOdds(from: oddsResponse)

        // Cache result
        await cache.set(cacheKey, value: odds)

        return odds
    }

    private func parseOdds(from events: [OddsAPIEvent]) -> [String: BettingOdds] {
        var oddsMap: [String: BettingOdds] = [:]

        for event in events {
            guard let bookmaker = event.bookmakers.first else { continue }

            // Extract moneylines
            var homeMoneyline: Int?
            var awayMoneyline: Int?
            if let h2hMarket = bookmaker.markets.first(where: { $0.key == "h2h" }) {
                for outcome in h2hMarket.outcomes {
                    if outcome.name == event.homeTeam {
                        homeMoneyline = Int(outcome.price)
                    } else if outcome.name == event.awayTeam {
                        awayMoneyline = Int(outcome.price)
                    }
                }
            }

            // Extract spread
            var spread: Double?
            if let spreadMarket = bookmaker.markets.first(where: { $0.key == "spreads" }) {
                if let homeOutcome = spreadMarket.outcomes.first(where: { $0.name == event.homeTeam }) {
                    spread = homeOutcome.point
                }
            }

            // Extract total
            var total: Double?
            if let totalsMarket = bookmaker.markets.first(where: { $0.key == "totals" }) {
                if let overOutcome = totalsMarket.outcomes.first(where: { $0.name == "Over" }) {
                    total = overOutcome.point
                }
            }

            let odds = BettingOdds(
                homeMoneyline: homeMoneyline,
                awayMoneyline: awayMoneyline,
                spread: spread,
                total: total,
                bookmaker: bookmaker.title,
                lastUpdate: ISO8601DateFormatter().date(from: event.commenceTime) ?? Date()
            )

            // Use team names as key
            let key = "\(event.awayTeam) @ \(event.homeTeam)"
            oddsMap[key] = odds
        }

        return oddsMap
    }
}

private struct OddsAPIEvent: Codable {
    let id: String
    let sportKey: String
    let commenceTime: String
    let homeTeam: String
    let awayTeam: String
    let bookmakers: [OddsAPIBookmaker]

    enum CodingKeys: String, CodingKey {
        case id
        case sportKey = "sport_key"
        case commenceTime = "commence_time"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case bookmakers
    }
}

private struct OddsAPIBookmaker: Codable {
    let title: String
    let markets: [OddsAPIMarket]
}

private struct OddsAPIMarket: Codable {
    let key: String
    let outcomes: [OddsAPIOutcome]
}

private struct OddsAPIOutcome: Codable {
    let name: String
    let price: Double
    let point: Double?
}
