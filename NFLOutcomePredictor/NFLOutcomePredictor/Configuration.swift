import Foundation

/// Environment-aware configuration for iOS app
struct AppConfiguration {
    enum Environment {
        case debug
        case release
        
        static var current: Environment {
            #if DEBUG
            return .debug
            #else
            return .release
            #endif
        }
    }
    
    static let environment = Environment.current
    
    /// API Base URL - automatically switches based on build configuration
    static var apiBaseURL: String {
        switch environment {
        case .debug:
            // Local Docker container
            return "http://localhost:8080/api/v1"
        case .release:
            // Azure production
            return "https://statshark-api.azurewebsites.net/api/v1"
        }
    }
    
    /// Check if running in debug mode
    static var isDebug: Bool {
        environment == .debug
    }
    
    /// Check if running in release mode
    static var isRelease: Bool {
        environment == .release
    }
}
