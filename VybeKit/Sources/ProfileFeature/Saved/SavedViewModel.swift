import Components
import Core
import Foundation
import Models

/// One saved Hangout: either a card to open, or one that can no longer be opened (it was removed or made private).
enum SavedItem: Identifiable, Equatable {
    case available(HangoutCardData)
    case unavailable(HangoutID)

    var id: HangoutID {
        switch self {
        case .available(let card): card.id
        case .unavailable(let id): id
        }
    }
}

/// PR4, Saved. My saved Hangouts, newest first, from the shared library. Swipe to unsave, with Undo.
@MainActor @Observable
final class SavedViewModel {
    private(set) var state: LoadState<[SavedItem]> = .loading
    /// The Hangout just unsaved, so Undo can put it back. Cleared by the next unsave or a reload.
    private(set) var lastRemoved: HangoutID?

    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let libraryStore: LibraryStore
    private let router: Router
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(
        hangouts: any HangoutRepository, places: any PlaceRepository, photos: any PhotoStore,
        libraryStore: LibraryStore, router: Router
    ) {
        self.hangouts = hangouts
        self.places = places
        self.photos = photos
        self.libraryStore = libraryStore
        self.router = router
    }

    var title: String { String(localized: "profile.saved.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "profile.saved.empty", bundle: #bundle) }
    var unavailableTitle: String { String(localized: "profile.saved.unavailable", bundle: #bundle) }
    var unavailableBody: String { String(localized: "profile.saved.unavailable.body", bundle: #bundle) }
    var removeTitle: String { String(localized: "profile.saved.remove", bundle: #bundle) }
    var removedMessage: String { String(localized: "profile.saved.removed", bundle: #bundle) }
    var undoTitle: String { String(localized: "profile.saved.undo", bundle: #bundle) }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async {
        lastRemoved = nil
        await fetch()
    }

    private func fetch() async {
        do {
            await libraryStore.ensureLoaded()
            if let error = libraryStore.lastError, !libraryStore.hasLoaded { throw error }
            var items: [SavedItem] = []
            for id in libraryStore.savedHangoutIDs {
                items.append(try await item(for: id))
            }
            state = items.isEmpty ? .empty : .loaded(items)
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let items, _) = state {
                state = .loaded(items, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))
            }
        }
    }

    /// A Hangout that is gone (`notFound`) becomes an "unavailable" row; any other failure fails the load.
    private func item(for id: HangoutID) async throws -> SavedItem {
        do {
            let hangout = try await hangouts.hangout(id: id)
            let cover = try await places.spots(for: hangout).first?.photos.first
            return .available(HangoutCardData(hangout, coverURL: cover.flatMap { photos.url(for: $0) },
                                              isSaved: true))
        } catch AppError.notFound {
            return .unavailable(id)
        }
    }

    // MARK: What the person does

    func open(_ id: HangoutID) { router.open(.hangout(id)) }

    /// Unsaves at once (the row leaves the list) and offers Undo.
    func remove(_ id: HangoutID) async {
        guard libraryStore.isSaved(id) else { return }
        await libraryStore.toggleSave(id)
        guard !libraryStore.isSaved(id) else { return }   // the save failed and was rolled back
        lastRemoved = id
        if case .loaded(let items, let stale) = state {
            let left = items.filter { $0.id != id }
            state = left.isEmpty ? .empty : .loaded(left, isStale: stale)
        }
    }

    /// Saves the last removed Hangout again and shows it.
    func undo() async {
        guard let id = lastRemoved else { return }
        lastRemoved = nil
        await libraryStore.toggleSave(id)
        await fetch()
    }
}
