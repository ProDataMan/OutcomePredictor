import Foundation
#if canImport(AsyncHTTPClient)
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP client wrapper using AsyncHTTPClient for optimal Linux performance.
///
/// AsyncHTTPClient provides 5-10x better performance than URLSession on Linux.
/// This wrapper provides a unified interface that uses:
/// - AsyncHTTPClient on server platforms (Linux, macOS server-side code)
/// - URLSession fallback on iOS where AsyncHTTPClient isn't needed
public struct HTTPClient: Sendable {
    #if canImport(AsyncHTTPClient)
    private static let shared = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .singleton)
    #endif

    /// Creates an HTTP client.
    public init() {}

    /// Performs GET request.
    ///
    /// - Parameters:
    ///   - url: URL string to request.
    ///   - headers: Optional HTTP headers.
    ///   - timeout: Request timeout in seconds (default: 30).
    /// - Returns: Tuple of response data and HTTP status code.
    /// - Throws: HTTPClientError on failures.
    public func get(
        url: String,
        headers: HTTPHeaders = [:],
        timeout: TimeInterval = 30
    ) async throws -> (Data, Int) {
        #if canImport(AsyncHTTPClient)
        guard let urlObj = URL(string: url) else {
            throw HTTPClientError.invalidURL(url)
        }

        var request = AsyncHTTPClient.HTTPClientRequest(url: url)
        request.method = .GET
        for (name, value) in headers {
            request.headers.add(name: name, value: value)
        }

        let response = try await Self.shared.execute(
            request,
            timeout: .seconds(Int64(timeout))
        )

        let body = try await response.body.collect(upTo: 10 * 1024 * 1024) // 10MB limit
        let data = Data(buffer: body)

        return (data, Int(response.status.code))
        #else
        // Fallback to URLSession on iOS
        guard let urlObj = URL(string: url) else {
            throw HTTPClientError.invalidURL(url)
        }

        var request = URLRequest(url: urlObj)
        request.timeoutInterval = timeout
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return (data, statusCode)
        #endif
    }

    /// Performs POST request with body data.
    ///
    /// - Parameters:
    ///   - url: URL string to request.
    ///   - headers: Optional HTTP headers.
    ///   - body: Request body data.
    ///   - timeout: Request timeout in seconds (default: 30).
    /// - Returns: Tuple of response data and HTTP status code.
    /// - Throws: HTTPClientError on failures.
    public func post(
        url: String,
        headers: HTTPHeaders = [:],
        body: Data,
        timeout: TimeInterval = 30
    ) async throws -> (Data, Int) {
        #if canImport(AsyncHTTPClient)
        guard let urlObj = URL(string: url) else {
            throw HTTPClientError.invalidURL(url)
        }

        var request = AsyncHTTPClient.HTTPClientRequest(url: url)
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        for (name, value) in headers {
            request.headers.add(name: name, value: value)
        }
        request.body = .bytes(ByteBuffer(data: body))

        let response = try await Self.shared.execute(
            request,
            timeout: .seconds(Int64(timeout))
        )

        let responseBody = try await response.body.collect(upTo: 10 * 1024 * 1024)
        let data = Data(buffer: responseBody)

        return (data, Int(response.status.code))
        #else
        // Fallback to URLSession on iOS
        guard let urlObj = URL(string: url) else {
            throw HTTPClientError.invalidURL(url)
        }

        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return (data, statusCode)
        #endif
    }
}

/// HTTP header dictionary.
public typealias HTTPHeaders = [String: String]

/// HTTP client errors.
public enum HTTPClientError: Error, LocalizedError {
    case invalidURL(String)
    case httpError(Int)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .invalidResponse:
            return "Invalid HTTP response"
        }
    }
}
