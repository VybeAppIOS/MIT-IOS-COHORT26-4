import Foundation
import Models

/// A Hangout the person saved.
public struct SavedHangout: Codable, Hashable, Sendable {
    public var hangoutID: HangoutID
    public var savedAt: Date

    public init(hangoutID: HangoutID, savedAt: Date) {
        self.hangoutID = hangoutID
        self.savedAt = savedAt
    }
}

/// Everything that is the person's own and lives on the phone: Saved, Drafts and their runs.
/// `runTimes` holds the owner-only exact times for each run (ADR 004).
public struct Library: Codable, Hashable, Sendable {
    public var saves: [SavedHangout]
    public var drafts: [Hangout]
    public var runs: [HangoutRun]
    public var runTimes: [RunID: RunTimes]

    public init(
        saves: [SavedHangout] = [], drafts: [Hangout] = [], runs: [HangoutRun] = [], runTimes: [RunID: RunTimes] = [:]
    ) {
        self.saves = saves
        self.drafts = drafts
        self.runs = runs
        self.runTimes = runTimes
    }
}

/// Reads and writes the whole library at once. Implementations write through one serial writer (ADR 005),
/// so the newest `save` always wins. Deleting an item is saving the library without it.
public protocol LibraryRepository: Sendable {
    func load() async throws -> Library
    func save(_ library: Library) async throws
}
