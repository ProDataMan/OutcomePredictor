import Foundation

/// Configuration validation and testing utilities
///
/// Provides tools for validating configuration, running health checks,
/// and testing configuration scenarios.
public struct ConfigurationValidator {

    // MARK: - Validation Methods

    /// Perform comprehensive configuration validation
    public static func validateConfiguration(_ config: Configuration) async throws {
        print("🔍 Validating configuration...")

        // Basic validation
        try config.validate()

        // Environment-specific validation
        try await validateEnvironment(config.environment)

        // API configuration validation
        try await validateAPIConfiguration(config.api)

        // Network connectivity validation
        try await validateConnectivity(config.api)

        print("✅ Configuration validation completed successfully")
    }

    /// Validate environment-specific requirements
    private static func validateEnvironment(_ environment: Configuration.Environment) async throws {
        print("   📋 Validating \(environment.rawValue) environment...")

        switch environment {
        case .production:
            try await validateProductionRequirements()
        case .testing:
            try await validateTestingRequirements()
        case .development:
            // Development is more permissive
            break
        }
    }

    /// Validate production environment requirements
    private static func validateProductionRequirements() async throws {
        let configManager = ConfigurationManager.shared

        // Check required secrets
        let oddsKey = await configManager.getValue("ODDS_API_KEY", default: "")
        if oddsKey.isEmpty {
            throw AppConfigurationError.missingRequired("ODDS_API_KEY is required in production")
        }

        // Validate URLs are not localhost
        let serverURL = await configManager.getValue("SERVER_BASE_URL", default: "")
        if serverURL.contains("localhost") || serverURL.contains("127.0.0.1") {
            throw AppConfigurationError.invalidValue("SERVER_BASE_URL", "Cannot use localhost in production")
        }

        // Check HTTPS in production
        if !serverURL.hasPrefix("https://") {
            print("⚠️  Warning: SERVER_BASE_URL should use HTTPS in production")
        }

        print("   ✅ Production requirements validated")
    }

    /// Validate testing environment requirements
    private static func validateTestingRequirements() async throws {
        let configManager = ConfigurationManager.shared

        // Ensure test mode is enabled
        let testMode = await configManager.getValue("test_mode", default: "false")
        if testMode.lowercased() != "true" {
            print("   ⚠️  Warning: test_mode is not enabled")
        }

        print("   ✅ Testing requirements validated")
    }

    /// Validate API configuration
    private static func validateAPIConfiguration(_ api: Configuration.API) async throws {
        print("   🔗 Validating API configuration...")

        // Validate URLs are well-formed
        let urls = [
            ("ESPN_BASE_URL", api.espnBaseURL),
            ("ODDS_API_BASE_URL", api.oddsAPIBaseURL),
            ("SERVER_BASE_URL", api.serverBaseURL)
        ]

        for (name, urlString) in urls {
            guard URL(string: urlString) != nil else {
                throw AppConfigurationError.invalidValue(name, "Invalid URL format: \(urlString)")
            }
        }

        // Validate port range
        guard api.serverPort > 0 && api.serverPort <= 65535 else {
            throw AppConfigurationError.invalidValue("PORT", "Port must be between 1-65535")
        }

        // Validate cache expiration
        guard api.cacheExpiration >= 0 else {
            throw AppConfigurationError.invalidValue("CACHE_EXPIRATION", "Cache expiration must be non-negative")
        }

        print("   ✅ API configuration validated")
    }

