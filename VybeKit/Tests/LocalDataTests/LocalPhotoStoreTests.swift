import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import LocalData

struct LocalPhotoStoreTests {
    private func processed(_ bytes: String = "large") -> ProcessedPhoto {
        ProcessedPhoto(large: Data(bytes.utf8), thumbnail: Data("small".utf8))
    }

    @Test func aSavedPhotoIsWrittenAndFoundAgain() async throws {
        let saved = try TestSupport.temporaryDirectory()
        let store = LocalPhotoStore(
            photosDirectory: TestSupport.fixtures.photosDirectory, savedDirectory: saved.appending(path: "later"),
            makeID: { "abc" })
        let photo = try await store.save(processed("hello"))
        #expect(photo.id == "photo-abc")
        let url = try #require(store.url(for: photo))
        #expect(try Data(contentsOf: url) == Data("hello".utf8))
        #expect(url.path.hasPrefix(saved.path))
    }

    @Test func eachSaveGetsItsOwnFile() async throws {
        let counter = Counter()
        let store = LocalPhotoStore(
            photosDirectory: TestSupport.fixtures.photosDirectory,
            savedDirectory: try TestSupport.temporaryDirectory(), makeID: { "id-\(counter.next())" })
        let first = try await store.save(processed("one"))
        let second = try await store.save(processed("two"))
        #expect(first.path != second.path && first.id != second.id)
        #expect(try Data(contentsOf: try #require(store.url(for: first))) == Data("one".utf8))
        #expect(try Data(contentsOf: try #require(store.url(for: second))) == Data("two".utf8))
    }

    @Test func bundledAndSavedFilesAreBothFound() async throws {
        let store = LocalPhotoStore(
            photosDirectory: TestSupport.fixtures.photosDirectory, savedDirectory: try TestSupport.temporaryDirectory())
        let bundled = Photo(id: "p1", path: "place-example-cafe-a1b2-1.jpg", width: 1, height: 1)
        let saved = try await store.save(processed())
        #expect(store.url(for: bundled) != nil)
        #expect(store.url(for: saved) != nil)
        #expect(store.url(for: Photo(id: "p3", path: "nope.jpg", width: 1, height: 1)) == nil)
    }

    @Test func aPathThatClimbsOutOfTheFolderIsNeverFound() async throws {
        let folder = try TestSupport.temporaryDirectory()
        let store = LocalPhotoStore(photosDirectory: folder, savedDirectory: folder.appending(path: "saved"))
        try Data("secret".utf8).write(to: folder.appending(path: "outside.jpg"))
        let sneaky = Photo(id: "p", path: "saved/../outside.jpg", width: 1, height: 1)
        #expect(store.url(for: sneaky) == nil)
    }

    @Test func theSizeIsReadFromTheLargePicture() async throws {
        let store = LocalPhotoStore(
            photosDirectory: TestSupport.fixtures.photosDirectory, savedDirectory: try TestSupport.temporaryDirectory())
        let photo = try await store.save(processed("not an image"))
        #expect(photo.width == 0 && photo.height == 0)   // bytes that are not a picture have no size
    }
}

private final class Counter: Sendable {
    private let value = Mutex(0)
    func next() -> Int {
        value.withLock { count -> Int in
            count += 1
            return count
        }
    }
}
