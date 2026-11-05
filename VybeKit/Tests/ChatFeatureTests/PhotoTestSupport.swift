import Core
import Foundation
import ImageIO
import Models
import Synchronization
import Testing
import UIKit
import UniformTypeIdentifiers

/// A photo store the test controls: it keeps what it was asked to save and can be told to fail.
final class ControlledPhotos: PhotoStore {
    let saved = Mutex<[ProcessedPhoto]>([])
    let failSave = Mutex(false)

    func url(for photo: Photo) -> URL? { URL(string: "https://photos.invalid/\(photo.path)") }

    func save(_ photo: ProcessedPhoto) async throws -> Photo {
        if failSave.withLock({ $0 }) { throw AppError.offline }
        let number = saved.withLock { list -> Int in
            list.append(photo)
            return list.count
        }
        return Photo(id: PhotoID("photo-test-\(number)"), path: "test-\(number).jpg", width: 10, height: 10)
    }
}

/// Real picture bytes for the photo tests.
enum TestPhotos {
    /// A small JPEG that carries a GPS position, like a picture straight from the camera.
    static func jpegWithLocation(width: Int = 120, height: Int = 90) throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        let output = NSMutableData()
        let jpeg = UTType.jpeg.identifier as CFString
        let destination = try #require(CGImageDestinationCreateWithData(output, jpeg, 1, nil))
        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 18.5074, kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 73.8077, kCGImagePropertyGPSLongitudeRef: "E"
            ]
        ]
        CGImageDestinationAddImage(destination, try #require(image.cgImage), properties as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return output as Data
    }

    static func hasLocation(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let found = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        return found[kCGImagePropertyGPSDictionary] != nil
    }
}
