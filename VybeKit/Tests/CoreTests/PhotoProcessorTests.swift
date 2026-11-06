import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import Core

struct PhotoProcessorTests {
    /// A smooth picture (so it compresses like a real photo), optionally carrying GPS, EXIF and a rotation tag.
    private func makeImage(
        width: Int, height: Int, orientation: Int? = nil, withMetadata: Bool = true
    ) throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            let colors = [UIColor.systemOrange.cgColor, UIColor.systemTeal.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            context.cgContext.drawLinearGradient(
                gradient, start: .zero, end: CGPoint(x: width, y: height), options: [])
            UIColor.white.setFill()
            context.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        }
        let output = NSMutableData()
        let jpeg = UTType.jpeg.identifier as CFString
        let destination = try #require(CGImageDestinationCreateWithData(output, jpeg, 1, nil))
        var properties: [CFString: Any] = [:]
        if withMetadata {
            properties[kCGImagePropertyGPSDictionary] = [
                kCGImagePropertyGPSLatitude: 18.5074, kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 73.8077, kCGImagePropertyGPSLongitudeRef: "E"
            ]
            properties[kCGImagePropertyExifDictionary] = [kCGImagePropertyExifUserComment: "EXAMPLE secret comment"]
            properties[kCGImagePropertyTIFFDictionary] = [kCGImagePropertyTIFFMake: "EXAMPLE Camera"]
        }
        if let orientation { properties[kCGImagePropertyOrientation] = orientation }
        CGImageDestinationAddImage(destination, try #require(image.cgImage), properties as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return output as Data
    }

    private func properties(of data: Data) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        return try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    }

    private func size(of data: Data) throws -> (width: Int, height: Int) {
        let found = try properties(of: data)
        let width = try #require(found[kCGImagePropertyPixelWidth] as? Int)
        let height = try #require(found[kCGImagePropertyPixelHeight] as? Int)
        return (width, height)
    }

    @Test func theTestImageReallyCarriesGPSAndExif() throws {
        let original = try properties(of: try makeImage(width: 800, height: 600))
        #expect(original[kCGImagePropertyGPSDictionary] != nil)
        #expect(original[kCGImagePropertyExifDictionary] != nil)
    }

    @Test func locationAndOtherMetadataAreRemoved() async throws {
        let result = try await PhotoProcessor().process(try makeImage(width: 4000, height: 3000))
        for data in [result.large, result.thumbnail] {
            let found = try properties(of: data)
            #expect(found[kCGImagePropertyGPSDictionary] == nil)
            // The JPEG encoder itself writes a few technical fields (pixel size, colour space). Nothing personal may
            // be left: no comment, date, camera, lens or settings.
            let exif = (found[kCGImagePropertyExifDictionary] as? [CFString: Any]) ?? [:]
            let technical: Set<String> = [
                kCGImagePropertyExifPixelXDimension, kCGImagePropertyExifPixelYDimension,
                kCGImagePropertyExifColorSpace
            ].map { $0 as String }.reduce(into: []) { $0.insert($1) }
            let extra = Set(exif.keys.map { $0 as String }).subtracting(technical)
            #expect(extra.isEmpty, "EXIF fields left in the output: \(extra.sorted())")
            let tiff = found[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            #expect(tiff?[kCGImagePropertyTIFFMake] == nil)
            // The secret words must not appear anywhere in the file's bytes, not just in the parsed fields.
            #expect(data.range(of: Data("EXAMPLE secret comment".utf8)) == nil)
            #expect(data.range(of: Data("EXAMPLE Camera".utf8)) == nil)
        }
    }

    @Test func bothSizesAreAsRequested() async throws {
        let result = try await PhotoProcessor().process(try makeImage(width: 4000, height: 3000))
        let large = try size(of: result.large)
        let thumbnail = try size(of: result.thumbnail)
        #expect(large.width == 1600 && large.height == 1200)
        #expect(thumbnail.width == 400 && thumbnail.height == 300)
    }

    @Test func thePortraitLongSideIsTheHeight() async throws {
        let result = try await PhotoProcessor().process(try makeImage(width: 3000, height: 4000))
        #expect(try size(of: result.large) == (1200, 1600))
    }

    @Test func theRotationTagIsAppliedBeforeItIsDropped() async throws {
        // Stored as 4000 x 3000 but tagged "rotate 90 degrees": it is a portrait photo.
        let result = try await PhotoProcessor().process(try makeImage(width: 4000, height: 3000, orientation: 6))
        let large = try size(of: result.large)
        #expect(large.width == 1200 && large.height == 1600)
        #expect(try properties(of: result.large)[kCGImagePropertyOrientation] as? Int ?? 1 == 1)
    }

    @Test func aSmallPictureIsNotMadeBigger() async throws {
        let result = try await PhotoProcessor().process(try makeImage(width: 800, height: 600))
        #expect(try size(of: result.large) == (800, 600))
        #expect(try size(of: result.thumbnail) == (400, 300))
    }

    @Test func theLargeSizeIsSmallEnough() async throws {
        let result = try await PhotoProcessor().process(try makeImage(width: 4000, height: 3000))
        #expect(result.large.count < 300_000, "large JPEG is \(result.large.count) bytes")
        #expect(result.thumbnail.count < result.large.count)
    }

    @Test func lowerQualityMakesASmallerFile() async throws {
        let image = try makeImage(width: 3000, height: 2000)
        let normal = try await PhotoProcessor(quality: 0.8).process(image)
        let rough = try await PhotoProcessor(quality: 0.2).process(image)
        #expect(rough.large.count < normal.large.count)
    }

    @Test func customSizesAreUsed() async throws {
        let result = try await PhotoProcessor(largeLongSide: 1000, thumbnailLongSide: 100)
            .process(try makeImage(width: 4000, height: 3000))
        #expect(try size(of: result.large) == (1000, 750))
        #expect(try size(of: result.thumbnail) == (100, 75))
    }

    @Test func outputIsAlwaysAJPEG() async throws {
        let result = try await PhotoProcessor().process(try makeImage(width: 1000, height: 800))
        for data in [result.large, result.thumbnail] {
            #expect(Array(data.prefix(2)) == [0xFF, 0xD8])
        }
    }

    @Test func somethingThatIsNotAPictureIsRefused() async {
        await #expect(throws: PhotoProcessingError.notAnImage) {
            try await PhotoProcessor().process(Data("hello".utf8))
        }
        await #expect(throws: PhotoProcessingError.notAnImage) { try await PhotoProcessor().process(Data()) }
    }

    @Test func theProcessedPhotoKnowsItsSize() async throws {
        let result = try await PhotoProcessor().process(try makeImage(width: 4000, height: 3000))
        #expect(result.pixelSize?.width == 1600 && result.pixelSize?.height == 1200)
        #expect(ProcessedPhoto(large: Data("x".utf8), thumbnail: Data()).pixelSize == nil)
    }

    #if DEBUG
    @Test func theStubPhotoStoreHandsOutNewPhotosAndKeepsNoFiles() async throws {
        let store = StubPhotoStore()
        let processed = try await PhotoProcessor().process(try makeImage(width: 800, height: 600))
        let first = try await store.save(processed)
        let second = try await store.save(processed)
        #expect(first.id != second.id && first.path != second.path)
        #expect(first.width == 800 && first.height == 600)
        #expect(store.url(for: first) == nil)
    }
    #endif
}
