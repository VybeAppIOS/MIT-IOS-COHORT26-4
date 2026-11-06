import Core
import Foundation
import Models

/// Phase 1: a photo is a file. Team photos are in the bundled `Content/Photos` folder; photos a person adds (for
/// example in a chat) are saved in the app's Application Support folder. `url(for:)` looks in both. Nil when the file
/// is in neither.
public struct LocalPhotoStore: PhotoStore {
    /// Where saved photos live: `Application Support/Vybe/Photos`.
    public static var defaultSavedDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "Vybe").appending(path: "Photos")
    }

    private let photosDirectory: URL
    private let savedDirectory: URL
    private let makeID: @Sendable () -> String

    public init(
        photosDirectory: URL, savedDirectory: URL = LocalPhotoStore.defaultSavedDirectory,
        makeID: @escaping @Sendable () -> String = { UUID().uuidString.lowercased() }
    ) {
        self.photosDirectory = photosDirectory
        self.savedDirectory = savedDirectory
        self.makeID = makeID
    }

    public init(loader: ContentLoader = .bundled, savedDirectory: URL = LocalPhotoStore.defaultSavedDirectory) {
        self.init(photosDirectory: loader.photosDirectory, savedDirectory: savedDirectory)
    }

    public func url(for photo: Photo) -> URL? {
        // A path that climbs out of the folder (a bad value from outside) never matches.
        guard !photo.path.split(separator: "/").contains("..") else { return nil }
        for directory in [photosDirectory, savedDirectory] {
            let file = directory.appending(path: photo.path)
            if FileManager.default.fileExists(atPath: file.path) { return file }
        }
        return nil
    }

    /// Writes the large picture as `<id>.jpg` (the thumbnail is made again from it when a list needs one).
    public func save(_ photo: ProcessedPhoto) async throws -> Photo {
        let size = photo.pixelSize
        let id = makeID()
        let path = "saved-\(id).jpg"
        try FileManager.default.createDirectory(at: savedDirectory, withIntermediateDirectories: true)
        try photo.large.write(to: savedDirectory.appending(path: path), options: .atomic)
        return Photo(id: PhotoID("photo-\(id)"), path: path, width: size?.width ?? 0, height: size?.height ?? 0)
    }
}
