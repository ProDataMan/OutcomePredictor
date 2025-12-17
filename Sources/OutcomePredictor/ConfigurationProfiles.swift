import Foundation

/// Environment-specific configuration profiles
///
/// Provides pre-configured settings for different deployment environments.
/// Each profile includes appropriate defaults for that environment.
public struct ConfigurationProfiles {

    // MARK: - Development Profile
    public static let development = ConfigurationProfile(
        name: "Development",
        environment: .development,
        description: "Local development with mock data and fast refresh",
        apiDefaults: [
            "SERVER_BASE_URL": "http://localhost:8080/api/v1",
            "ESPN_BASE_URL": "https://site.api.espn.com/apis/site/v2/sports/football/nfl",
            "ODDS_API_BASE_URL": "https://api.the-odds-api.com/v4",
            "PORT": "8080",
            "CACHE_EXPIRATION": "300", // 5 minutes for fast development
            "LOG_LEVEL": "debug"
        ],
        features: [
            "debug_menu": "true",
            "mock_data": "false",
            "detailed_logging": "true",
            "hot_reload": "true"
        ]
    )

    // MARK: - Testing Profile
    public static let testing = ConfigurationProfile(
        name: "Testing",
        environment: .testing,
        description: "Automated testing with predictable behavior",
        apiDefaults: [
            "SERVER_BASE_URL": "http://localhost:9999/api/v1",
            "ESPN_BASE_URL": "http://localhost:9999/mock/espn",
            "ODDS_API_BASE_URL": "http://localhost:9999/mock/odds",
            "PORT": "9999",
            "CACHE_EXPIRATION": "10", // Very short for testing
            "LOG_LEVEL": "error"
        ],
        features: [
            "debug_menu": "false",
            "mock_data": "true",
            "detailed_logging": "false",
            "deterministic_responses": "true",
            "test_mode": "true"
        ]
    )

    // MARK: - Production Profile
    public static let production = ConfigurationProfile(
        name: "Production",
        environment: .production,
        description: "Production deployment with optimal performance",
        apiDefaults: [
            "SERVER_BASE_URL": "https://statshark-api.azurewebsites.net/api/v1",
            "ESPN_BASE_URL": "https://site.api.espn.com/apis/site/v2/sports/football/nfl",
            "ODDS_API_BASE_URL": "https://api.the-odds-api.com/v4",
            "PORT": "8080",
            "CACHE_EXPIRATION": "21600", // 6 hours
            "LOG_LEVEL": "info"
        ],
        features: [
            "debug_menu": "false",
            "mock_data": "false",
            "detailed_logging": "false",
            "performance_monitoring": "true",
            "error_reporting": "true"
        ],
        requiredSecrets: [
            "ODDS_API_KEY": "Required for betting odds data"
        ]
    )

    // MARK: - Staging Profile
    public static let staging = ConfigurationProfile(
        name: "Staging",
        environment: .production, // Same validation as production
        description: "Pre-production environment for final testing",
        apiDefaults: [
            "SERVER_BASE_URL": "https://statshark-api-staging.azurewebsites.net/api/v1",
            "ESPN_BASE_URL": "https://site.api.espn.com/apis/site/v2/sports/football/nfl",
            "ODDS_API_BASE_URL": "https://api.the-odds-api.com/v4",
            "PORT": "8080",
            "CACHE_EXPIRATION": "3600", // 1 hour for staging
            "LOG_LEVEL": "debug"
        ],
        features: [
            "debug_menu": "true",
            "mock_data": "false",
            "detailed_logging": "true",
            "performance_monitoring": "true",
            "error_reporting": "true"
        ],
        requiredSecrets: [
            "ODDS_API_KEY": "Required for betting odds data"
        ]
    )

    /// All available profiles
    public static let all: [ConfigurationProfile] = [
        development, testing, production, staging
    ]

    /// Get profile by name
    public static func profile(named name: String) -> ConfigurationProfile? {
        return all.first { $0.name.lowercased() == name.lowercased() }
    }

