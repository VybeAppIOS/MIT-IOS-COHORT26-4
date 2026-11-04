import Foundation
import Models
import Observation

/// Saved Hangouts, Drafts and finished runs, shared by every tab so every card agrees (ADR 005).
/// Actions update memory first, then save; a failed save rolls back and sets `lastError`.
@MainActor @Observable
public final class LibraryStore {
    public private(set) var library = Library()
    public private(set) var hasLoaded = false
    /// The last failure, for a short error message. Cleared by the next success.
    public private(set) var lastError: AppError?

    private let repository: any LibraryRepository
    private let now: @Sendable () -> Date

    public init(repository: any LibraryRepository, now: @escaping @Sendable () -> Date = { Date() }) {
        self.repository = repository
        self.now = now
    }

    public var drafts: [Hangout] { library.drafts }

    /// Runs that ended and are not posted yet ("Ready to post").
    public var finishedRuns: [HangoutRun] { library.runs.filter { $0.state == .done || $0.state == .scheduled } }

    public var savedHangoutIDs: [HangoutID] {
        library.saves.sorted { $0.savedAt > $1.savedAt }.map(\.hangoutID)
    }

    public func load() async {
        do {
            library = try await repository.load()
            hasLoaded = true
            lastError = nil
        } catch is CancellationError {
            return
        } catch {
            lastError = AppError(error)
        }
    }

    public func isSaved(_ id: HangoutID) -> Bool { library.saves.contains { $0.hangoutID == id } }

    public func toggleSave(_ id: HangoutID) async {
        var changed = library
        if isSaved(id) {
            changed.saves.removeAll { $0.hangoutID == id }
        } else {
            changed.saves.append(SavedHangout(hangoutID: id, savedAt: now()))
        }
        await apply(changed)
    }

    /// Saves or replaces a draft.
    public func saveDraft(_ hangout: Hangout) async {
        var changed = library
        changed.drafts.removeAll { $0.id == hangout.id }
        changed.drafts.append(hangout)
        await apply(changed)
    }

    public func deleteDraft(_ id: HangoutID) async {
        var changed = library
        changed.drafts.removeAll { $0.id == id }
        await apply(changed)
    }

    private func apply(_ changed: Library) async {
        let previous = library
        library = changed
        do {
            try await repository.save(changed)
            lastError = nil
        } catch {
            library = previous
            lastError = AppError(error)
        }
    }
}