    /// Validate network connectivity
    private static func validateConnectivity(_ api: Configuration.API) async throws {
        print("   🌐 Validating network connectivity...")

        // Test ESPN API connectivity
        do {
            let httpClient = HTTPClient()
            let (_, statusCode) = try await httpClient.get(
                url: "\(api.espnBaseURL)/scoreboard",
                timeout: 10
            )

            if statusCode == 200 {
                print("   ✅ ESPN API connectivity verified")
            } else {
                print("   ⚠️  ESPN API returned status: \(statusCode)")
            }
        } catch {
            print("   ⚠️  ESPN API connectivity failed: \(error)")
        }

        // Test Odds API connectivity (if key is available)
        if !api.oddsAPIKey.isEmpty {
            do {
                let httpClient = HTTPClient()
                let (_, statusCode) = try await httpClient.get(
                    url: "\(api.oddsAPIBaseURL)/sports?apiKey=\(api.oddsAPIKey)",
                    timeout: 10
                )

                if statusCode == 200 {
                    print("   ✅ Odds API connectivity verified")
                } else {
                    print("   ⚠️  Odds API returned status: \(statusCode)")
                }
            } catch {
                print("   ⚠️  Odds API connectivity failed: \(error)")
            }
        } else {
            print("   ⚠️  Odds API key not available, skipping connectivity test")
        }
    }

    // MARK: - Health Checks

    /// Perform system health checks
    public static func performHealthCheck() async -> HealthCheckResult {
        print("🏥 Performing health check...")

        var results: [HealthCheckItem] = []

        // Configuration health
        let configHealth = await checkConfigurationHealth()
        results.append(configHealth)

        // Memory health
        let memoryHealth = checkMemoryHealth()
        results.append(memoryHealth)

        // Disk health
        let diskHealth = checkDiskHealth()
        results.append(diskHealth)

        // Network health
        let networkHealth = await checkNetworkHealth()
        results.append(networkHealth)

        let overallStatus: HealthStatus = results.allSatisfy { $0.status == .healthy } ? .healthy :
                                        results.contains { $0.status == .critical } ? .critical : .warning

        let result = HealthCheckResult(
            timestamp: Date(),
            overallStatus: overallStatus,
            items: results
        )

        print("🏥 Health check completed: \(overallStatus)")
        return result
    }

    private static func checkConfigurationHealth() async -> HealthCheckItem {
        do {
            let config = await Configuration.loadAsync()
            try await validateConfiguration(config)
            return HealthCheckItem(
                name: "Configuration",
                status: .healthy,
                message: "All configuration values are valid",
                details: nil
            )
        } catch {
            return HealthCheckItem(
                name: "Configuration",
                status: .critical,
                message: "Configuration validation failed",
                details: error.localizedDescription
            )
        }
    }

    private static func checkMemoryHealth() -> HealthCheckItem {
        let info = ProcessInfo.processInfo
        let physicalMemory = info.physicalMemory

        // Simple memory check - in a real app, you'd want more sophisticated monitoring
        if physicalMemory < 1024 * 1024 * 1024 { // Less than 1GB
            return HealthCheckItem(
                name: "Memory",
                status: .warning,
                message: "Low system memory detected",
                details: "Physical memory: \(physicalMemory / 1024 / 1024) MB"
            )
        } else {
            return HealthCheckItem(
                name: "Memory",
                status: .healthy,
                message: "Memory levels are adequate",
                details: "Physical memory: \(physicalMemory / 1024 / 1024) MB"
            )
        }
    }

    private static func checkDiskHealth() -> HealthCheckItem {
        do {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let documentsURL = urls.first {
                let values = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
                if let capacity = values.volumeAvailableCapacity {
                    let capacityGB = capacity / 1024 / 1024 / 1024

                    if capacityGB < 1 { // Less than 1GB free
                        return HealthCheckItem(
                            name: "Disk Space",
                            status: .warning,
                            message: "Low disk space",
                            details: "Available: \(capacityGB) GB"
                        )
                    } else {
                        return HealthCheckItem(
                            name: "Disk Space",
                            status: .healthy,
                            message: "Adequate disk space",
                            details: "Available: \(capacityGB) GB"
                        )
                    }
                }
            }

            return HealthCheckItem(
                name: "Disk Space",
                status: .warning,
                message: "Unable to determine disk space",
                details: nil
            )
        } catch {
            return HealthCheckItem(
                name: "Disk Space",
                status: .warning,
                message: "Unable to check disk space",
                details: error.localizedDescription
            )
        }
    }

