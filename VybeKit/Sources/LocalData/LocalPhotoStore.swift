import Core
import Foundation
import Models

/// Phase 1: a photo is a file in the bundled `Content/Photos` folder. Nil when the file is not there.
public struct LocalPhotoStore: PhotoStore {
    private let photosDirectory: URL

    public init(photosDirectory: URL) {
        self.photosDirectory = photosDirectory
    }

    public init(loader: ContentLoader = .bundled) {
        self.init(photosDirectory: loader.photosDirectory)
    }

    public func url(for photo: Photo) -> URL? {
        let file = photosDirectory.appending(path: photo.path)
        return FileManager.default.fileExists(atPath: file.path) ? file : nil
    }
}
