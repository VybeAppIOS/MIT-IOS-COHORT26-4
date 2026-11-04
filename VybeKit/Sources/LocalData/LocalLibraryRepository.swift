import Core
import Foundation
import Models

/// Saved Hangouts, Drafts and runs, in `Application Support/Vybe/library.json` (through `LibraryFile`).
public struct LocalLibraryRepository: LibraryRepository {
    private let file: LibraryFile

    public init(file: LibraryFile) {
        self.file = file
    }

    /// The normal file in Application Support.
    public init() {
        self.init(file: LibraryFile(url: LocalDataPaths.libraryURL, empty: Library()))
    }

    public func load() async throws -> Library { try await file.load() }

    public func save(_ library: Library) async throws { try await file.save(library) }

    /// True once if the library file was unreadable and set aside (for a one-time notice).
    public func takeQuarantineNotice() async -> Bool { await file.takeQuarantineNotice() }
}