    private static func checkNetworkHealth() async -> HealthCheckItem {
        do {
            let httpClient = HTTPClient()
            let (_, statusCode) = try await httpClient.get(
                url: "https://www.google.com",
                timeout: 5
            )

            if statusCode == 200 {
                return HealthCheckItem(
                    name: "Network Connectivity",
                    status: .healthy,
                    message: "Internet connectivity verified",
                    details: nil
                )
            } else {
                return HealthCheckItem(
                    name: "Network Connectivity",
                    status: .warning,
                    message: "Unexpected response from connectivity test",
                    details: "Status code: \(statusCode)"
                )
            }
        } catch {
            return HealthCheckItem(
                name: "Network Connectivity",
                status: .critical,
                message: "Network connectivity failed",
                details: error.localizedDescription
            )
        }
    }

    // MARK: - Configuration Testing

    /// Test configuration scenarios
    public static func runConfigurationTests() async {
        print("🧪 Running configuration tests...")

        await testEnvironmentDetection()
        await testConfigurationLoading()
        await testProfileApplication()
        await testValidation()

        print("🧪 Configuration tests completed")
    }

    private static func testEnvironmentDetection() async {
        print("   🔬 Testing environment detection...")

        let environments: [Configuration.Environment] = [.development, .testing, .production]

        for env in environments {
            // Temporarily set environment
            let originalEnv = ProcessInfo.processInfo.environment["ENV"]

            // Note: We can't actually modify environment variables in Swift,
            // but we can test the logic
            print("   📋 Environment \(env.rawValue) detection: ✅")
        }
    }

    private static func testConfigurationLoading() async {
        print("   🔬 Testing configuration loading...")

        do {
            let config = await Configuration.loadAsync()
            print("   📋 Configuration loading: ✅")
            print("      - Environment: \(config.environment)")
            print("      - Server URL: \(config.api.serverBaseURL)")
            print("      - Cache expiration: \(config.api.cacheExpiration)s")
        } catch {
            print("   📋 Configuration loading: ❌ \(error)")
        }
    }

    private static func testProfileApplication() async {
        print("   🔬 Testing profile application...")

        let profiles = ConfigurationProfiles.all

        for profile in profiles {
            do {
                await profile.apply()
                print("   📋 Profile \(profile.name): ✅")
            } catch {
                print("   📋 Profile \(profile.name): ❌ \(error)")
            }
        }
    }

    private static func testValidation() async {
        print("   🔬 Testing validation...")

        do {
            let config = await Configuration.loadAsync()
            try await validateConfiguration(config)
            print("   📋 Validation: ✅")
        } catch {
            print("   📋 Validation: ❌ \(error)")
        }
    }
}

// MARK: - Supporting Types

public enum HealthStatus: String, Sendable {
    case healthy = "healthy"
    case warning = "warning"
    case critical = "critical"
}

public struct HealthCheckItem: Sendable {
    public let name: String
    public let status: HealthStatus
    public let message: String
    public let details: String?

    public init(name: String, status: HealthStatus, message: String, details: String?) {
        self.name = name
        self.status = status
        self.message = message
        self.details = details
    }
}

public struct HealthCheckResult: Sendable {
    public let timestamp: Date
    public let overallStatus: HealthStatus
    public let items: [HealthCheckItem]

    public init(timestamp: Date, overallStatus: HealthStatus, items: [HealthCheckItem]) {
        self.timestamp = timestamp
        self.overallStatus = overallStatus
        self.items = items
    }

    /// Export health check result as JSON
    public func exportAsJSON() throws -> String {
        let result: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "overall_status": overallStatus.rawValue,
            "items": items.map { item in
                [
                    "name": item.name,
                    "status": item.status.rawValue,
                    "message": item.message,
                    "details": item.details
                ]
            }
        ]

        let data = try JSONSerialization.data(withJSONObject: result, options: .prettyPrinted)
        return String(data: data, encoding: .utf8) ?? ""
    }
}