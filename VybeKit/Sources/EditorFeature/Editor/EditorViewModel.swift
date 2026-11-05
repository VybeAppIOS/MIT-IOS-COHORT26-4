import Components
import Core
import Foundation
import Models

/// One chip of a fixed list (tags, best times): the stored word and the words shown.
struct EditorChip: Identifiable, Equatable {
    let id: String
    let title: String
}

/// E1, Hangout editor (the editor cover). A new Hangout, one of my Drafts, or a Remix. Every change is saved as a Draft
/// straight away (autosave), so nothing is lost if the app closes. Validation uses `HangoutRules`.
@MainActor @Observable
final class EditorViewModel {
    static let titleRange = 3...60
    static let summaryLimit = 200
    /// Where the Add Spot list looks until the person's area can be read (see the report).
    static let defaultArea = "Kothrud"

    /// The first load: the Draft being edited, once ready.
    private(set) var state: LoadState<HangoutID> = .loading

    var title = ""
    var summary = ""
    private(set) var spots: [Spot] = []
    private(set) var placesByID: [PlaceID: Place] = [:]
    var budgetLower = 0
    var budgetUpper = 0
    /// The person's own estimate; nil means "the sum of the Spots' minutes".
    private(set) var minutesOverride: Int?
    private(set) var tags: Set<String> = []
    private(set) var bestTimes: Set<String> = []
    var isAddingSpot = false
    var isConfirmingClose = false
    private(set) var hasEdits = false

    private var draftID = HangoutID("")
    private var authorID = UserID("")
    private var createdAt = Date.distantPast
    private(set) var remixedFromID: HangoutID?
    private(set) var remixedFromPlaceIDs: [PlaceID]?
    private(set) var remixAuthor: String?
    /// The Draft as it was when the editor opened (to put back on Discard).
    private var openedDraft: Hangout?

    let start: EditorStart
    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let profiles: any ProfileRepository
    private let photos: any PhotoStore
    private let libraryStore: LibraryStore
    private let session: SessionStore
    private let router: Router
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> String
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(
        start: EditorStart, hangouts: any HangoutRepository, places: any PlaceRepository,
        profiles: any ProfileRepository, photos: any PhotoStore, libraryStore: LibraryStore, session: SessionStore,
        router: Router, now: @escaping @Sendable () -> Date, makeID: @escaping @Sendable () -> String
    ) {
        self.start = start
        self.hangouts = hangouts
        self.places = places
        self.profiles = profiles
        self.photos = photos
        self.libraryStore = libraryStore
        self.session = session
        self.router = router
        self.now = now
        self.makeID = makeID
    }

    // MARK: Loading

