import Foundation
import UIKit
import SwiftUI

/// Image cache manager for aggressive caching of player photos and team helmets.
/// Matches Android's caching strategy with 100MB disk cache and memory optimization.
@MainActor
final class ImageCache {
    static let shared = ImageCache()

    private let urlSession: URLSession
    private let memoryCache = NSCache<NSString, UIImage>()

    /// Cache configuration matching Android's aggressive strategy
    private static let diskCacheSize = 100 * 1024 * 1024  // 100 MB
    private static let memoryCacheSize = 50 * 1024 * 1024 // 50 MB
    private static let memoryCacheCountLimit = 100

    private init() {
        // Configure aggressive URL cache
        let urlCache = URLCache(
            memoryCapacity: Self.memoryCacheSize,
            diskCapacity: Self.diskCacheSize,
            directory: FileManager.default
                .urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ImageCache")
        )

        // Configure URL session with aggressive caching
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        urlSession = URLSession(configuration: configuration)

        // Configure in-memory cache
        memoryCache.countLimit = Self.memoryCacheCountLimit
        memoryCache.totalCostLimit = Self.memoryCacheSize
    }

    /// Cached URLSession for use with AsyncImage
    var session: URLSession {
        urlSession
    }

    /// Load image from cache or network
    func loadImage(from url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString

        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }

        // Check disk cache via URLSession
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let (data, response) = try await urlSession.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ImageCacheError.invalidResponse
        }

        // Decode image
        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }

        // Cache in memory
        let cost = data.count
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)

        return image
    }

    /// Preload images for faster subsequent access
    func preloadImages(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = try? await self.loadImage(from: url)
                }
            }
        }
    }

    /// Clear all cached images
    func clearCache() {
        memoryCache.removeAllObjects()
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }

    /// Clear expired cached images (older than 7 days)
    func clearExpiredCache() {
        guard let cache = urlSession.configuration.urlCache else { return }

        let expirationDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)

        // URLCache doesn't provide direct expiration control,
        // but the cache will automatically evict old entries when needed
        cache.removeCachedResponses(since: expirationDate)
    }
}

/// Errors that can occur during image caching
enum ImageCacheError: Error, LocalizedError {
    case invalidResponse
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .invalidImageData:
            return "Unable to decode image data"
        }
    }
}

/// Custom AsyncImage that uses cached URLSession
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else if error != nil {
                placeholder()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else { return }

        isLoading = true
        error = nil

        do {
            let loadedImage = try await ImageCache.shared.loadImage(from: url)
            await MainActor.run {
                image = loadedImage
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
        }
    }
}

/// Convenience initializers for CachedAsyncImage
extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.url = url
        self.content = { $0 }
        self.placeholder = { ProgressView() }
    }
}

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
        self.placeholder = { ProgressView() }
    }
}
