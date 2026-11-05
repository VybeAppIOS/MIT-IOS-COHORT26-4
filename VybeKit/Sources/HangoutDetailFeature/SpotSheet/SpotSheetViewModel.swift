import Components
import Core
import Design
import Foundation
import Models

/// Everything the Spot sheet shows, already as display text (never a raw model).
struct SpotSheetContent: Equatable, Sendable {
    let name: String
    let categoryText: String
    let address: String
    /// "₹100–250"
    let costText: String
    /// "Open until 10 pm", "Opens at 9 am", "Closed today", or the Place's hours note.
    let hoursText: String
    let photos: [GalleryPhoto]
    let isClosedByAuthorities: Bool
    /// The trek safety note; nil when this Place is not a trek.
    let trekNote: String?
    /// Apple's ID for this Place; nil hides the Apple Maps details button.
    let applePlaceID: String?
    /// Up to 3 Hangouts that include this Place, Picks first.
    let hangouts: [HangoutCardData]
}

/// HD2: one Place, in a sheet opened from Hangout detail, Search and the live screen (`Sheet.spot`).
@MainActor @Observable
final class SpotSheetViewModel {
    static let maxHangouts = 3

    private(set) var state: LoadState<SpotSheetContent> = .loading
    let id: PlaceID

    private let places: any PlaceRepository
    private let hangouts: any HangoutRepository
    private let photos: any PhotoStore
    private let library: LibraryStore
    private let router: Router
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private var hasLoaded = false

    /// Cheap: no loading here (ADR 005). `now` is injected, never `Date()`; `calendar` is Pune time.
    init(
        id: PlaceID, places: any PlaceRepository, hangouts: any HangoutRepository, photos: any PhotoStore,
        library: LibraryStore, router: Router, now: @escaping @Sendable () -> Date,
        calendar: Calendar = OpeningHours.pune
    ) {
        self.id = id
        self.places = places
        self.hangouts = hangouts
        self.photos = photos
        self.library = library
        self.router = router
        self.now = now
        self.calendar = calendar
    }

    func load() async {
        guard !hasLoaded else { return }        // .task runs again whenever the sheet reappears
        await fetch()
    }

    func reload() async { await fetch() }       // pull to refresh and the Retry button

    private func fetch() async {
        do {
            let place = try await places.place(id: id)
            let cards = await hangoutCards(with: place.id)
            state = .loaded(content(place, hangouts: cards))
            hasLoaded = true
        } catch is CancellationError {
            return                              // leaving the screen is not an error (ADR 005)
        } catch {
            let appError = AppError(error)
            if case .loaded(let content, _) = state {
                state = .loaded(content, isStale: true)   // a failed refresh keeps what is on screen
            } else if appError == .notFound {
                state = .empty                            // "This Spot is no longer available"
            } else {
                state = .failed(appError)                 // only a first load can fail
            }
        }
    }

    // MARK: Actions

    /// Closes the sheet, then opens the Hangout on the screen underneath.
    func hangoutTapped(_ hangoutID: HangoutID) {
        router.dismissSheet()
        router.open(.hangout(hangoutID))
    }

    /// Report is pushed inside this sheet (IA: R1 is a push when opened from HD2).
    func reportTapped() { router.open(.report(.place(id))) }

    // MARK: Building the content

    /// Up to 3 Hangouts with this Place, Picks first. The list is extra: if it fails, the sheet still shows the
    /// Place. There is no "Hangouts with this Place" query yet, so this filters the whole list (fine on local
    /// data; the backend should get its own query).
    private func hangoutCards(with placeID: PlaceID) async -> [HangoutCardData] {
        let all: [Hangout]
        do {
            all = try await hangouts.hangouts(near: nil, filters: HangoutFilters())
        } catch {
            Log.hangout.error("Spot sheet: Hangouts list failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
        let matching = all.filter { $0.spots.contains { $0.placeID == placeID } }
        let picksFirst = matching.filter(\.isPick) + matching.filter { !$0.isPick }
        var cards: [HangoutCardData] = []
        for hangout in picksFirst.prefix(Self.maxHangouts) {
            let coverURL = await coverURL(of: hangout)
            cards.append(HangoutCardData(hangout, coverURL: coverURL, isSaved: library.isSaved(hangout.id)))
        }
        return cards
    }

    /// A card's cover: the Hangout's first Spot's first photo (the `HangoutCardData` rule).
    private func coverURL(of hangout: Hangout) async -> URL? {
        guard let first = hangout.spots.first,
              let place = try? await places.place(id: first.placeID) else { return nil }
        return place.photos.first.flatMap(photos.url(for:))
    }

    private func content(_ place: Place, hangouts cards: [HangoutCardData]) -> SpotSheetContent {
        let isTrek = place.category == .trek || place.trekInfo != nil
        return SpotSheetContent(
            name: place.name, categoryText: ComponentStrings.categoryName(place.category), address: place.address,
            costText: place.costPerPerson.formattedPerPerson,
            hoursText: hoursText(OpeningHours.status(of: place.hours, at: now(), calendar: calendar),
                                 note: place.hoursNote),
            photos: place.photos.map {
                GalleryPhoto(id: $0.id.rawValue, url: photos.url(for: $0), credit: $0.credit, description: place.name)
            },
            isClosedByAuthorities: place.status == .closedByAuthorities,
            trekNote: isTrek ? (place.trekInfo?.safetyNote ?? SpotSheetText.trekSafety) : nil,
            applePlaceID: place.applePlaceID, hangouts: cards)
    }

    private func hoursText(_ status: OpeningStatus, note: String?) -> String {
        switch status {
        case .openUntil(let date): SpotSheetText.openUntil(timeText(date))
        case .opensAt(let date): SpotSheetText.opensAt(timeText(date))
        case .closedToday: SpotSheetText.closedToday
        case .notListed: note ?? SpotSheetText.hoursNotListed
        }
    }

    /// "10:00 PM" in Pune time, in the person's own time format.
    private func timeText(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: calendar.timeZone))
    }
}

/// The Spot sheet's text, read from HangoutDetailFeature's own catalog (`bundle: #bundle`, task X-3).
enum SpotSheetText {
    static var notFound: String { String(localized: "hangoutDetail.spot.notFound", bundle: #bundle) }
    static var closedToday: String { String(localized: "hangoutDetail.spot.closedToday", bundle: #bundle) }
    static var hoursNotListed: String { String(localized: "hangoutDetail.spot.hoursNotListed", bundle: #bundle) }
    static var trekSafety: String { String(localized: "hangoutDetail.spot.trekSafety", bundle: #bundle) }
    static var appleDetails: String { String(localized: "hangoutDetail.spot.appleDetails", bundle: #bundle) }
    static var appleDetailsFailed: String {
        String(localized: "hangoutDetail.spot.appleDetailsFailed", bundle: #bundle)
    }
    static var hangoutsHeader: String { String(localized: "hangoutDetail.spot.hangoutsHeader", bundle: #bundle) }
    static var more: String { String(localized: "hangoutDetail.spot.more", bundle: #bundle) }
    static var reportPlace: String { String(localized: "hangoutDetail.spot.reportPlace", bundle: #bundle) }

    /// "Open until 10:00 PM"
    static func openUntil(_ time: String) -> String {
        String(localized: "hangoutDetail.spot.openUntil \(time)", bundle: #bundle)
    }

    /// "Opens at 9:00 AM"
    static func opensAt(_ time: String) -> String {
        String(localized: "hangoutDetail.spot.opensAt \(time)", bundle: #bundle)
    }
}
