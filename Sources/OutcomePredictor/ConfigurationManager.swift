import Foundation

/// Enhanced configuration manager with file-based configuration support.
///
/// Supports multiple configuration sources in priority order:
/// 1. Environment variables (highest priority)
/// 2. Configuration files (.config.json, .env)
/// 3. Keychain for secrets (macOS/iOS)
/// 4. Default values (lowest priority)
public actor ConfigurationManager {
    /// Configuration file names to search for (in order of preference)
    private static let configFiles = [
        ".config.json",
        "config.json",
        ".env",
        "config.env"
    ]

    /// Cached configuration values
    private var cachedConfig: [String: String] = [:]

    /// File-based configuration loaded from disk
    private var fileConfig: [String: String] = [:]

    /// Shared instance
    public static let shared = ConfigurationManager()

    private init() {
        Task {
            await loadConfigurationFiles()
        }
    }

    /// Loads configuration files from the file system
    private func loadConfigurationFiles() {
        for fileName in Self.configFiles {
            if let config = loadConfigFile(fileName) {
                print("📁 Loaded configuration from: \(fileName)")
                fileConfig.merge(config) { (current, _) in current }
                break // Use first file found
            }
        }
    }

    /// Load configuration from a specific file
    private func loadConfigFile(_ fileName: String) -> [String: String]? {
        let possiblePaths = [
            FileManager.default.currentDirectoryPath + "/" + fileName,
            NSHomeDirectory() + "/." + fileName,
            "/etc/" + fileName
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return parseConfigFile(at: path)
            }
        }

        return nil
    }

    /// Parse configuration file based on extension
    private func parseConfigFile(at path: String) -> [String: String]? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }

        if path.hasSuffix(".json") {
            return parseJSONConfig(content)
        } else {
            return parseEnvConfig(content)
        }
    }

    /// Parse JSON configuration file
    private func parseJSONConfig(_ content: String) -> [String: String]? {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        var config: [String: String] = [:]
        flattenJSON(json, into: &config)
        return config
    }

    /// Flatten nested JSON into dot-notation keys
    private func flattenJSON(_ json: [String: Any], into config: inout [String: String], prefix: String = "") {
        for (key, value) in json {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"

            if let stringValue = value as? String {
                config[fullKey] = stringValue
            } else if let numberValue = value as? NSNumber {
                config[fullKey] = numberValue.stringValue
            } else if let nestedDict = value as? [String: Any] {
                flattenJSON(nestedDict, into: &config, prefix: fullKey)
            } else if let arrayValue = value as? [Any] {
                config[fullKey] = "\(arrayValue)"
            }
        }
    }

    /// Parse .env format configuration file
    private func parseEnvConfig(_ content: String) -> [String: String] {
        var config: [String: String] = [:]

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse KEY=VALUE format
            if let equalIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<equalIndex]).trimmingCharacters(in: .whitespaces)
                var value = String(trimmed[trimmed.index(after: equalIndex)...]).trimmingCharacters(in: .whitespaces)

                // Remove quotes if present
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }

                config[key] = value
            }
        }

        return config
    }

    /// Get configuration value with priority: env vars > files > keychain > default
    public func getValue(_ key: String, default defaultValue: String = "") -> String {
        // 1. Check environment variables (highest priority)
        if let envValue = ProcessInfo.processInfo.environment[key] {
            return envValue
        }

        // 2. Check cached config
        if let cachedValue = cachedConfig[key] {
            return cachedValue
        }

        // 3. Check file-based config
        if let fileValue = fileConfig[key] {
            cachedConfig[key] = fileValue
            return fileValue
        }

        // 4. Check keychain (if available)
        #if canImport(Security)
        if let keychainValue = getKeychainValue(key) {
            cachedConfig[key] = keychainValue
            return keychainValue
        }
        #endif

        // 5. Return default value
        return defaultValue
    }

    /// Get typed configuration value
    public func getValue<T>(_ key: String, as type: T.Type, default defaultValue: T) -> T {
        let stringValue = getValue(key, default: "")

        if stringValue.isEmpty {
            return defaultValue
        }

        switch type {
        case is Int.Type:
            return (Int(stringValue) ?? defaultValue as? Int ?? 0) as! T
        case is Double.Type:
            return (Double(stringValue) ?? defaultValue as? Double ?? 0.0) as! T
        case is Bool.Type:
            let boolValue = stringValue.lowercased()
            return (["true", "1", "yes", "on"].contains(boolValue)) as! T
        case is TimeInterval.Type:
            return (TimeInterval(stringValue) ?? defaultValue as? TimeInterval ?? 0) as! T
        default:
            return stringValue as! T
        }
    }

    /// Set configuration value (cached only, doesn't persist to files)
    public func setValue(_ key: String, value: String) {
        cachedConfig[key] = value
    }

    /// Set value in keychain (if available)
    public func setSecureValue(_ key: String, value: String) {
        #if canImport(Security)
        setKeychainValue(key, value: value)
        #else
        // Fallback to in-memory cache
        cachedConfig[key] = value
        #endif
    }

    /// Clear all cached configuration
    public func clearCache() {
        cachedConfig.removeAll()
    }

    /// Reload configuration from files
    public func reload() async {
        fileConfig.removeAll()
        cachedConfig.removeAll()
        await loadConfigurationFiles()
    }

    /// Export current configuration (excluding secrets)
    public func exportConfiguration(includeEnvironment: Bool = false) -> [String: String] {
        var exported: [String: String] = [:]

        // Add file-based config
        exported.merge(fileConfig) { (current, _) in current }

        // Add environment variables if requested
        if includeEnvironment {
            for (key, value) in ProcessInfo.processInfo.environment {
                // Skip sensitive keys
                if !isSensitiveKey(key) {
                    exported[key] = value
                }
            }
        }

        return exported
    }

    /// Check if a key is considered sensitive
    private func isSensitiveKey(_ key: String) -> Bool {
        let sensitivePatterns = [
            "PASSWORD", "SECRET", "KEY", "TOKEN", "CREDENTIAL",
            "PRIVATE", "CERT", "AUTH", "OAUTH"
        ]

        let upperKey = key.uppercased()
        return sensitivePatterns.contains { upperKey.contains($0) }
    }
}

// MARK: - Keychain Support (macOS/iOS only)
#if canImport(Security)
extension ConfigurationManager {
    private func getKeychainValue(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    private func setKeychainValue(_ key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
#endif