import Foundation
import OutcomePredictor

/// Configuration management CLI tool
///
/// Provides commands for managing application configuration:
/// - validate: Validate current configuration
/// - health: Run health checks
/// - profile: Manage configuration profiles
/// - export: Export configuration to files
/// - test: Run configuration tests
@main
struct ConfigCLI {
    static func main() async {
        let args = CommandLine.arguments

        guard args.count > 1 else {
            printHelp()
            return
        }

        let command = args[1]

        do {
            switch command {
            case "validate":
                await validateCommand(args)
            case "health":
                await healthCommand(args)
            case "profile":
                await profileCommand(args)
            case "export":
                await exportCommand(args)
            case "test":
                await testCommand(args)
            case "help", "--help", "-h":
                printHelp()
            default:
                print("❌ Unknown command: \(command)")
                print("Run 'config help' for available commands")
            }
        } catch {
            print("❌ Error: \(error)")
            exit(1)
        }
    }

    // MARK: - Commands

    static func validateCommand(_ args: [String]) async {
        print("🔍 Validating configuration...\n")

        do {
            let config = await Configuration.loadAsync()
            try await ConfigurationValidator.validateConfiguration(config)
            print("\n✅ Configuration is valid!")
        } catch {
            print("\n❌ Configuration validation failed:")
            print("   \(error)")
            exit(1)
        }
    }

    static func healthCommand(_ args: [String]) async {
        print("🏥 Running health checks...\n")

        let result = await ConfigurationValidator.performHealthCheck()

        print("\n📊 Health Check Results:")
        print("   Overall Status: \(statusEmoji(result.overallStatus)) \(result.overallStatus.rawValue.capitalized)")
        print("   Timestamp: \(DateFormatter.localizedString(from: result.timestamp, dateStyle: .short, timeStyle: .medium))")
        print()

        for item in result.items {
            let emoji = statusEmoji(item.status)
            print("   \(emoji) \(item.name): \(item.message)")
            if let details = item.details {
                print("      \(details)")
            }
        }

        // Export JSON if requested
        if args.contains("--json") {
            do {
                let json = try result.exportAsJSON()
                print("\n📄 JSON Export:")
                print(json)
            } catch {
                print("❌ Failed to export JSON: \(error)")
            }
        }
    }

    static func profileCommand(_ args: [String]) async {
        guard args.count > 2 else {
            printProfileHelp()
            return
        }

        let subcommand = args[2]

        switch subcommand {
        case "list":
            listProfiles()
        case "current":
            showCurrentProfile()
        case "apply":
            await applyProfile(args)
        case "export":
            await exportProfile(args)
        case "validate":
            await validateProfile(args)
        default:
            print("❌ Unknown profile command: \(subcommand)")
            printProfileHelp()
        }
    }

    static func exportCommand(_ args: [String]) async {
        let format = args.contains("--env") ? "env" : "json"
        let includeSecrets = !args.contains("--no-secrets")

        print("📁 Exporting configuration as \(format)...")

        do {
            let config = await Configuration.loadAsync()
            let profile = ConfigurationProfiles.currentProfile()

            switch format {
            case "env":
                let content = profile.exportAsEnv(includeComments: true)
                print(content)
            case "json":
                let content = try profile.exportAsJSON()
                print(content)
            default:
                print("❌ Unsupported format: \(format)")
            }
        } catch {
            print("❌ Export failed: \(error)")
        }
    }

    static func testCommand(_ args: [String]) async {
        print("🧪 Running configuration tests...\n")
        await ConfigurationValidator.runConfigurationTests()
    }

    // MARK: - Profile Subcommands

    static func listProfiles() {
        print("📋 Available Configuration Profiles:\n")

        for profile in ConfigurationProfiles.all {
            let current = profile.name == ConfigurationProfiles.currentProfile().name ? " (current)" : ""
            print("   📋 \(profile.name)\(current)")
            print("      Environment: \(profile.environment.rawValue)")
            print("      Description: \(profile.description)")
            print()
        }
    }

