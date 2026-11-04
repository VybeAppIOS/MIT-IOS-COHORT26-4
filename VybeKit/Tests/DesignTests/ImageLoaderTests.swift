import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Design

private actor FetchCounter {
    private(set) var count = 0
    func bump() { count += 1 }
}

/// Draws a plain grey picture in memory and encodes it as PNG. No real photos are needed.
private func makePNG(width: Int, height: Int) -> Data {
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue
    )!
    context.setFillColor(gray: 0.5, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let output = NSMutableData()
    let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    return output as Data
}

private let sampleURL = URL(string: "https://example.invalid/kothrud-sample.png")!

@Test func sameURLTwiceLoadsOnce() async throws {
    let counter = FetchCounter()
    let png = makePNG(width: 800, height: 400)
    let loader = ImageLoader(fetch: { _ in
        await counter.bump()
        return png
    })

    _ = try await loader.image(at: sampleURL, maxPixelSize: 200)
    _ = try await loader.image(at: sampleURL, maxPixelSize: 200)

    #expect(await counter.count == 1)
}

@Test func twoRequestsAtOnceShareOneLoad() async throws {
    let counter = FetchCounter()
    let png = makePNG(width: 800, height: 400)
    let loader = ImageLoader(fetch: { _ in
        await counter.bump()
        try await Task.sleep(for: .milliseconds(50))
        return png
    })

    async let first = loader.image(at: sampleURL, maxPixelSize: 200)
    async let second = loader.image(at: sampleURL, maxPixelSize: 200)
    _ = try await (first, second)

    #expect(await counter.count == 1)
}

@Test func downsampleIsNoLargerThanRequested() async throws {
    let png = makePNG(width: 800, height: 400)
    let loader = ImageLoader(fetch: { _ in png })

    let image = try await loader.image(at: sampleURL, maxPixelSize: 100)

    #expect(max(image.width, image.height) <= 100)
}

@Test func missingFileIsAnErrorNotACrash() async {
    let loader = ImageLoader()
    let missing = URL(fileURLWithPath: "/definitely/not/here.png")

    await #expect(throws: ImageLoadError.fileNotFound) {
        try await loader.image(at: missing, maxPixelSize: 100)
    }
}

@Test func loadsARealFileURL() async throws {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).png")
    try makePNG(width: 300, height: 300).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }

    let image = try await ImageLoader().image(at: file, maxPixelSize: 100)

    #expect(max(image.width, image.height) <= 100)
}

@Test func unsupportedSchemeIsRejected() async {
    let loader = ImageLoader()

    await #expect(throws: ImageLoadError.unsupportedURL) {
        try await loader.image(at: URL(string: "http://example.invalid/a.png")!, maxPixelSize: 100)
    }
}

@Test func bytesThatAreNotAnImageGiveDecodeFailed() async {
    let loader = ImageLoader(fetch: { _ in Data([0, 1, 2, 3]) })

    await #expect(throws: ImageLoadError.decodeFailed) {
        try await loader.image(at: sampleURL, maxPixelSize: 100)
    }
}
