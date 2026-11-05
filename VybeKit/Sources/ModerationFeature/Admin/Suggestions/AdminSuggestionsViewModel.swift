import Core
import Design
import Foundation
import Models

/// One pending suggestion in the list.
struct AdminSuggestionRow: Identifiable, Equatable {
    let id: PlaceSuggestionID
    let name: String
    /// "Café · 15 hr ago"
    let detailText: String
    let note: String?
}

/// The review form for one suggestion: the Place it would become (every field editable) and a reject note.
/// The team types the real details; nothing is filled in for them except the suggestion's own name and category.
struct AdminReview: Equatable {
    let id: PlaceSuggestionID
    var name: String
    var category: PlaceCategory
    var area = ""
    var address = ""
    var costLower = 0
    var costUpper = 0
    var rejectNote = ""
}

/// AD2, Place suggestions. Team accounts only. Pending suggestions; approve into a Place (editable) or reject with a
/// note. "Residential address" is a one-tap reject: homes and hostels are never accepted (`docs/RISKS.md`).
@MainActor @Observable
final class AdminSuggestionsViewModel {
    static let city = "Pune"

    private(set) var state: LoadState<[AdminSuggestionRow]> = .loading
    /// The review sheet is up, editing `draft`.
    var isReviewing = false
    var draft = AdminReview(id: "", name: "", category: .cafe)
    private(set) var actionFailed = false
    private(set) var isWorking = false

    private var pending: [PlaceSuggestion] = []
    private let admin: any AdminRepository
    private let session: SessionStore
    private let now: @Sendable () -> Date
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(admin: any AdminRepository, session: SessionStore, now: @escaping @Sendable () -> Date) {
        self.admin = admin
        self.session = session
        self.now = now
    }

    var title: String { String(localized: "admin.suggestions.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "admin.suggestions.empty", bundle: #bundle) }
    var teamOnlyMessage: String { String(localized: "admin.teamOnly", bundle: #bundle) }
    var actionError: String { String(localized: "admin.actionFailed", bundle: #bundle) }
    var isAllowed: Bool { session.isTeamAccount }

    let categories: [AdminCategoryOption] = PlaceCategory.allCases.filter { $0 != .unknown }.map {
        AdminCategoryOption(category: $0, title: ComponentStrings.categoryName($0))
    }

    var canApprove: Bool {
        guard isReviewing, !isWorking else { return false }
        let filled = [draft.name, draft.area, draft.address]
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return filled && draft.costLower >= 0 && draft.costLower <= draft.costUpper
    }

    var canReject: Bool {
        guard isReviewing, !isWorking else { return false }
        return !draft.rejectNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        guard isAllowed else { return }
        do {
            pending = try await admin.placeSuggestions().filter { $0.status == .pending }
            let rows = pending.map(row)
            state = rows.isEmpty ? .empty : .loaded(rows)
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            if case .loaded(let rows, _) = state {
                state = .loaded(rows, isStale: true)
            } else {
                state = .failed(AppError(error))
            }
        }
    }

    private func row(_ suggestion: PlaceSuggestion) -> AdminSuggestionRow {
        let age = Duration.seconds(Int(max(0, now().timeIntervalSince(suggestion.createdAt))))
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 1))
        return AdminSuggestionRow(
            id: suggestion.id, name: suggestion.name,
            detailText: String(format: String(localized: "admin.suggestions.detail", bundle: #bundle),
                               ComponentStrings.categoryName(suggestion.category), age),
            note: suggestion.note)
    }

    // MARK: What the person does

    func rowTapped(_ row: AdminSuggestionRow) {
        guard let suggestion = pending.first(where: { $0.id == row.id }) else { return }
        actionFailed = false
        draft = AdminReview(id: suggestion.id, name: suggestion.name, category: suggestion.category)
        isReviewing = true
    }

    func approveTapped() async {
        let review = draft
        guard canApprove, let suggestion = pending.first(where: { $0.id == review.id }) else { return }
        let place = Place(
            id: PlaceID("place-\(suggestion.id.rawValue)"), name: review.name.trimmingCharacters(in: .whitespaces),
            category: review.category, city: Self.city, area: review.area.trimmingCharacters(in: .whitespaces),
            address: review.address.trimmingCharacters(in: .whitespaces), coordinate: suggestion.coordinate,
            costPerPerson: RupeeRange(lower: review.costLower, upper: review.costUpper), verifiedAt: now())
        await act { try await self.admin.approve(suggestion.id, as: place) }
    }

    func rejectTapped() async {
        let review = draft
        guard canReject else { return }
        let note = review.rejectNote.trimmingCharacters(in: .whitespacesAndNewlines)
        await act { try await self.admin.reject(review.id, note: note) }
    }

    /// One tap: rejects as a home, hostel or other residential address.
    func rejectResidentialTapped() async {
        let review = draft
        guard isReviewing, !isWorking else { return }
        let note = String(localized: "admin.suggestions.residential.note", bundle: #bundle)
        await act { try await self.admin.reject(review.id, note: note) }
    }

    func closeReviewTapped() { isReviewing = false }

    private func act(_ work: @MainActor () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await work()
            isReviewing = false
            actionFailed = false
            await fetch()
        } catch is CancellationError {
            return
        } catch {
            actionFailed = true
        }
    }
}

/// One category in the review form's picker.
struct AdminCategoryOption: Identifiable, Equatable {
    let category: PlaceCategory
    let title: String

    var id: String { category.rawValue }
}
