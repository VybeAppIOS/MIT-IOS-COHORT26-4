import Core
import Foundation
import Models
import Testing
@testable import LocalData

struct DocumentFileTests {
    private func file(
        _ name: String = "library.json", now: @escaping @Sendable () -> Date = { Date() }
    ) throws -> (LibraryFile, URL) {
        let url = try TestSupport.temporaryDirectory().appending(path: name)
        return (LibraryFile(url: url, empty: Library(), now: now), url)
    }

    private func library(saved count: Int) -> Library {
        let epoch = Date(timeIntervalSince1970: 0)
        return Library(saves: (0..<count).map { SavedHangout(hangoutID: HangoutID("h\($0)"), savedAt: epoch) })
    }

    @Test func aMissingFileIsAnEmptyLibrary() async throws {
        #expect(try await file().0.load() == Library())
    }

    @Test func theLibraryRoundTripsToDisk() async throws {
        let (writer, url) = try file()
        var original = library(saved: 2)
        let times = RunTimes(startedAt: Date(timeIntervalSince1970: 100),
                             visitedAt: ["s1": Date(timeIntervalSince1970: 200)])
        original.runTimes = ["r1": times]
        try await writer.save(original)
        #expect(try await LibraryFile(url: url, empty: Library()).load() == original)
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("\"schemaVersion\":1"))
    }

    @Test func missingFoldersAreCreated() async throws {
        let url = try TestSupport.temporaryDirectory().appending(path: "a/b/library.json")
        try await LibraryFile(url: url, empty: Library()).save(Library())
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test func tenQuickSavesLeaveOneValidFile() async throws {
        let (writer, url) = try file()
        await withTaskGroup(of: Void.self) { group in
            for count in 1...10 {
                group.addTask { try? await writer.save(library(saved: count)) }
            }
        }
        let loaded = try await LibraryFile(url: url, empty: Library()).load()
        #expect((1...10).contains(loaded.saves.count))
        let folder = try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path)
        #expect(folder == ["library.json"])
    }

    @Test func tenSequentialSavesEndWithTheLastOne() async throws {
        let (writer, url) = try file()
        for count in 1...10 { try await writer.save(library(saved: count)) }
        #expect(try await LibraryFile(url: url, empty: Library()).load().saves.count == 10)
    }

    @Test func aCorruptFileIsSetAsideAndTheAppStartsEmpty() async throws {
        let (writer, url) = try file(now: { Date(timeIntervalSince1970: 1_793_700_000) })
        try "{ this is not json".write(to: url, atomically: true, encoding: .utf8)
        #expect(try await writer.load() == Library())
        #expect(!FileManager.default.fileExists(atPath: url.path))
        let kept = url.deletingLastPathComponent().appending(path: "library.corrupt-1793700000.json")
        #expect(try String(contentsOf: kept, encoding: .utf8) == "{ this is not json")
        #expect(await writer.takeQuarantineNotice())
        #expect(await !writer.takeQuarantineNotice())
    }

    @Test func aNewerFileIsRejectedAndLeftUntouched() async throws {
        let (writer, url) = try file()
        let future = #"{"schemaVersion": 2, "value": {}}"#
        try future.write(to: url, atomically: true, encoding: .utf8)
        await #expect(throws: DocumentFileError.newerVersion(found: 2, supported: 1)) { try await writer.load() }
        #expect(try String(contentsOf: url, encoding: .utf8) == future)
    }

    @Test func theProfileIsDefaultThenSavedThenReloaded() async throws {
        let url = try TestSupport.temporaryDirectory().appending(path: "profile.json")
        let fallback = UserProfile(id: "user-local", username: "you", displayName: "You",
                                   createdAt: Date(timeIntervalSince1970: 0))
        let repository = LocalProfileRepository(file: DocumentFile(url: url, empty: fallback))
        #expect(try await repository.currentProfile() == fallback)
        var renamed = fallback
        renamed.displayName = "Sample Renamed"
        _ = try await repository.update(renamed)
        let again = LocalProfileRepository(file: DocumentFile(url: url, empty: fallback))
        #expect(try await again.currentProfile().displayName == "Sample Renamed")
        await #expect(throws: AppError.notFound) { try await again.profile(id: "someone-else") }
    }
}
