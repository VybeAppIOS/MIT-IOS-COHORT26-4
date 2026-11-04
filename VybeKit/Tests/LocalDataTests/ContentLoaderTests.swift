import Foundation
import Models
import Testing
@testable import LocalData

struct ContentLoaderTests {
    @Test func loadsEveryPlaceAndHangoutInTheFolder() throws {
        let snapshot = try TestSupport.fixtures.load()
        #expect(snapshot.places.count == 3)
        #expect(snapshot.hangouts.count == 4)
        #expect(snapshot.hangouts.map(\.id).contains("hangout-example-evening-c3d4"))
    }

    @Test func filesAreReadInNameOrder() throws {
        let names = try TestSupport.fixtures.load().places.map(\.id.rawValue)
        #expect(names == names.sorted())
    }

    @Test func aMissingFolderIsAnError() {
        let loader = ContentLoader(contentDirectory: URL.temporaryDirectory.appending(path: "no-such-\(UUID())"))
        #expect(throws: ContentError.self) { try loader.load() }
    }

    @Test func anEmptyFolderGivesNothing() throws {
        let snapshot = try ContentLoader(contentDirectory: try TestSupport.temporaryDirectory()).load()
        #expect(snapshot.places.isEmpty && snapshot.hangouts.isEmpty)
    }

    @Test func nonJSONFilesAreIgnored() throws {
        let loader = try TestSupport.contentFolder([
            .init("Places", ".gitkeep", ""), .init("Hangouts", "notes.txt", "hi")
        ])
        #expect(try loader.load().places.isEmpty)
    }

    @Test func aNewerMajorVersionIsRejectedWithTheFileName() throws {
        let future = #"{"schemaVersion": 2, "id": "x"}"#
        let loader = try TestSupport.contentFolder([.init("Places", "place-future.json", future)])
        #expect(throws: ContentError.unsupportedSchema(file: "place-future.json", found: 2, supported: 1)) {
            try loader.load()
        }
    }

    @Test func anOlderVersionIsAccepted() throws {
        let json = try String(contentsOf: TestSupport.fixtures.contentDirectory
            .appending(path: "Places/place-example-park-e5f6.json"), encoding: .utf8)
            .replacingOccurrences(of: "\"schemaVersion\": 1", with: "\"schemaVersion\": 0")
        let loader = try TestSupport.contentFolder([.init("Places", "place-old.json", json)])
        #expect(try loader.load().places.map(\.id) == ["place-example-park-e5f6"])
    }

    @Test func aFileWithoutSchemaVersionIsRejected() throws {
        let loader = try TestSupport.contentFolder([.init("Hangouts", "h.json", #"{"id": "x"}"#)])
        #expect(throws: ContentError.missingSchemaVersion(file: "h.json")) { try loader.load() }
    }

    @Test func aBrokenFileNamesItself() throws {
        let todo = #"{"schemaVersion": 1, "id": "p", "coordinate": "TODO"}"#
        let loader = try TestSupport.contentFolder([.init("Places", "place-todo.json", todo)])
        do {
            _ = try loader.load()
            Issue.record("expected an error")
        } catch let ContentError.invalidFile(file, _) {
            #expect(file == "place-todo.json")
        }
    }

    @Test func theStoreLoadsOnceAndRetriesAfterAFailure() async throws {
        let store = TestSupport.content
        let first = try await store.snapshot()
        #expect(try await store.snapshot().places == first.places)

        let missing = URL.temporaryDirectory.appending(path: "no-\(UUID())")
        let broken = ContentStore(loader: ContentLoader(contentDirectory: missing))
        await #expect(throws: ContentError.self) { try await broken.snapshot() }
    }

    @Test func bundledContentFolderIsFound() throws {
        _ = try ContentLoader.bundled.load()
    }
}
