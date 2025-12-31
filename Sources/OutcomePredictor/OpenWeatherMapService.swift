import Foundation

/// OpenWeatherMap API implementation of WeatherService.
///
/// Free tier provides:
/// - 1,000 API calls/day
/// - 5-day forecast with 3-hour intervals
/// - Current weather data
///
/// Sign up at: https://openweathermap.org/api
public actor OpenWeatherMapService: WeatherService {
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private var cache: [String: CachedWeather] = [:]
    private let cacheDuration: TimeInterval = 3600 // 1 hour

    /// Stadium locations mapped to coordinates for weather lookups.
    /// Indoor stadiums are marked with isIndoor flag.
    private let stadiumLocations: [String: StadiumInfo] = [
        // AFC East
        "Buffalo": StadiumInfo(city: "Buffalo", state: "NY", lat: 42.7738, lon: -78.7870, isIndoor: false),
        "Miami": StadiumInfo(city: "Miami Gardens", state: "FL", lat: 25.9580, lon: -80.2389, isIndoor: false),
        "New England": StadiumInfo(city: "Foxborough", state: "MA", lat: 42.0909, lon: -71.2643, isIndoor: false),
        "New York Jets": StadiumInfo(city: "East Rutherford", state: "NJ", lat: 40.8128, lon: -74.0742, isIndoor: false),

        // AFC North
        "Baltimore": StadiumInfo(city: "Baltimore", state: "MD", lat: 39.2780, lon: -76.6227, isIndoor: false),
        "Cincinnati": StadiumInfo(city: "Cincinnati", state: "OH", lat: 39.0954, lon: -84.5160, isIndoor: false),
        "Cleveland": StadiumInfo(city: "Cleveland", state: "OH", lat: 41.5061, lon: -81.6995, isIndoor: false),
        "Pittsburgh": StadiumInfo(city: "Pittsburgh", state: "PA", lat: 40.4468, lon: -80.0158, isIndoor: false),

        // AFC South
        "Houston": StadiumInfo(city: "Houston", state: "TX", lat: 29.6847, lon: -95.4107, isIndoor: true),
        "Indianapolis": StadiumInfo(city: "Indianapolis", state: "IN", lat: 39.7601, lon: -86.1639, isIndoor: true),
        "Jacksonville": StadiumInfo(city: "Jacksonville", state: "FL", lat: 30.3240, lon: -81.6373, isIndoor: false),
        "Tennessee": StadiumInfo(city: "Nashville", state: "TN", lat: 36.1665, lon: -86.7713, isIndoor: false),

        // AFC West
        "Denver": StadiumInfo(city: "Denver", state: "CO", lat: 39.7439, lon: -105.0201, isIndoor: false),
        "Kansas City": StadiumInfo(city: "Kansas City", state: "MO", lat: 39.0489, lon: -94.4839, isIndoor: false),
        "Las Vegas": StadiumInfo(city: "Las Vegas", state: "NV", lat: 36.0909, lon: -115.1833, isIndoor: true),
        "Los Angeles Chargers": StadiumInfo(city: "Inglewood", state: "CA", lat: 33.9534, lon: -118.3392, isIndoor: false),

        // NFC East
        "Dallas": StadiumInfo(city: "Arlington", state: "TX", lat: 32.7473, lon: -97.0945, isIndoor: true),
        "New York Giants": StadiumInfo(city: "East Rutherford", state: "NJ", lat: 40.8128, lon: -74.0742, isIndoor: false),
        "Philadelphia": StadiumInfo(city: "Philadelphia", state: "PA", lat: 39.9008, lon: -75.1675, isIndoor: false),
        "Washington": StadiumInfo(city: "Landover", state: "MD", lat: 38.9076, lon: -76.8645, isIndoor: false),

        // NFC North
        "Chicago": StadiumInfo(city: "Chicago", state: "IL", lat: 41.8623, lon: -87.6167, isIndoor: false),
        "Detroit": StadiumInfo(city: "Detroit", state: "MI", lat: 42.3400, lon: -83.0456, isIndoor: true),
        "Green Bay": StadiumInfo(city: "Green Bay", state: "WI", lat: 44.5013, lon: -88.0622, isIndoor: false),
        "Minnesota": StadiumInfo(city: "Minneapolis", state: "MN", lat: 44.9738, lon: -93.2575, isIndoor: true),

        // NFC South
        "Atlanta": StadiumInfo(city: "Atlanta", state: "GA", lat: 33.7555, lon: -84.4008, isIndoor: true),
        "Carolina": StadiumInfo(city: "Charlotte", state: "NC", lat: 35.2258, lon: -80.8528, isIndoor: false),
        "New Orleans": StadiumInfo(city: "New Orleans", state: "LA", lat: 29.9511, lon: -90.0812, isIndoor: true),
        "Tampa Bay": StadiumInfo(city: "Tampa", state: "FL", lat: 27.9759, lon: -82.5033, isIndoor: false),

        // NFC West
        "Arizona": StadiumInfo(city: "Glendale", state: "AZ", lat: 33.5276, lon: -112.2626, isIndoor: true),
        "Los Angeles Rams": StadiumInfo(city: "Inglewood", state: "CA", lat: 33.9534, lon: -118.3392, isIndoor: false),
        "San Francisco": StadiumInfo(city: "Santa Clara", state: "CA", lat: 37.4032, lon: -121.9698, isIndoor: false),
        "Seattle": StadiumInfo(city: "Seattle", state: "WA", lat: 47.5952, lon: -122.3316, isIndoor: false)
    ]

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func fetchWeather(for location: String, at date: Date) async throws -> WeatherConditions {
        // Check cache first
        let cacheKey = "\(location)-\(date.timeIntervalSince1970)"
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheDuration {
            return cached.weather
        }

        // Get stadium info
        guard let stadiumInfo = stadiumLocations[location] else {
            throw WeatherServiceError.invalidLocation
        }

        // Indoor stadiums have no weather impact
        if stadiumInfo.isIndoor {
            let weather = WeatherConditions(
                temperature: 72.0,
                windSpeed: 0.0,
                precipitationProbability: 0.0,
                description: "Indoor",
                isIndoor: true,
                location: location,
                forecastTime: date
            )
            cache[cacheKey] = CachedWeather(weather: weather, timestamp: Date())
            return weather
        }

        // Determine if we need current weather or forecast
        let hoursUntilGame = date.timeIntervalSince(Date()) / 3600

        let weather: WeatherConditions
        if hoursUntilGame < 2 {
            // Game is happening now or very soon - use current weather
            weather = try await fetchCurrentWeather(for: stadiumInfo, location: location, date: date)
        } else if hoursUntilGame < 120 { // 5 days
            // Use forecast API
            weather = try await fetchForecastWeather(for: stadiumInfo, location: location, date: date)
        } else {
            throw WeatherServiceError.forecastUnavailable
        }

        // Cache the result
        cache[cacheKey] = CachedWeather(weather: weather, timestamp: Date())
        return weather
    }

    private func fetchCurrentWeather(for stadium: StadiumInfo, location: String, date: Date) async throws -> WeatherConditions {
        let url = URL(string: "\(baseURL)/weather?lat=\(stadium.lat)&lon=\(stadium.lon)&appid=\(apiKey)&units=imperial")!

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(CurrentWeatherResponse.self, from: data)

        return WeatherConditions(
            temperature: response.main.temp,
            windSpeed: response.wind.speed,
            precipitationProbability: response.rain?.probability ?? response.snow?.probability ?? 0.0,
            description: response.weather.first?.description ?? "Unknown",
            isIndoor: false,
            location: location,
            forecastTime: date
        )
    }

    private func fetchForecastWeather(for stadium: StadiumInfo, location: String, date: Date) async throws -> WeatherConditions {
        let url = URL(string: "\(baseURL)/forecast?lat=\(stadium.lat)&lon=\(stadium.lon)&appid=\(apiKey)&units=imperial")!

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ForecastResponse.self, from: data)

        // Find the forecast closest to game time
        let targetTimestamp = date.timeIntervalSince1970
        guard let closestForecast = response.list.min(by: { forecast1, forecast2 in
            abs(forecast1.dt - targetTimestamp) < abs(forecast2.dt - targetTimestamp)
        }) else {
            throw WeatherServiceError.invalidResponse
        }

        return WeatherConditions(
            temperature: closestForecast.main.temp,
            windSpeed: closestForecast.wind.speed,
            precipitationProbability: closestForecast.pop ?? 0.0,
            description: closestForecast.weather.first?.description ?? "Unknown",
            isIndoor: false,
            location: location,
            forecastTime: Date(timeIntervalSince1970: closestForecast.dt)
        )
    }
}

// MARK: - Supporting Types

private struct StadiumInfo {
    let city: String
    let state: String
    let lat: Double
    let lon: Double
    let isIndoor: Bool
}

private struct CachedWeather {
    let weather: WeatherConditions
    let timestamp: Date
}

// MARK: - API Response Types

private struct CurrentWeatherResponse: Codable {
    let main: MainWeather
    let wind: Wind
    let weather: [WeatherDescription]
    let rain: Precipitation?
    let snow: Precipitation?
}

private struct ForecastResponse: Codable {
    let list: [ForecastItem]
}

private struct ForecastItem: Codable {
    let dt: TimeInterval
    let main: MainWeather
    let wind: Wind
    let weather: [WeatherDescription]
    let pop: Double? // Probability of precipitation
}

private struct MainWeather: Codable {
    let temp: Double
}

private struct Wind: Codable {
    let speed: Double
}

private struct WeatherDescription: Codable {
    let description: String
}

private struct Precipitation: Codable {
    let probability: Double?
}