    func load() async {
        guard !hasLoaded else { return }
        do {
            await libraryStore.ensureLoaded()
            switch start {
            case .new: startNew()
            case .draft(let id): try openDraft(id)
            case .remix(let id): try await startRemix(of: id)
            }
            let draft = currentHangout()
            let found = try await places.spots(for: draft)
            placesByID = Dictionary(found.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            state = .loaded(draftID)
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            state = .failed(AppError(error))
        }
    }

    func reload() async {
        hasLoaded = false
        state = .loading
        await load()
    }

    private func startNew() {
        draftID = HangoutID("hangout-draft-\(makeID())")
        authorID = session.currentUser?.id ?? UserID("user-local")
        createdAt = now()
    }

    private func openDraft(_ id: HangoutID) throws {
        guard let draft = libraryStore.drafts.first(where: { $0.id == id }) else { throw AppError.notFound }
        openedDraft = draft
        fill(from: draft)
    }

    /// A Remix is a new Draft that keeps the original's Spots, credits its author and remembers its Places (70% rule).
    private func startRemix(of id: HangoutID) async throws {
        let original = try await hangouts.hangout(id: id)
        fill(from: original)
        draftID = HangoutID("hangout-draft-\(makeID())")
        authorID = session.currentUser?.id ?? UserID("user-local")
        createdAt = now()
        remixedFromID = original.id
        remixedFromPlaceIDs = original.spots.map(\.placeID)
        remixAuthor = (try? await profiles.profile(id: original.authorID)).map { "@\($0.username)" }
        hasEdits = true   // a Remix is worth keeping even before the first change
        await autosave()
    }

    private func fill(from hangout: Hangout) {
        draftID = hangout.id
        authorID = hangout.authorID
        createdAt = hangout.createdAt
        title = hangout.title
        summary = hangout.summary
        spots = hangout.spots
        budgetLower = hangout.budgetPerPerson.lower
        budgetUpper = hangout.budgetPerPerson.upper
        let sum = hangout.spots.compactMap(\.minutes).reduce(0, +)
        minutesOverride = hangout.estimatedMinutes == sum ? nil : hangout.estimatedMinutes
        tags = Set(hangout.tags)
        bestTimes = Set(hangout.bestTimes)
        remixedFromID = hangout.remixedFromID
        remixedFromPlaceIDs = hangout.remixedFromPlaceIDs
    }

    // MARK: Words and view-ready values

    let tagOptions: [EditorChip] = ["good-for-groups", "budget-friendly", "rainy-day", "date-idea", "solo-friendly"]
        .map { EditorChip(id: $0, title: EditorViewModel.word("editor.tag.", $0)) }
    let timeOptions: [EditorChip] = ["morning", "afternoon", "evening", "night"]
        .map { EditorChip(id: $0, title: EditorViewModel.word("editor.time.", $0)) }

    /// A plain catalog key built from a stored word (not an interpolated format key).
    private static func word(_ prefix: String, _ key: String) -> String {
        String(localized: String.LocalizationValue(stringLiteral: prefix + key), bundle: #bundle)
    }

    // MARK: Validation (the rules are in HangoutRules)

    var titleError: String? {
        Self.titleRange.contains(title.trimmingCharacters(in: .whitespacesAndNewlines).count)
            ? nil : String(localized: "editor.error.title", bundle: #bundle)
    }

    var summaryError: String? {
        summary.count > Self.summaryLimit ? String(localized: "editor.error.summary", bundle: #bundle) : nil
    }

    var spotCountError: String? {
        guard !HangoutRules.isValidSpotCount(spots.count) else { return nil }
        return spots.count < HangoutRules.minimumSpots
            ? String(localized: "editor.error.fewSpots", bundle: #bundle)
            : String(localized: "editor.error.manySpots", bundle: #bundle)
    }

    /// Allowed, but worth knowing.
    var duplicateWarning: String? {
        HangoutRules.hasDuplicatePlace(spots) ? String(localized: "editor.warning.duplicate", bundle: #bundle) : nil
    }

    var budgetError: String? {
        budgetLower >= 0 && budgetLower <= budgetUpper ? nil : String(localized: "editor.error.budget", bundle: #bundle)
    }

    var canFinish: Bool {
        titleError == nil && summaryError == nil && spotCountError == nil && budgetError == nil
    }

    var canAddSpot: Bool { spots.count < HangoutRules.maximumSpots }

    // MARK: Remix credit

    /// How many of the original's Places this Remix still has.
    var keptCount: Int {
        guard let original = remixedFromPlaceIDs else { return 0 }
        return Set(original).intersection(spots.map(\.placeID)).count
    }

    /// The 70% rule: whether this Remix still counts towards the original.
    var keepsCredit: Bool {
        guard let original = remixedFromPlaceIDs else { return false }
        return HangoutRules.remixKeepsEnough(original: original, remix: spots.map(\.placeID))
    }

    /// "Remixed from @x · keeps 3 of 4 Places"; nil when this is not a Remix.
    var remixBanner: String? {
        guard let original = remixedFromPlaceIDs else { return nil }
        let author = remixAuthor ?? String(localized: "editor.remix.someone", bundle: #bundle)
        let total = Set(original).count
        let key: String.LocalizationValue = keepsCredit ? "editor.remix.banner" : "editor.remix.banner.noCredit"
        return String(format: String(localized: key, bundle: #bundle), author, keptCount, total)
    }

    // MARK: Editing

    func edited() {
        hasEdits = true
        Task { await autosave() }
    }

    func addSpotTapped() { isAddingSpot = true }

    func addSpot(_ spot: Spot, place: Place) {
        guard canAddSpot else { return }
        spots.append(spot)
        placesByID[place.id] = place
        edited()
    }

    func removeSpots(at offsets: IndexSet) {
        spots = spots.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
        edited()
    }

    /// The same result as SwiftUI's `move(fromOffsets:toOffset:)`, without importing SwiftUI here.
    func moveSpots(from source: IndexSet, to destination: Int) {
        let moving = source.sorted().map { spots[$0] }
        var rest = spots.enumerated().filter { !source.contains($0.offset) }.map(\.element)
        let insertAt = destination - source.filter { $0 < destination }.count
        rest.insert(contentsOf: moving, at: min(max(0, insertAt), rest.count))
        spots = rest
        edited()
    }

    func setMinutes(_ minutes: Int?, for id: SpotID) {
        guard let index = spots.firstIndex(where: { $0.id == id }) else { return }
        spots[index].minutes = minutes.map { max(0, $0) }
        edited()
    }

    func setNote(_ note: String, for id: SpotID) {
        guard let index = spots.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        spots[index].note = trimmed.isEmpty ? nil : note
        edited()
    }

    func setEstimate(_ minutes: Int) {
        minutesOverride = max(0, minutes)
        edited()
    }

    func toggleTag(_ chip: EditorChip) {
        if tags.contains(chip.id) { tags.remove(chip.id) } else { tags.insert(chip.id) }
        edited()
    }

    func toggleBestTime(_ chip: EditorChip) {
        if bestTimes.contains(chip.id) { bestTimes.remove(chip.id) } else { bestTimes.insert(chip.id) }
        edited()
    }

    // MARK: Saving and closing

    /// The Hangout as it stands, as a Draft.
    func currentHangout() -> Hangout {
        Hangout(
            id: draftID, title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines), spots: spots,
            budgetPerPerson: RupeeRange(lower: budgetLower, upper: budgetUpper), estimatedMinutes: estimatedMinutes,
            bestTimes: timeOptions.map(\.id).filter(bestTimes.contains),
            tags: tagOptions.map(\.id).filter(tags.contains),
            authorID: authorID, status: .draft, remixedFromID: remixedFromID, remixedFromPlaceIDs: remixedFromPlaceIDs,
            createdAt: createdAt, updatedAt: now())
    }

    /// Saves the Draft (only once something was entered, so an untouched new Hangout leaves nothing behind).
    func autosave() async {
        guard hasEdits, hasLoaded || remixedFromID != nil else { return }
        await libraryStore.saveDraft(currentHangout())
    }

    /// Done: save, close the editor and show Drafts on the Profile tab.
    func doneTapped() async {
        guard canFinish else { return }
        hasEdits = true
        await autosave()
        router.show(.drafts, in: .profile)
    }

    /// Close: straight away when nothing was entered; otherwise ask (keep the Draft, or discard the changes).
    func closeTapped() {
        if hasEdits { isConfirmingClose = true } else { router.dismissCover() }
    }

    func keepDraftAndClose() async {
        await autosave()
        router.dismissCover()
    }

    /// Discard: a new Hangout or a Remix disappears; an existing Draft goes back to how it was when opened.
    func discardAndClose() async {
        if let openedDraft {
            await libraryStore.saveDraft(openedDraft)
        } else {
            await libraryStore.deleteDraft(draftID)
        }
        router.dismissCover()
    }

    // MARK: Add Spot (E2) and Suggest a Place (E3)

    func makeAddSpotViewModel() -> AddSpotViewModel {
        AddSpotViewModel(
            places: places, photos: photos, area: Self.defaultArea, makeID: makeID,
            onAdd: { [weak self] spot, place in self?.addSpot(spot, place: place) },
            onSuggest: { [weak self] in self?.suggestPlaceTapped() })
    }

    /// From Add Spot: close it and open Suggest a Place as the router's sheet over the editor.
    func suggestPlaceTapped() {
        isAddingSpot = false
        router.present(.suggestPlace)
    }
}
