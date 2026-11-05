import Core
import Foundation
import Models

/// One Spot of the post, read-only: "1. EXAMPLE Chai Tapri".
struct EditPostSpotRow: Identifiable, Equatable {
    let id: Int
    let text: String
}

/// PO2, Edit post (`Sheet.editPost(runID)`). Title, caption, photos (reorder and take out), tags and audience can
/// change; the Spots cannot ("Spots can't be changed after posting"). Delete post asks first; its comments go with it.
/// Works on my own posted or scheduled run in the library (see the WO-3 report: the feed has no edit call yet).
@MainActor @Observable
final class EditPostViewModel {
    private(set) var state: LoadState<RunID> = .loading
    var title = ""
    var caption = ""
    private(set) var photos: [Photo] = []
    private(set) var coverID: PhotoID?
    private(set) var tags: Set<String> = []
    private(set) var visibility: Visibility = .friends
    private(set) var spotRows: [EditPostSpotRow] = []
    var isConfirmingPublic = false
    var isConfirmingDelete = false
    private(set) var isSaving = false

    private var run: HangoutRun?
    private let runID: RunID
    private let libraryStore: LibraryStore
    private let places: any PlaceRepository
    private let photoStore: any PhotoStore
    private let session: SessionStore
    private let router: Router
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(
        runID: RunID, libraryStore: LibraryStore, places: any PlaceRepository, photos: any PhotoStore,
        session: SessionStore, router: Router
    ) {
        self.runID = runID
        self.libraryStore = libraryStore
        self.places = places
        self.photoStore = photos
        self.session = session
        self.router = router
    }

    // MARK: Words

    var screenTitle: String { String(localized: "posting.edit.title", bundle: #bundle) }
    var saveTitle: String { String(localized: "posting.edit.save", bundle: #bundle) }
    var spotsLocked: String { String(localized: "posting.edit.spotsLocked", bundle: #bundle) }
    var deleteTitle: String { String(localized: "posting.edit.delete", bundle: #bundle) }
    var deleteConfirmTitle: String { String(localized: "posting.edit.delete.confirm", bundle: #bundle) }
    var deleteConfirmMessage: String { String(localized: "posting.edit.delete.message", bundle: #bundle) }
    var publicWarning: String { String(localized: "posting.audience.warning", bundle: #bundle) }
    var publicConfirmTitle: String { String(localized: "posting.audience.confirm", bundle: #bundle) }
    var publicConfirmButton: String { String(localized: "posting.audience.confirm.yes", bundle: #bundle) }

    let tagOptions: [ComposerOption<String>] = ComposerViewModel.tagIDs.map {
        ComposerOption(value: $0, title: String(localized: String.LocalizationValue(stringLiteral: "posting.tag." + $0),
                                                bundle: #bundle))
    }

    let audienceOptions: [ComposerOption<Visibility>] = [
        ComposerOption(value: .friends, title: String(localized: "posting.audience.friends", bundle: #bundle)),
        ComposerOption(value: .public, title: String(localized: "posting.audience.public", bundle: #bundle))
    ]

    var privateNote: String? {
        session.currentUser?.isPrivate == true ? String(localized: "posting.audience.private", bundle: #bundle) : nil
    }

    // MARK: Rules

    var titleError: String? {
        let count = title.trimmingCharacters(in: .whitespacesAndNewlines).count
        return (1...ComposerViewModel.titleLimit).contains(count)
            ? nil : String(localized: "posting.error.title", bundle: #bundle)
    }

    var captionError: String? {
        caption.count > ComposerViewModel.captionLimit
            ? String(localized: "posting.error.caption", bundle: #bundle) : nil
    }

    var canSave: Bool { run != nil && titleError == nil && captionError == nil && !isSaving }

    var photoRows: [ComposerPhotoRow] {
        photos.enumerated().map { index, photo in
            ComposerPhotoRow(
                id: photo.id, url: photoStore.url(for: photo), isCover: photo.id == coverID,
                label: String(format: String(localized: "posting.photo.label", bundle: #bundle), index + 1))
        }
    }

    // MARK: Loading

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        await libraryStore.ensureLoaded()
        if let error = libraryStore.lastError, !libraryStore.hasLoaded {
            if case .loaded = state { return }   // a failed refresh keeps what is on screen
            state = .failed(error)
            return
        }
        let editable: Set<RunState> = [.scheduled, .posted]
        guard let found = libraryStore.library.runs.first(where: { $0.id == runID && editable.contains($0.state) })
        else {
            state = .failed(.notFound)
            return
        }
        guard !hasLoaded else { return }   // a refresh never throws away what the person typed
        run = found
        title = found.title ?? found.card.hangoutTitle
        caption = found.caption ?? ""
        photos = found.photos
        coverID = found.coverPhotoID ?? found.photos.first?.id
        tags = Set(found.tags)
        visibility = found.visibility
        spotRows = await spotNames(found.visits)
        hasLoaded = true
        state = .loaded(found.id)
    }

    /// "1. EXAMPLE Chai Tapri". A Place that cannot be read shows its number only.
    private func spotNames(_ visits: [Visit]) async -> [EditPostSpotRow] {
        var rows: [EditPostSpotRow] = []
        for visit in visits.sorted(by: { $0.order < $1.order }) {
            let name = try? await places.place(id: visit.placeID).name
            let text = String(format: String(localized: "posting.edit.spot", bundle: #bundle), visit.order,
                              name ?? "")
            rows.append(EditPostSpotRow(id: visit.order, text: text))
        }
        return rows
    }

    // MARK: What the person does

    func toggleTag(_ id: String) {
        if tags.contains(id) { tags.remove(id) } else { tags.insert(id) }
    }

    func audienceTapped(_ choice: Visibility) {
        if choice == .public && visibility != .public {
            isConfirmingPublic = true
        } else {
            visibility = choice
        }
    }

    func publicConfirmed() {
        isConfirmingPublic = false
        visibility = .public
    }

    func coverTapped(_ id: PhotoID) { coverID = id }

    func removePhoto(_ id: PhotoID) {
        photos.removeAll { $0.id == id }
        if coverID == id { coverID = photos.first?.id }
    }

    /// Same meaning as SwiftUI's `onMove`, written without SwiftUI.
    func movePhotos(from source: IndexSet, to destination: Int) {
        let moving = source.sorted().map { photos[$0] }
        let before = source.filter { $0 < destination }.count
        for index in source.sorted(by: >) { photos.remove(at: index) }
        photos.insert(contentsOf: moving, at: min(max(0, destination - before), photos.count))
    }

    /// Saves the words, photos, tags and audience. The Spots and the times are never touched.
    func saveTapped() async {
        guard canSave, var updated = run else { return }
        isSaving = true
        defer { isSaving = false }
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.caption = trimmedCaption.isEmpty ? nil : trimmedCaption
        updated.photos = photos
        updated.coverPhotoID = coverID
        updated.tags = ComposerViewModel.tagIDs.filter(tags.contains)
        updated.visibility = visibility
        updated.audience = session.currentUser?.isPrivate == true ? .friends : visibility
        libraryStore.updateRun(updated, times: libraryStore.library.runTimes[updated.id])
        await libraryStore.flush()
        run = updated
        router.dismissSheet()
    }

    func deleteTapped() { isConfirmingDelete = true }

    func deleteConfirmed() async {
        isConfirmingDelete = false
        libraryStore.removeRun(runID)
        await libraryStore.flush()
        router.dismissSheet()
    }

    func cancelTapped() { router.dismissSheet() }
}
