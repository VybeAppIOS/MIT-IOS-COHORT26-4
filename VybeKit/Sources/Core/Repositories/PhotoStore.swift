import Foundation
import Models

/// Turns a `Photo` into a file or web address the image loader can open, and keeps new photos.
public protocol PhotoStore: Sendable {
    /// Nil when there is no image.
    func url(for photo: Photo) -> URL?

    /// Keeps a photo that `PhotoProcessor` already made safe (resized, location removed) and returns the `Photo` value
    /// that messages and posts hold. Phase 1 writes a file on the phone; Phase 2 uploads it.
    func save(_ photo: ProcessedPhoto) async throws -> Photo
}