    static func showCurrentProfile() {
        let profile = ConfigurationProfiles.currentProfile()
        let environment = Configuration.Environment.current

        print("📋 Current Configuration Profile:")
        print("   Name: \(profile.name)")
        print("   Environment: \(environment.rawValue)")
        print("   Description: \(profile.description)")
        print()

        if !profile.apiDefaults.isEmpty {
            print("   API Configuration:")
            for (key, value) in profile.apiDefaults.sorted(by: { $0.key < $1.key }) {
                // Mask sensitive values
                let displayValue = isSensitiveKey(key) ? "***" : value
                print("      \(key) = \(displayValue)")
            }
            print()
        }

        if !profile.features.isEmpty {
            print("   Feature Flags:")
            for (key, value) in profile.features.sorted(by: { $0.key < $1.key }) {
                print("      \(key) = \(value)")
            }
            print()
        }

        if !profile.requiredSecrets.isEmpty {
            print("   Required Secrets:")
            for (key, description) in profile.requiredSecrets.sorted(by: { $0.key < $1.key }) {
                print("      \(key): \(description)")
            }
        }
    }

    static func applyProfile(_ args: [String]) async {
        guard args.count > 3 else {
            print("❌ Profile name required")
            print("Usage: config profile apply <profile-name>")
            return
        }

        let profileName = args[3]

        guard let profile = ConfigurationProfiles.profile(named: profileName) else {
            print("❌ Unknown profile: \(profileName)")
            print("Available profiles: \(ConfigurationProfiles.all.map(\.name).joined(separator: ", "))")
            return
        }

        print("📋 Applying profile: \(profile.name)")
        await profile.apply()

        // Validate after applying
        do {
            try await profile.validateSecrets()
            print("✅ Profile applied successfully")
        } catch {
            print("⚠️  Profile applied but validation failed: \(error)")
        }
    }

    static func exportProfile(_ args: [String]) async {
        guard args.count > 3 else {
            print("❌ Profile name required")
            print("Usage: config profile export <profile-name> [--env]")
            return
        }

        let profileName = args[3]
        let format = args.contains("--env") ? "env" : "json"

        guard let profile = ConfigurationProfiles.profile(named: profileName) else {
            print("❌ Unknown profile: \(profileName)")
            return
        }

        do {
            let content = format == "env" ? profile.exportAsEnv() : try profile.exportAsJSON()
            print(content)
        } catch {
            print("❌ Export failed: \(error)")
        }
    }

    static func validateProfile(_ args: [String]) async {
        guard args.count > 3 else {
            print("❌ Profile name required")
            print("Usage: config profile validate <profile-name>")
            return
        }

        let profileName = args[3]

        guard let profile = ConfigurationProfiles.profile(named: profileName) else {
            print("❌ Unknown profile: \(profileName)")
            return
        }

        print("🔍 Validating profile: \(profile.name)")

        do {
            await profile.apply()
            try await profile.validateSecrets()
            print("✅ Profile validation completed successfully")
        } catch {
            print("❌ Profile validation failed: \(error)")
        }
    }

    // MARK: - Utilities

    static func statusEmoji(_ status: HealthStatus) -> String {
        switch status {
        case .healthy: return "✅"
        case .warning: return "⚠️"
        case .critical: return "❌"
        }
    }

    static func isSensitiveKey(_ key: String) -> Bool {
        let sensitivePatterns = ["PASSWORD", "SECRET", "KEY", "TOKEN", "CREDENTIAL"]
        let upperKey = key.uppercased()
        return sensitivePatterns.contains { upperKey.contains($0) }
    }

    // MARK: - Help

    static func printHelp() {
        print("""
        📋 Configuration Management CLI

        USAGE:
            config <command> [options]

        COMMANDS:
            validate                 Validate current configuration
            health [--json]         Run health checks
            profile <subcommand>    Manage configuration profiles
            export [--env] [--no-secrets]  Export configuration
            test                    Run configuration tests
            help                    Show this help message

        PROFILE SUBCOMMANDS:
            list                    List available profiles
            current                 Show current profile
            apply <name>            Apply a profile
            export <name> [--env]   Export a profile
            validate <name>         Validate a profile

        EXAMPLES:
            config validate
            config health --json
            config profile list
            config profile apply development
            config export --env
            config test

        """)
    }

    static func printProfileHelp() {
        print("""
        📋 Configuration Profile Management

        USAGE:
            config profile <subcommand> [options]

        SUBCOMMANDS:
            list                    List all available profiles
            current                 Show current active profile
            apply <name>            Apply a specific profile
            export <name> [--env]   Export profile configuration
            validate <name>         Validate profile requirements

        EXAMPLES:
            config profile list
            config profile current
            config profile apply production
            config profile export development --env
            config profile validate staging

        """)
    }
}