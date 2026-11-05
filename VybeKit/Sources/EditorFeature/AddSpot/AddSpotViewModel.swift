import Components
import Core
import Foundation
import Models

/// One category filter chip ("All" has no category).
struct CategoryChip: Identifiable, Equatable {
    let category: PlaceCategory?
    let title: String

    var id: String { category?.rawValue ?? "all" }
}

/// One Place in the list, ready to draw.
struct AddSpotRow: Identifiable, Equatable {
    let place: Place
    let categoryText: String
    let thumbnailURL: URL?

    var id: PlaceID { place.id }
}

/// E2, Add Spot (a sheet from the Hangout editor). The team's Places in the area, filtered by category chips (no
/// free-text search until the mentors answer the picker question). Tapping one adds it as a new Spot with a new,
/// stable `SpotID`, then the sheet closes. "Can't find it?" asks for a Place suggestion (E3).
@MainActor @Observable
final class AddSpotViewModel {
    private(set) var state: LoadState<[AddSpotRow]> = .loading
    private(set) var selectedCategory: PlaceCategory?

    private let places: any PlaceRepository
    private let photos: any PhotoStore
    private let area: String
    private let makeID: @Sendable () -> String
    private let onAdd: (Spot, Place) -> Void
    private let onSuggest: () -> Void
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005). `onAdd` gives the new Spot and its Place to the editor.
    init(
        places: any PlaceRepository, photos: any PhotoStore, area: String, makeID: @escaping @Sendable () -> String,
        onAdd: @escaping (Spot, Place) -> Void, onSuggest: @escaping () -> Void
    ) {
        self.places = places
        self.photos = photos
        self.area = area
        self.makeID = makeID
        self.onAdd = onAdd
        self.onSuggest = onSuggest
    }

    var title: String { String(localized: "editor.addSpot.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "editor.addSpot.empty", bundle: #bundle) }
    var filteredEmpty: String { String(localized: "editor.addSpot.filteredEmpty", bundle: #bundle) }
    var suggestTitle: String { String(localized: "editor.addSpot.suggest", bundle: #bundle) }
    var allTitle: String { String(localized: "editor.addSpot.all", bundle: #bundle) }

    /// "All" first, then every category that has at least one Place, in the order of `PlaceCategory`.
    var chips: [CategoryChip] {
        guard case .loaded(let rows, _) = state else { return [] }
        let present = Set(rows.map(\.place.category))
        return [CategoryChip(category: nil, title: allTitle)]
            + PlaceCategory.allCases.filter(present.contains).map {
                CategoryChip(category: $0, title: ComponentStrings.categoryName($0))
            }
    }

    /// The rows for the chosen chip.
    var visibleRows: [AddSpotRow] {
        guard case .loaded(let rows, _) = state else { return [] }
        guard let selectedCategory else { return rows }
        return rows.filter { $0.place.category == selectedCategory }
    }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        do {
            let found = try await places.places(in: area).filter { $0.status != .hidden }
            let rows = found.sorted { $0.name < $1.name }.map { place in
                AddSpotRow(place: place, categoryText: ComponentStrings.categoryName(place.category),
                           thumbnailURL: place.photos.first.flatMap { photos.url(for: $0) })
            }
            state = rows.isEmpty ? .empty : .loaded(rows)
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let rows, _) = state {
                state = .loaded(rows, isStale: true)
            } else {
                state = .failed(AppError(error))
            }
        }
    }

    // MARK: What the person does

    func select(_ chip: CategoryChip) { selectedCategory = chip.category }

    func isSelected(_ chip: CategoryChip) -> Bool { chip.category == selectedCategory }

    /// A new Spot for this Place, with a new ID that never changes afterwards.
    func add(_ place: Place) {
        onAdd(Spot(id: SpotID("spot-\(makeID())"), placeID: place.id), place)
    }

    func suggestTapped() { onSuggest() }
}