    /// Get profile for current environment
    public static func currentProfile() -> ConfigurationProfile {
        let environment = Configuration.Environment.current

        // Check for specific profile override
        if let profileName = ProcessInfo.processInfo.environment["PROFILE"] {
            if let profile = profile(named: profileName) {
                return profile
            }
        }

        // Default profile based on environment
        switch environment {
        case .development:
            return development
        case .testing:
            return testing
        case .production:
            return production
        }
    }
}

// MARK: - ConfigurationProfile
public struct ConfigurationProfile: Sendable {
    /// Profile name
    public let name: String

    /// Target environment
    public let environment: Configuration.Environment

    /// Profile description
    public let description: String

    /// Default API configuration values
    public let apiDefaults: [String: String]

    /// Feature flags and settings
    public let features: [String: String]

    /// Required secrets for this profile
    public let requiredSecrets: [String: String]

    public init(
        name: String,
        environment: Configuration.Environment,
        description: String,
        apiDefaults: [String: String] = [:],
        features: [String: String] = [:],
        requiredSecrets: [String: String] = [:]
    ) {
        self.name = name
        self.environment = environment
        self.description = description
        self.apiDefaults = apiDefaults
        self.features = features
        self.requiredSecrets = requiredSecrets
    }

    /// Apply this profile to ConfigurationManager
    public func apply() async {
        let configManager = ConfigurationManager.shared

        // Apply API defaults
        for (key, value) in apiDefaults {
            await configManager.setValue(key, value: value)
        }

        // Apply feature flags
        for (key, value) in features {
            await configManager.setValue(key, value: value)
        }

        print("📋 Applied configuration profile: \(name)")
        print("   Environment: \(environment.rawValue)")
        print("   Description: \(description)")

        if !requiredSecrets.isEmpty {
            print("   Required secrets: \(requiredSecrets.keys.joined(separator: ", "))")
        }
    }

    /// Validate that all required secrets are available
    public func validateSecrets() async throws {
        let configManager = ConfigurationManager.shared
        var missing: [String] = []

        for (key, description) in requiredSecrets {
            let value = await configManager.getValue(key, default: "")
            if value.isEmpty {
                missing.append("\(key): \(description)")
            }
        }

        if !missing.isEmpty {
            throw AppConfigurationError.missingRequired(
                "Missing required secrets for \(name) profile:\n" + missing.joined(separator: "\n")
            )
        }
    }

    /// Export profile as configuration file content
    public func exportAsJSON() throws -> String {
        let config: [String: Any] = [
            "profile": [
                "name": name,
                "environment": environment.rawValue,
                "description": description
            ],
            "api": apiDefaults,
            "features": features,
            "secrets": requiredSecrets.keys.map { ["key": $0, "description": requiredSecrets[$0] ?? ""] }
        ]

        let data = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Export profile as .env file content
    public func exportAsEnv(includeComments: Bool = true) -> String {
        var lines: [String] = []

        if includeComments {
            lines.append("# \(name) Configuration Profile")
            lines.append("# \(description)")
            lines.append("# Environment: \(environment.rawValue)")
            lines.append("")
        }

        // Environment and profile
        lines.append("ENV=\(environment.rawValue)")
        lines.append("PROFILE=\(name)")
        lines.append("")

        if includeComments && !apiDefaults.isEmpty {
            lines.append("# API Configuration")
        }
        for (key, value) in apiDefaults.sorted(by: { $0.key < $1.key }) {
            lines.append("\(key)=\(value)")
        }

        if !apiDefaults.isEmpty && !features.isEmpty {
            lines.append("")
        }

        if includeComments && !features.isEmpty {
            lines.append("# Feature Flags")
        }
        for (key, value) in features.sorted(by: { $0.key < $1.key }) {
            lines.append("\(key)=\(value)")
        }

        if !features.isEmpty && !requiredSecrets.isEmpty {
            lines.append("")
        }

        if includeComments && !requiredSecrets.isEmpty {
            lines.append("# Required Secrets (set these manually)")
        }
        for (key, description) in requiredSecrets.sorted(by: { $0.key < $1.key }) {
            if includeComments {
                lines.append("# \(description)")
            }
            lines.append("# \(key)=your_secret_here")
        }

        return lines.joined(separator: "\n")
    }
}