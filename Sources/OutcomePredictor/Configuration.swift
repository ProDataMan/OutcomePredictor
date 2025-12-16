import Foundation

/// Application configuration using multiple sources with priority order.
///
/// Supports multiple configuration sources:
/// 1. Environment variables (highest priority)
/// 2. Configuration files (.config.json, .env)
/// 3. Keychain for secrets (macOS/iOS)
/// 4. Default values (lowest priority)
///
/// Configuration values are loaded through ConfigurationManager for secure and flexible handling.
public struct Configuration: Sendable {
    /// API configuration.
    public struct API: Sendable {
        /// The Odds API key for fetching betting odds.
        public let oddsAPIKey: String

        /// ESPN API base URL.
        public let espnBaseURL: String

        /// The Odds API base URL.
        public let oddsAPIBaseURL: String

        /// Server API base URL for iOS client.
        public let serverBaseURL: String

        /// Server port.
        public let serverPort: Int

        /// Maximum cache duration in seconds.
        public let cacheExpiration: TimeInterval

        public init(
            oddsAPIKey: String? = nil,
            espnBaseURL: String? = nil,
            oddsAPIBaseURL: String? = nil,
            serverBaseURL: String? = nil,
            serverPort: Int? = nil,
            cacheExpiration: TimeInterval? = nil
        ) {
            // First try direct parameters, then fall back to environment variables
            // ConfigurationManager provides async access via separate methods

            self.oddsAPIKey = oddsAPIKey
                ?? ProcessInfo.processInfo.environment["ODDS_API_KEY"]
                ?? ""

            self.espnBaseURL = espnBaseURL
                ?? ProcessInfo.processInfo.environment["ESPN_BASE_URL"]
                ?? "https://site.api.espn.com/apis/site/v2/sports/football/nfl"

            self.oddsAPIBaseURL = oddsAPIBaseURL
                ?? ProcessInfo.processInfo.environment["ODDS_API_BASE_URL"]
                ?? "https://api.the-odds-api.com/v4"

            self.serverBaseURL = serverBaseURL
                ?? ProcessInfo.processInfo.environment["SERVER_BASE_URL"]
                ?? "http://localhost:8080/api/v1"

            if let portString = ProcessInfo.processInfo.environment["PORT"],
               let port = Int(portString) {
                self.serverPort = serverPort ?? port
            } else {
                self.serverPort = serverPort ?? 8080
            }

            self.cacheExpiration = cacheExpiration
                ?? TimeInterval(ProcessInfo.processInfo.environment["CACHE_EXPIRATION"] ?? "21600") ?? 21600
        }

        /// Load configuration asynchronously from ConfigurationManager
        /// This provides access to file-based and keychain configurations
        public static func loadAsync(
            oddsAPIKey: String? = nil,
            espnBaseURL: String? = nil,
            oddsAPIBaseURL: String? = nil,
            serverBaseURL: String? = nil,
            serverPort: Int? = nil,
            cacheExpiration: TimeInterval? = nil
        ) async -> API {
            let configManager = ConfigurationManager.shared

            let resolvedOddsAPIKey: String
            if let oddsAPIKey = oddsAPIKey {
                resolvedOddsAPIKey = oddsAPIKey
            } else {
                resolvedOddsAPIKey = await configManager.getValue("ODDS_API_KEY", default: "")
            }

            let resolvedEspnBaseURL: String
            if let espnBaseURL = espnBaseURL {
                resolvedEspnBaseURL = espnBaseURL
            } else {
                resolvedEspnBaseURL = await configManager.getValue("ESPN_BASE_URL",
                    default: "https://site.api.espn.com/apis/site/v2/sports/football/nfl")
            }

            let resolvedOddsAPIBaseURL: String
            if let oddsAPIBaseURL = oddsAPIBaseURL {
                resolvedOddsAPIBaseURL = oddsAPIBaseURL
            } else {
                resolvedOddsAPIBaseURL = await configManager.getValue("ODDS_API_BASE_URL",
                    default: "https://api.the-odds-api.com/v4")
            }

            let resolvedServerBaseURL: String
            if let serverBaseURL = serverBaseURL {
                resolvedServerBaseURL = serverBaseURL
            } else {
                resolvedServerBaseURL = await configManager.getValue("SERVER_BASE_URL",
                    default: "http://localhost:8080/api/v1")
            }

            let resolvedServerPort: Int
            if let serverPort = serverPort {
                resolvedServerPort = serverPort
            } else {
                resolvedServerPort = await configManager.getValue("PORT", as: Int.self, default: 8080)
            }

            let resolvedCacheExpiration: TimeInterval
            if let cacheExpiration = cacheExpiration {
                resolvedCacheExpiration = cacheExpiration
            } else {
                resolvedCacheExpiration = await configManager.getValue("CACHE_EXPIRATION", as: TimeInterval.self, default: 21600)
            }

            return API(
                oddsAPIKey: resolvedOddsAPIKey,
                espnBaseURL: resolvedEspnBaseURL,
                oddsAPIBaseURL: resolvedOddsAPIBaseURL,
                serverBaseURL: resolvedServerBaseURL,
                serverPort: resolvedServerPort,
                cacheExpiration: resolvedCacheExpiration
            )
        }
    }

    /// Environment type.
    public enum Environment: String, Sendable {
        case development
        case production
        case testing

        /// Current environment from ENV variable.
        public static var current: Environment {
            guard let envString = ProcessInfo.processInfo.environment["ENV"] else {
                return .development
            }
            return Environment(rawValue: envString.lowercased()) ?? .development
        }
    }

    /// Current environment.
    public let environment: Environment

    /// API configuration.
    public let api: API

    /// Shared configuration instance.
    public static let shared = Configuration()

    /// Creates configuration from environment variables.
    public init(
        environment: Environment? = nil,
        api: API? = nil
    ) {
        self.environment = environment ?? Environment.current
        self.api = api ?? API()
    }

    /// Load configuration asynchronously with full ConfigurationManager support
    public static func loadAsync(
        environment: Environment? = nil
    ) async -> Configuration {
        let resolvedEnvironment = environment ?? Environment.current
        let api = await API.loadAsync()
        return Configuration(environment: resolvedEnvironment, api: api)
    }

    /// Validates required configuration values.
    ///
    /// - Throws: `AppConfigurationError` if required values are missing.
    public func validate() throws {
        if environment == .production {
            guard !api.oddsAPIKey.isEmpty else {
                throw AppConfigurationError.missingRequired("ODDS_API_KEY")
            }

            guard !api.serverBaseURL.contains("localhost") else {
                throw AppConfigurationError.invalidValue("SERVER_BASE_URL", "Cannot use localhost in production")
            }
        }
    }

    /// Check if running in production.
    public var isProduction: Bool {
        environment == .production
    }

    /// Check if running in development.
    public var isDevelopment: Bool {
        environment == .development
    }

    /// Check if running in testing.
    public var isTesting: Bool {
        environment == .testing
    }
}

/// Application configuration errors.
public enum AppConfigurationError: Error, LocalizedError {
    case missingRequired(String)
    case invalidValue(String, String)

    public var errorDescription: String? {
        switch self {
        case .missingRequired(let key):
            return "Missing required configuration: \(key)"
        case .invalidValue(let key, let reason):
            return "Invalid configuration for \(key): \(reason)"
        }
    }
}
