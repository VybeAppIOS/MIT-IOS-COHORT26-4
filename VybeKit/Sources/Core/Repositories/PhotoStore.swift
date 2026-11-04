import Foundation
import Models

/// Turns a `Photo` into a file or web address the image loader can open. Nil when there is no image.
public protocol PhotoStore: Sendable {
    func url(for photo: Photo) -> URL?
}
