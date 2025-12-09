import Foundation

/// Generic HTTP response cache using Actor for thread-safe Dictionary access.
///
/// This implements the "Dictionary in a Mutex" pattern using Swift's Actor model.
/// Actors provide built-in synchronization, making them ideal for caching.
/// This cache is Linux-compatible and avoids NSCache's Objective-C runtime dependency.
public actor HTTPCache<Value: Codable & Sendable> {
    /// Cache entry with value and expiration metadata.
    private struct CacheEntry: Sendable {
        let value: Value
        let timestamp: Date
        let expiresAt: Date
    }

    /// Thread-safe dictionary storage.
    private var cache: [String: CacheEntry] = [:]

    /// Default time-to-live for cached entries in seconds.
    private let defaultTTL: TimeInterval

    /// Creates an HTTP cache with optional default TTL.
    ///
    /// - Parameter defaultTTL: Default time-to-live in seconds (default: 1 hour).
    public init(defaultTTL: TimeInterval = 3600) {
        self.defaultTTL = defaultTTL
    }

    /// Retrieves cached value if it exists and hasn't expired.
    ///
    /// - Parameter key: Cache key.
    /// - Returns: Cached value if valid, nil otherwise.
    public func get(_ key: String) -> Value? {
        guard let entry = cache[key] else { return nil }

        // Check expiration
        if Date() > entry.expiresAt {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    /// Stores value in cache with optional custom TTL.
    ///
    /// - Parameters:
    ///   - key: Cache key.
    ///   - value: Value to cache.
    ///   - ttl: Optional custom time-to-live in seconds (defaults to defaultTTL).
    public func set(_ key: String, value: Value, ttl: TimeInterval? = nil) {
        let expiration = Date().addingTimeInterval(ttl ?? defaultTTL)
        cache[key] = CacheEntry(
            value: value,
            timestamp: Date(),
            expiresAt: expiration
        )
    }

    /// Checks if a cache entry exists and is valid.
    ///
    /// - Parameter key: Cache key.
    /// - Returns: True if entry exists and hasn't expired.
    public func isValid(_ key: String) -> Bool {
        guard let entry = cache[key] else { return false }
        return Date() <= entry.expiresAt
    }

    /// Removes expired entries from cache.
    ///
    /// Call periodically to prevent unbounded memory growth.
    public func cleanup() {
        let now = Date()
        cache = cache.filter { $0.value.expiresAt > now }
    }

    /// Clears all cached data.
    public func clear() {
        cache.removeAll()
    }

    /// Removes specific cache entry.
    ///
    /// - Parameter key: Cache key to remove.
    public func remove(_ key: String) {
        cache.removeValue(forKey: key)
    }

    /// Retrieves cache statistics for monitoring.
    ///
    /// - Returns: Tuple with count, oldest entry timestamp, and newest entry timestamp.
    public func stats() -> (count: Int, oldestEntry: Date?, newestEntry: Date?) {
        let timestamps = cache.values.map { $0.timestamp }
        return (
            count: cache.count,
            oldestEntry: timestamps.min(),
            newestEntry: timestamps.max()
        )
    }
}
