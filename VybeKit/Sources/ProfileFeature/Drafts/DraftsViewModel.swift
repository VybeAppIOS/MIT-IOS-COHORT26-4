import Components
import Core
import Foundation
import Models

/// PR5, Drafts. My unfinished Hangouts (a Remix is a Draft until it has been done), newest first. Tap to edit, swipe
/// to delete (confirmed), New Hangout to start from scratch. All in the editor cover (E1).
@MainActor @Observable
final class DraftsViewModel {
    private(set) var state: LoadState<[HangoutCardData]> = .loading
    /// The Draft waiting for "Delete?" to be confirmed.
    var pendingDelete: HangoutID?

    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let libraryStore: LibraryStore
    private let router: Router
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(places: any PlaceRepository, photos: any PhotoStore, libraryStore: LibraryStore, router: Router) {
        self.places = places
        self.photos = photos
        self.libraryStore = libraryStore
        self.router = router
    }

    var title: String { String(localized: "profile.drafts.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "profile.drafts.empty", bundle: #bundle) }
    var newTitle: String { String(localized: "profile.drafts.new", bundle: #bundle) }
    var deleteTitle: String { String(localized: "profile.drafts.delete", bundle: #bundle) }
    var deleteConfirmTitle: String { String(localized: "profile.drafts.delete.confirm", bundle: #bundle) }
    var deleteConfirmMessage: String { String(localized: "profile.drafts.delete.message", bundle: #bundle) }

    /// Bound to the confirmation dialog: true while a delete waits for an answer.
    var isConfirmingDelete: Bool {
        get { pendingDelete != nil }
        set { if !newValue { pendingDelete = nil } }
    }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        do {
            await libraryStore.ensureLoaded()
            if let error = libraryStore.lastError, !libraryStore.hasLoaded { throw error }
            var cards: [HangoutCardData] = []
            for draft in libraryStore.drafts.sorted(by: { $0.updatedAt > $1.updatedAt }) {
                let cover = try? await places.spots(for: draft).first?.photos.first
                cards.append(HangoutCardData(draft, coverURL: cover.flatMap { photos.url(for: $0) }, isSaved: false))
            }
            state = cards.isEmpty ? .empty : .loaded(cards)
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let cards, _) = state {
                state = .loaded(cards, isStale: true)
            } else {
                state = .failed(AppError(error))
            }
        }
    }

    // MARK: What the person does

    func open(_ id: HangoutID) { router.presentCover(.editor(.draft(id))) }
    func newTapped() { router.presentCover(.editor(.new)) }
    func deleteTapped(_ id: HangoutID) { pendingDelete = id }

    func deleteConfirmed() async {
        guard let id = pendingDelete else { return }
        pendingDelete = nil
        await libraryStore.deleteDraft(id)
        guard !libraryStore.drafts.contains(where: { $0.id == id }) else { return }   // failed, rolled back
        if case .loaded(let cards, let stale) = state {
            let left = cards.filter { $0.id != id }
            state = left.isEmpty ? .empty : .loaded(left, isStale: stale)
        }
    }
}
