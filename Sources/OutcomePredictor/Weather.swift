import Foundation

/// Weather conditions for a game.
public struct GameWeather: Codable, Sendable {
    public let temperature: Double // Fahrenheit
    public let condition: WeatherCondition
    public let windSpeed: Double // mph
    public let precipitation: Double // percentage chance
    public let humidity: Double // percentage
    public let timestamp: Date

    public init(
        temperature: Double,
        condition: WeatherCondition,
        windSpeed: Double,
        precipitation: Double,
        humidity: Double,
        timestamp: Date = Date()
    ) {
        self.temperature = temperature
        self.condition = condition
        self.windSpeed = windSpeed
        self.precipitation = precipitation
        self.humidity = humidity
        self.timestamp = timestamp
    }
}

/// Weather condition categories.
public enum WeatherCondition: String, Codable, Sendable, CaseIterable {
    case clear = "Clear"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case rain = "Rain"
    case heavyRain = "Heavy Rain"
    case snow = "Snow"
    case heavySnow = "Heavy Snow"
    case sleet = "Sleet"
    case fog = "Fog"
    case wind = "Windy"
    case extreme = "Extreme"

    /// Icon name for weather condition.
    public var iconName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .snow: return "cloud.snow.fill"
        case .heavySnow: return "cloud.snow.fill"
        case .sleet: return "cloud.sleet.fill"
        case .fog: return "cloud.fog.fill"
        case .wind: return "wind"
        case .extreme: return "exclamationmark.triangle.fill"
        }
    }
}

/// Team performance in different weather conditions.
public struct TeamWeatherStats: Codable, Sendable {
    public let teamAbbreviation: String
    public let homePerformance: WeatherPerformance
    public let awayPerformance: WeatherPerformance
    public let season: Int

    public init(
        teamAbbreviation: String,
        homePerformance: WeatherPerformance,
        awayPerformance: WeatherPerformance,
        season: Int
    ) {
        self.teamAbbreviation = teamAbbreviation
        self.homePerformance = homePerformance
        self.awayPerformance = awayPerformance
        self.season = season
    }
}

/// Performance statistics by weather condition.
public struct WeatherPerformance: Codable, Sendable {
    public let clearWeather: ConditionStats
    public let rain: ConditionStats
    public let snow: ConditionStats
    public let wind: ConditionStats
    public let cold: ConditionStats // Below 32°F
    public let hot: ConditionStats // Above 85°F

    public init(
        clearWeather: ConditionStats,
        rain: ConditionStats,
        snow: ConditionStats,
        wind: ConditionStats,
        cold: ConditionStats,
        hot: ConditionStats
    ) {
        self.clearWeather = clearWeather
        self.rain = rain
        self.snow = snow
        self.wind = wind
        self.cold = cold
        self.hot = hot
    }

    /// Get stats for specific condition.
    public func stats(for condition: WeatherCondition, temperature: Double) -> ConditionStats {
        switch condition {
        case .rain, .heavyRain, .sleet:
            return rain
        case .snow, .heavySnow:
            return snow
        case .wind:
            return wind
        default:
            if temperature < 32 {
                return cold
            } else if temperature > 85 {
                return hot
            }
            return clearWeather
        }
    }
}

/// Statistics for a specific weather condition.
public struct ConditionStats: Codable, Sendable {
    public let gamesPlayed: Int
    public let wins: Int
    public let losses: Int
    public let ties: Int
    public let averagePointsScored: Double
    public let averagePointsAllowed: Double

    public var winPercentage: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(wins) / Double(gamesPlayed)
    }

    public init(
        gamesPlayed: Int = 0,
        wins: Int = 0,
        losses: Int = 0,
        ties: Int = 0,
        averagePointsScored: Double = 0.0,
        averagePointsAllowed: Double = 0.0
    ) {
        self.gamesPlayed = gamesPlayed
        self.wins = wins
        self.losses = losses
        self.ties = ties
        self.averagePointsScored = averagePointsScored
        self.averagePointsAllowed = averagePointsAllowed
    }
}

/// Player performance in different weather conditions.
public struct PlayerWeatherStats: Codable, Sendable {
    public let playerId: String
    public let playerName: String
    public let position: String
    public let clearWeather: PlayerConditionStats
    public let rain: PlayerConditionStats
    public let snow: PlayerConditionStats
    public let wind: PlayerConditionStats
    public let cold: PlayerConditionStats
    public let hot: PlayerConditionStats
    public let season: Int

    public init(
        playerId: String,
        playerName: String,
        position: String,
        clearWeather: PlayerConditionStats,
        rain: PlayerConditionStats,
        snow: PlayerConditionStats,
        wind: PlayerConditionStats,
        cold: PlayerConditionStats,
        hot: PlayerConditionStats,
        season: Int
    ) {
        self.playerId = playerId
        self.playerName = playerName
        self.position = position
        self.clearWeather = clearWeather
        self.rain = rain
        self.snow = snow
        self.wind = wind
        self.cold = cold
        self.hot = hot
        self.season = season
    }

    /// Get stats for specific condition.
    public func stats(for condition: WeatherCondition, temperature: Double) -> PlayerConditionStats {
        switch condition {
        case .rain, .heavyRain, .sleet:
            return rain
        case .snow, .heavySnow:
            return snow
        case .wind:
            return wind
        default:
            if temperature < 32 {
                return cold
            } else if temperature > 85 {
                return hot
            }
            return clearWeather
        }
    }
}

/// Player statistics for a specific weather condition.
public struct PlayerConditionStats: Codable, Sendable {
    public let gamesPlayed: Int

    // QB Stats
    public let passingYards: Int?
    public let passingTouchdowns: Int?
    public let interceptions: Int?

    // RB/WR Stats
    public let rushingYards: Int?
    public let rushingTouchdowns: Int?
    public let receivingYards: Int?
    public let receivingTouchdowns: Int?
    public let receptions: Int?

    public var averagePassingYards: Double? {
        guard let yards = passingYards, gamesPlayed > 0 else { return nil }
        return Double(yards) / Double(gamesPlayed)
    }

    public var averageRushingYards: Double? {
        guard let yards = rushingYards, gamesPlayed > 0 else { return nil }
        return Double(yards) / Double(gamesPlayed)
    }

    public var averageReceivingYards: Double? {
        guard let yards = receivingYards, gamesPlayed > 0 else { return nil }
        return Double(yards) / Double(gamesPlayed)
    }

    public init(
        gamesPlayed: Int = 0,
        passingYards: Int? = nil,
        passingTouchdowns: Int? = nil,
        interceptions: Int? = nil,
        rushingYards: Int? = nil,
        rushingTouchdowns: Int? = nil,
        receivingYards: Int? = nil,
        receivingTouchdowns: Int? = nil,
        receptions: Int? = nil
    ) {
        self.gamesPlayed = gamesPlayed
        self.passingYards = passingYards
        self.passingTouchdowns = passingTouchdowns
        self.interceptions = interceptions
        self.rushingYards = rushingYards
        self.rushingTouchdowns = rushingTouchdowns
        self.receivingYards = receivingYards
        self.receivingTouchdowns = receivingTouchdowns
        self.receptions = receptions
    }
}
