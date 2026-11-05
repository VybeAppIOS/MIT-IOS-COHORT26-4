import Foundation
import ImageIO
import UniformTypeIdentifiers

/// The two sizes made from one picked photo.
public struct ProcessedPhoto: Sendable, Equatable {
    /// About 1600 px on the long side.
    public let large: Data
    /// About 400 px on the long side (for lists and cards).
    public let thumbnail: Data

    public init(large: Data, thumbnail: Data) {
        self.large = large
        self.thumbnail = thumbnail
    }

    /// The size of the large picture in pixels. Nil when the bytes are not an image.
    public var pixelSize: (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(large as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (width, height)
    }
}

public enum PhotoProcessingError: Error, Equatable {
    case notAnImage
    case couldNotResize
    case couldNotEncode
}

/// Makes a photo safe and small before it is saved or uploaded: it is resized and written again as a new JPEG
/// **without any metadata**, so the location (GPS), the time, the camera and every other EXIF detail are gone
/// (`docs/RISKS.md` 3). The picture is turned upright first, because the rotation tag is removed with the rest.
///
/// It is `async` and Core is not main-actor, so it runs off the main thread.
public struct PhotoProcessor: Sendable {
    public let largeLongSide: Int
    public let thumbnailLongSide: Int
    /// JPEG quality from 0 to 1.
    public let quality: Double

    public init(largeLongSide: Int = 1600, thumbnailLongSide: Int = 400, quality: Double = 0.8) {
        self.largeLongSide = largeLongSide
        self.thumbnailLongSide = thumbnailLongSide
        self.quality = quality
    }

    public func process(_ data: Data) async throws -> ProcessedPhoto {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) > 0 else {
            throw PhotoProcessingError.notAnImage
        }
        return ProcessedPhoto(
            large: try jpeg(from: source, longSide: largeLongSide),
            thumbnail: try jpeg(from: source, longSide: thumbnailLongSide))
    }

    /// Never makes a picture bigger than it was.
    private func jpeg(from source: CGImageSource, longSide: Int) throws -> Data {
        let target = min(longSide, originalLongSide(of: source) ?? longSide)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,   // apply the rotation tag, then forget it
            kCGImageSourceThumbnailMaxPixelSize: target,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw PhotoProcessingError.couldNotResize
        }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw PhotoProcessingError.couldNotEncode }
        // Adding a CGImage (not the source) carries no metadata over: that is what removes GPS and EXIF.
        let properties = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { throw PhotoProcessingError.couldNotEncode }
        return output as Data
    }

    private func originalLongSide(of source: CGImageSource) -> Int? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        let rotated = (properties[kCGImagePropertyOrientation] as? Int).map { (5...8).contains($0) } ?? false
        return max(width, height) == 0 ? nil : (rotated ? max(height, width) : max(width, height))
    }
}
