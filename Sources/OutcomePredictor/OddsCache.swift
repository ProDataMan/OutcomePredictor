import Foundation

/// Two-tier cache for betting odds with memory and disk persistence.
///
/// This cache prevents excessive API calls to The Odds API (500 requests/month limit).
/// Uses NSCache for automatic memory management and disk storage for persistence across restarts.
/// Default TTL: 6 hours (odds don't change frequently).
public actor OddsCache {
    private let memoryCache: NSCache<NSString, CachedOdds>
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let cacheDuration: TimeInterval

    /// Wrapper class to store odds data with timestamp.
    private class CachedOdds: NSObject {
        let odds: [String: BettingOdds]
        let timestamp: Date

        init(odds: [String: BettingOdds], timestamp: Date = Date()) {
            self.odds = odds
            self.timestamp = timestamp
        }
    }

    /// Creates a two-tier odds cache with memory and disk storage.
    ///
    /// - Parameter cacheExpiration: Time interval before cache expires (default: 6 hours).
    public init(cacheExpiration: TimeInterval = 6 * 60 * 60) {
        self.memoryCache = NSCache<NSString, CachedOdds>()
        self.memoryCache.countLimit = 10 // Limit memory entries
        self.fileManager = FileManager.default
        self.cacheDuration = cacheExpiration

        // Setup cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = paths[0].appendingPathComponent("NFLOddsCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Check if cache is still valid based on timestamp.
    public func isValid() -> Bool {
        let cacheKey = "nfl_odds" as NSString

        // Check memory cache first
        if let cached = memoryCache.object(forKey: cacheKey) {
            return Date().timeIntervalSince(cached.timestamp) < cacheDuration
        }

        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("nfl_odds.json")
        if fileManager.fileExists(atPath: fileURL.path),
           let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            return Date().timeIntervalSince(modificationDate) < cacheDuration
        }

        return false
    }

    /// Get cached odds if available and valid.
    ///
    /// Checks memory cache first (fast), then disk cache (slower but persists).
    /// - Returns: Cached odds dictionary, or nil if cache miss or expired.
    public func getOdds() -> [String: BettingOdds]? {
        let cacheKey = "nfl_odds" as NSString

        // Try memory cache first
        if let cached = memoryCache.object(forKey: cacheKey) {
            if Date().timeIntervalSince(cached.timestamp) < cacheDuration {
                return cached.odds
            } else {
                memoryCache.removeObject(forKey: cacheKey)
            }
        }

        // Try disk cache
        let fileURL = cacheDirectory.appendingPathComponent("nfl_odds.json")
        if fileManager.fileExists(atPath: fileURL.path),
           let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modificationDate) < cacheDuration {

            // Load from disk
            if let data = try? Data(contentsOf: fileURL),
               let odds = try? JSONDecoder().decode([String: BettingOdds].self, from: data) {

                // Restore to memory cache for faster subsequent access
                let cached = CachedOdds(odds: odds, timestamp: modificationDate)
                memoryCache.setObject(cached, forKey: cacheKey)

                return odds
            }
        }

        // Cache miss or expired
        return nil
    }

    /// Update cache with new odds data.
    ///
    /// Stores in both memory (fast access) and disk (persistence).
    /// - Parameter odds: Dictionary of betting odds to cache.
    public func setOdds(_ odds: [String: BettingOdds]) {
        let cacheKey = "nfl_odds" as NSString
        let now = Date()

        // Store in memory cache
        let cached = CachedOdds(odds: odds, timestamp: now)
        memoryCache.setObject(cached, forKey: cacheKey)

        // Persist to disk
        let fileURL = cacheDirectory.appendingPathComponent("nfl_odds.json")
        if let data = try? JSONEncoder().encode(odds) {
            try? data.write(to: fileURL)
        }
    }

    /// Clear all cached data from memory and disk.
    public func clear() {
        memoryCache.removeAllObjects()

        let fileURL = cacheDirectory.appendingPathComponent("nfl_odds.json")
        try? fileManager.removeItem(at: fileURL)
    }

    /// Get cache statistics for monitoring.
    ///
    /// - Returns: Statistics including entry count, timestamps, and validity.
    public func stats() -> CacheStats {
        let cacheKey = "nfl_odds" as NSString
        var entryCount = 0
        var lastFetch: Date?
        var expiresAt: Date?

        // Check memory cache
        if let cached = memoryCache.object(forKey: cacheKey) {
            entryCount = cached.odds.count
            lastFetch = cached.timestamp
            expiresAt = cached.timestamp.addingTimeInterval(cacheDuration)
        } else {
            // Check disk cache
            let fileURL = cacheDirectory.appendingPathComponent("nfl_odds.json")
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let modificationDate = attributes[.modificationDate] as? Date,
               let data = try? Data(contentsOf: fileURL),
               let odds = try? JSONDecoder().decode([String: BettingOdds].self, from: data) {
                entryCount = odds.count
                lastFetch = modificationDate
                expiresAt = modificationDate.addingTimeInterval(cacheDuration)
            }
        }

        return CacheStats(
            entryCount: entryCount,
            lastFetch: lastFetch,
            isValid: isValid(),
            expiresAt: expiresAt
        )
    }
}

/// Cache statistics for monitoring.
public struct CacheStats: Sendable {
    public let entryCount: Int
    public let lastFetch: Date?
    public let isValid: Bool
    public let expiresAt: Date?
}
