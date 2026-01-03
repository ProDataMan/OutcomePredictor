import Foundation

/// Rest and travel analysis for teams.
///
/// Factors that affect team performance:
/// - Days of rest between games
/// - Travel distance and time zone changes
/// - Thursday night games (short week)
/// - Consecutive road games
public struct RestAndTravelAnalysis: Sendable, Codable {
    /// Days of rest for home team before this game
    public let homeTeamRestDays: Int

    /// Days of rest for away team before this game
    public let awayTeamRestDays: Int

    /// Travel distance for away team (miles)
    public let travelDistance: Double

    /// Time zone change for away team (hours, negative = west to east)
    public let timeZoneChange: Int

    /// Number of consecutive road games for away team (including this one)
    public let consecutiveRoadGames: Int

    /// Whether this is a Thursday night game (short week for both teams)
    public let isThursdayNightGame: Bool

    public init(
        homeTeamRestDays: Int,
        awayTeamRestDays: Int,
        travelDistance: Double,
        timeZoneChange: Int,
        consecutiveRoadGames: Int,
        isThursdayNightGame: Bool
    ) {
        self.homeTeamRestDays = homeTeamRestDays
        self.awayTeamRestDays = awayTeamRestDays
        self.travelDistance = travelDistance
        self.timeZoneChange = timeZoneChange
        self.consecutiveRoadGames = consecutiveRoadGames
        self.isThursdayNightGame = isThursdayNightGame
    }

    /// Calculate the rest and travel advantage.
    ///
    /// Positive values favor the home team, negative favor away team.
    /// Returns an adjustment value between -0.15 and +0.15.
    public func calculateAdvantage() -> Double {
        var adjustment = 0.0

        // Thursday night game advantage
        if isThursdayNightGame {
            // Home teams have 57% win rate on Thursday nights
            adjustment += 0.07
        }

        // Rest disparity
        let restDifference = homeTeamRestDays - awayTeamRestDays
        if abs(restDifference) >= 4 {
            // Significant rest advantage (e.g., bye week vs normal week)
            let restAdvantage = Double(restDifference) / 7.0 * 0.08
            adjustment += restAdvantage
        } else if abs(restDifference) >= 2 {
            // Moderate rest advantage
            let restAdvantage = Double(restDifference) / 7.0 * 0.04
            adjustment += restAdvantage
        }

        // Cross-country travel burden (>2000 miles)
        if travelDistance > 2000 {
            if abs(timeZoneChange) >= 3 {
                // Severe travel disadvantage (coast-to-coast with 3-hour time change)
                adjustment += 0.08
            } else if abs(timeZoneChange) == 2 {
                // Moderate travel disadvantage
                adjustment += 0.05
            } else {
                // Long distance but same time zone
                adjustment += 0.03
            }
        } else if travelDistance > 1000 {
            // Medium distance travel
            if abs(timeZoneChange) >= 2 {
                adjustment += 0.04
            } else {
                adjustment += 0.02
            }
        }

        // Consecutive road games fatigue
        if consecutiveRoadGames >= 3 {
            // Third straight road game = significant fatigue
            adjustment += 0.05
        } else if consecutiveRoadGames >= 2 {
            // Second road game in a row
            adjustment += 0.03
        }

        // Clamp to reasonable range
        return max(-0.15, min(0.15, adjustment))
    }

    /// Human-readable summary of rest and travel impact.
    public var impactSummary: String {
        var factors: [String] = []

        if isThursdayNightGame {
            factors.append("Thursday night game - home team advantage (57% win rate)")
        }

        let restDiff = homeTeamRestDays - awayTeamRestDays
        if abs(restDiff) >= 4 {
            if restDiff > 0 {
                factors.append("home team has \(restDiff)-day rest advantage")
            } else {
                factors.append("away team has \(abs(restDiff))-day rest advantage")
            }
        }

        if travelDistance > 2000 && abs(timeZoneChange) >= 3 {
            factors.append("away team crosses \(abs(timeZoneChange)) time zones (\(Int(travelDistance)) miles)")
        } else if travelDistance > 1000 {
            factors.append("away team travels \(Int(travelDistance)) miles")
        }

        if consecutiveRoadGames >= 3 {
            factors.append("away team's \(consecutiveRoadGames)rd consecutive road game")
        } else if consecutiveRoadGames == 2 {
            factors.append("away team's 2nd consecutive road game")
        }

        if factors.isEmpty {
            return "Normal rest and travel conditions"
        }

        return factors.joined(separator: "; ")
    }
}

/// Stadium location information for calculating travel distance and time zones.
public struct StadiumLocation: Sendable {
    public let city: String
    public let state: String
    public let latitude: Double
    public let longitude: Double
    public let timeZone: Int  // UTC offset in hours

    public init(city: String, state: String, latitude: Double, longitude: Double, timeZone: Int) {
        self.city = city
        self.state = state
        self.latitude = latitude
        self.longitude = longitude
        self.timeZone = timeZone
    }

