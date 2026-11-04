import CoreGraphics
import Foundation
import ImageIO

/// Why an image could not be loaded. Callers show a failure state; nothing here crashes.
public enum ImageLoadError: Error, Equatable, Sendable {
    case unsupportedURL
    case fileNotFound
    case badResponse
    case decodeFailed
}

/// Loads, downsamples and caches pictures from `file://` and `https://` URLs.
public actor ImageLoader {
    public static let shared = ImageLoader()

    private let fetch: @Sendable (URL) async throws -> Data
    private let cache = NSCache<NSString, CGImage>()
    private var inFlight: [String: Task<CGImage, Error>] = [:]

    public init() {
        self.init(fetch: { url in
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                    throw ImageLoadError.badResponse
                }
                return data
            } catch let error as URLError where error.code == .fileDoesNotExist || error.code == .fileIsDirectory {
                throw ImageLoadError.fileNotFound
            }
        })
    }

    /// Tests pass their own `fetch` to count how often a URL is really read.
    init(fetch: @escaping @Sendable (URL) async throws -> Data) {
        self.fetch = fetch
        cache.totalCostLimit = 64 * 1024 * 1024
    }

    /// Sets the shared URL cache to 50 MB of memory and 200 MB of disk. Call once at launch.
    public static func configureURLCache() {
        URLCache.shared = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024)
    }

    /// Returns the picture at `url`, no larger than `maxPixelSize` on its long side.
    /// A second call for the same URL and size reuses the cache; two calls at once share one load.
    public func image(at url: URL, maxPixelSize: CGFloat) async throws -> CGImage {
        guard url.isFileURL || url.scheme == "https" else { throw ImageLoadError.unsupportedURL }
        let key = "\(url.absoluteString)@\(Int(maxPixelSize))"

        if let cached = cache.object(forKey: key as NSString) { return cached }
        if let running = inFlight[key] { return try await running.value }

        let task = Task { [fetch] in
            let data = try await fetch(url)
            return try Self.downsample(data, maxPixelSize: maxPixelSize)
        }
        inFlight[key] = task
        defer { inFlight[key] = nil }

        let image = try await task.value
        cache.setObject(image, forKey: key as NSString, cost: image.width * image.height * 4)
        return image
    }

    private static func downsample(_ data: Data, maxPixelSize: CGFloat) throws -> CGImage {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            throw ImageLoadError.decodeFailed
        }
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            throw ImageLoadError.decodeFailed
        }
        return image
    }
}
