import Foundation

/// Weather conditions that can affect game outcomes.
public struct WeatherConditions: Sendable, Codable {
    /// Temperature in Fahrenheit
    public let temperature: Double

    /// Wind speed in mph
    public let windSpeed: Double

    /// Precipitation probability (0.0 to 1.0)
    public let precipitationProbability: Double

    /// Description of conditions (e.g., "Clear", "Rain", "Snow")
    public let description: String

    /// Whether the game is indoors
    public let isIndoor: Bool

    /// Location of the game
    public let location: String

    /// Timestamp of weather forecast
    public let forecastTime: Date

    public init(
        temperature: Double,
        windSpeed: Double,
        precipitationProbability: Double,
        description: String,
        isIndoor: Bool,
        location: String,
        forecastTime: Date
    ) {
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.precipitationProbability = precipitationProbability
        self.description = description
        self.isIndoor = isIndoor
        self.location = location
        self.forecastTime = forecastTime
    }

    /// Calculate the weather impact on game play.
    /// Returns an adjustment value that favors teams suited for the conditions.
    ///
    /// - Parameters:
    ///   - homeTeamPassRatio: Home team's pass play percentage (0.0 to 1.0)
    ///   - awayTeamPassRatio: Away team's pass play percentage (0.0 to 1.0)
    ///   - homeTeamIsFromDome: Whether home team plays in a dome stadium
    /// - Returns: Weather adjustment value (-0.15 to +0.15)
    public func calculateWeatherImpact(
        homeTeamPassRatio: Double,
        awayTeamPassRatio: Double,
        homeTeamIsFromDome: Bool
    ) -> Double {
        // Indoor games have no weather impact
        if isIndoor {
            return 0.0
        }

        var impact = 0.0

        // Wind impact (heavily affects passing game)
        if windSpeed > 20 {
            // Severe wind favors run-heavy teams
            let homePenalty = homeTeamPassRatio > 0.60 ? -0.10 : 0.0
            let awayPenalty = awayTeamPassRatio > 0.60 ? 0.10 : 0.0
            impact += homePenalty + awayPenalty
        } else if windSpeed > 15 {
            // Moderate wind slightly favors run-heavy teams
            let homePenalty = homeTeamPassRatio > 0.65 ? -0.05 : 0.0
            let awayPenalty = awayTeamPassRatio > 0.65 ? 0.05 : 0.0
            impact += homePenalty + awayPenalty
        }

        // Temperature impact (cold weather)
        if temperature < 20 {
            // Extreme cold affects ball handling and passing
            impact -= 0.08
            // Dome team in extreme cold = bigger disadvantage
            if homeTeamIsFromDome {
                impact -= 0.06
            }
        } else if temperature < 32 {
            // Freezing temps affect performance
            impact -= 0.04
            if homeTeamIsFromDome {
                impact -= 0.04
            }
        }

        // Precipitation impact
        if precipitationProbability > 0.7 {
            // High chance of rain/snow favors rushing
            let homeAdvantage = homeTeamPassRatio < 0.50 ? 0.06 : -0.08
            let awayAdvantage = awayTeamPassRatio < 0.50 ? -0.06 : 0.08
            impact += homeAdvantage + awayAdvantage
        } else if precipitationProbability > 0.5 {
            // Moderate precipitation chance
            let homeAdvantage = homeTeamPassRatio < 0.50 ? 0.03 : -0.04
            let awayAdvantage = awayTeamPassRatio < 0.50 ? -0.03 : 0.04
            impact += homeAdvantage + awayAdvantage
        }

        // Clamp to reasonable range
        return max(-0.15, min(0.15, impact))
    }

    /// Human-readable summary of weather impact.
    public var impactSummary: String {
        if isIndoor {
            return "Indoor game - no weather impact"
        }

        var factors: [String] = []

        if windSpeed > 20 {
            factors.append("severe wind (\(Int(windSpeed))mph) - favors running game")
        } else if windSpeed > 15 {
            factors.append("strong wind (\(Int(windSpeed))mph) - passing difficult")
        }

        if temperature < 20 {
            factors.append("extreme cold (\(Int(temperature))°F) - ball handling issues")
        } else if temperature < 32 {
            factors.append("freezing temps (\(Int(temperature))°F) - affects grip")
        }

        if precipitationProbability > 0.7 {
            factors.append("likely precipitation (\(Int(precipitationProbability * 100))%) - favors rush")
        } else if precipitationProbability > 0.5 {
            factors.append("possible precipitation (\(Int(precipitationProbability * 100))%)")
        }

        if factors.isEmpty {
            return "Good weather conditions (\(Int(temperature))°F, \(Int(windSpeed))mph wind)"
        }

        return factors.joined(separator: "; ")
    }
}

/// Protocol for fetching weather data.
public protocol WeatherService: Sendable {
    /// Fetch weather conditions for a location at a specific time.
    ///
    /// - Parameters:
    ///   - location: City or venue location
    ///   - date: Game date/time
    /// - Returns: Weather conditions forecast
    func fetchWeather(for location: String, at date: Date) async throws -> WeatherConditions
}

/// Errors that can occur when fetching weather data.
public enum WeatherServiceError: Error, LocalizedError {
    case invalidLocation
    case apiKeyMissing
    case networkError(Error)
    case invalidResponse
    case forecastUnavailable

    public var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Invalid location provided"
        case .apiKeyMissing:
            return "Weather API key not configured"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from weather service"
        case .forecastUnavailable:
            return "Weather forecast not available for this date"
        }
    }
}