    /// Calculate distance to another stadium in miles using Haversine formula.
    public func distance(to other: StadiumLocation) -> Double {
        let earthRadius = 3959.0 // miles

        let lat1 = latitude * .pi / 180.0
        let lat2 = other.latitude * .pi / 180.0
        let dLat = (other.latitude - latitude) * .pi / 180.0
        let dLon = (other.longitude - longitude) * .pi / 180.0

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    /// Time zone difference in hours.
    public func timeZoneDifference(to other: StadiumLocation) -> Int {
        return other.timeZone - self.timeZone
    }
}

/// Stadium database with locations for all NFL teams.
public struct NFLStadiums {
    public static let locations: [String: StadiumLocation] = [
        // AFC East (Eastern Time: UTC-5)
        "Buffalo": StadiumLocation(city: "Orchard Park", state: "NY", latitude: 42.7738, longitude: -78.7870, timeZone: -5),
        "Miami": StadiumLocation(city: "Miami Gardens", state: "FL", latitude: 25.9580, longitude: -80.2389, timeZone: -5),
        "New England": StadiumLocation(city: "Foxborough", state: "MA", latitude: 42.0909, longitude: -71.2643, timeZone: -5),
        "New York Jets": StadiumLocation(city: "East Rutherford", state: "NJ", latitude: 40.8128, longitude: -74.0742, timeZone: -5),

        // AFC North (Eastern Time: UTC-5)
        "Baltimore": StadiumLocation(city: "Baltimore", state: "MD", latitude: 39.2780, longitude: -76.6227, timeZone: -5),
        "Cincinnati": StadiumLocation(city: "Cincinnati", state: "OH", latitude: 39.0954, longitude: -84.5160, timeZone: -5),
        "Cleveland": StadiumLocation(city: "Cleveland", state: "OH", latitude: 41.5061, longitude: -81.6995, timeZone: -5),
        "Pittsburgh": StadiumLocation(city: "Pittsburgh", state: "PA", latitude: 40.4468, longitude: -80.0158, timeZone: -5),

        // AFC South (Eastern/Central Time)
        "Houston": StadiumLocation(city: "Houston", state: "TX", latitude: 29.6847, longitude: -95.4107, timeZone: -6),
        "Indianapolis": StadiumLocation(city: "Indianapolis", state: "IN", latitude: 39.7601, longitude: -86.1639, timeZone: -5),
        "Jacksonville": StadiumLocation(city: "Jacksonville", state: "FL", latitude: 30.3240, longitude: -81.6373, timeZone: -5),
        "Tennessee": StadiumLocation(city: "Nashville", state: "TN", latitude: 36.1665, longitude: -86.7713, timeZone: -6),

        // AFC West (Pacific/Mountain Time)
        "Denver": StadiumLocation(city: "Denver", state: "CO", latitude: 39.7439, longitude: -105.0201, timeZone: -7),
        "Kansas City": StadiumLocation(city: "Kansas City", state: "MO", latitude: 39.0489, longitude: -94.4839, timeZone: -6),
        "Las Vegas": StadiumLocation(city: "Las Vegas", state: "NV", latitude: 36.0909, longitude: -115.1833, timeZone: -8),
        "Los Angeles Chargers": StadiumLocation(city: "Inglewood", state: "CA", latitude: 33.9534, longitude: -118.3392, timeZone: -8),

        // NFC East (Eastern Time: UTC-5)
        "Dallas": StadiumLocation(city: "Arlington", state: "TX", latitude: 32.7473, longitude: -97.0945, timeZone: -6),
        "New York Giants": StadiumLocation(city: "East Rutherford", state: "NJ", latitude: 40.8128, longitude: -74.0742, timeZone: -5),
        "Philadelphia": StadiumLocation(city: "Philadelphia", state: "PA", latitude: 39.9008, longitude: -75.1675, timeZone: -5),
        "Washington Commanders": StadiumLocation(city: "Landover", state: "MD", latitude: 38.9076, longitude: -76.8645, timeZone: -5),

        // NFC North (Central Time: UTC-6)
        "Chicago": StadiumLocation(city: "Chicago", state: "IL", latitude: 41.8623, longitude: -87.6167, timeZone: -6),
        "Detroit": StadiumLocation(city: "Detroit", state: "MI", latitude: 42.3400, longitude: -83.0456, timeZone: -5),
        "Green Bay": StadiumLocation(city: "Green Bay", state: "WI", latitude: 44.5013, longitude: -88.0622, timeZone: -6),
        "Minnesota": StadiumLocation(city: "Minneapolis", state: "MN", latitude: 44.9738, longitude: -93.2575, timeZone: -6),

        // NFC South (Eastern/Central Time)
        "Atlanta": StadiumLocation(city: "Atlanta", state: "GA", latitude: 33.7555, longitude: -84.4008, timeZone: -5),
        "Carolina": StadiumLocation(city: "Charlotte", state: "NC", latitude: 35.2258, longitude: -80.8528, timeZone: -5),
        "New Orleans": StadiumLocation(city: "New Orleans", state: "LA", latitude: 29.9511, longitude: -90.0812, timeZone: -6),
        "Tampa Bay": StadiumLocation(city: "Tampa", state: "FL", latitude: 27.9759, longitude: -82.5033, timeZone: -5),

        // NFC West (Pacific/Mountain Time)
        "Arizona": StadiumLocation(city: "Glendale", state: "AZ", latitude: 33.5276, longitude: -112.2626, timeZone: -7),
        "Los Angeles Rams": StadiumLocation(city: "Inglewood", state: "CA", latitude: 33.9534, longitude: -118.3392, timeZone: -8),
        "San Francisco": StadiumLocation(city: "Santa Clara", state: "CA", latitude: 37.4032, longitude: -121.9698, timeZone: -8),
        "Seattle": StadiumLocation(city: "Seattle", state: "WA", latitude: 47.5952, longitude: -122.3316, timeZone: -8)
    ]

    /// Get stadium location for a team.
    public static func location(for teamName: String) -> StadiumLocation? {
        return locations[teamName]
    }
}
