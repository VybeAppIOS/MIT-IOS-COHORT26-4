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
    /// The last failure of a write-behind save (the live run). Cleared by the next successful save.
    public private(set) var persistenceError: AppError?

    private var pendingSave = false
    private var saveTask: Task<Void, Never>?

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

    /// Reads the library from disk if that has not happened yet. Every change calls it first: saving before the file
    /// was read would write a nearly empty library over the person's real one (for example when the file is from a
    /// newer app version and `load()` refused it).
    public func ensureLoaded() async {
        if !hasLoaded { await load() }
    }

    public func isSaved(_ id: HangoutID) -> Bool { library.saves.contains { $0.hangoutID == id } }

    public func toggleSave(_ id: HangoutID) async {
        await ensureLoaded()
        guard hasLoaded else { return }   // `lastError` already says why
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
        await ensureLoaded()
        guard hasLoaded else { return }
        var changed = library
        changed.drafts.removeAll { $0.id == hangout.id }
        changed.drafts.append(hangout)
        await apply(changed)
    }

    public func deleteDraft(_ id: HangoutID) async {
        await ensureLoaded()
        guard hasLoaded else { return }
        var changed = library
        changed.drafts.removeAll { $0.id == id }
        await apply(changed)
    }

    /// Runs that are being done right now.
    public var liveRun: HangoutRun? { library.runs.first { $0.state == .live } }

    /// Adds or replaces a run and its owner-only times. Memory changes at once; the file is written behind
    /// (ADR 005): changes that arrive while a save is running are folded into one more save of the latest library.
    public func updateRun(_ run: HangoutRun, times: RunTimes?) {
        var changed = library
        if let index = changed.runs.firstIndex(where: { $0.id == run.id }) {
            changed.runs[index] = run
        } else {
            changed.runs.append(run)
        }
        changed.runTimes[run.id] = times
        library = changed
        scheduleSave()
    }

    public func removeRun(_ id: RunID) {
        var changed = library
        changed.runs.removeAll { $0.id == id }
        changed.runTimes[id] = nil
        library = changed
        scheduleSave()
    }

    /// Waits until every write-behind save has finished. Call it when the app goes to the background.
    public func flush() async {
        while let task = saveTask { await task.value }
    }

    private func scheduleSave() {
        pendingSave = true
        guard saveTask == nil else { return }
        saveTask = Task { await drainSaves() }
    }

    /// Saves the latest library until nothing changed during the last save. A failure keeps the memory as it is,
    /// is logged without personal data, and is retried by the next change (which saves the whole library again).
    private func drainSaves() async {
        while pendingSave {
            pendingSave = false
            // Never write before the file was read: that would replace the person's library with this one.
            guard hasLoaded else {
                persistenceError = lastError ?? .unknown
                Log.data.error("The library was not saved because it has not been read from disk yet.")
                break
            }
            do {
                try await repository.save(library)
                persistenceError = nil
            } catch {
                persistenceError = AppError(error)
                Log.data.error("The library could not be saved.")
            }
        }
        saveTask = nil
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
