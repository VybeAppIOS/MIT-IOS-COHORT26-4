import Core
import Foundation
import Models

/// One Place suggestion, ready to draw: what it is, where it stands, and the team's note.
struct SuggestionRowData: Identifiable, Equatable {
    let id: String
    let name: String
    let statusText: String
    let statusSymbol: String
    let status: PlaceSuggestionStatus
    let note: String?
}

/// ST6, My Place suggestions: the Places this person suggested, with pending / approved / rejected and the team's note.
@MainActor @Observable
final class MySuggestionsViewModel {
    private(set) var state: LoadState<[SuggestionRowData]> = .loading

    private let admin: any AdminRepository
    private let session: SessionStore
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005).
    init(admin: any AdminRepository, session: SessionStore) {
        self.admin = admin
        self.session = session
    }

    var title: String { String(localized: "profile.suggestions.title", bundle: #bundle) }
    var emptyMessage: String { String(localized: "profile.suggestions.empty", bundle: #bundle) }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    private func fetch() async {
        do {
            let mine = try await admin.placeSuggestions().filter { $0.submitterID == session.currentUser?.id }
            let rows = mine.sorted { $0.createdAt > $1.createdAt }.map(Self.row)
            state = rows.isEmpty ? .empty : .loaded(rows)
            hasLoaded = true
        } catch is CancellationError {
            return   // leaving the screen is not an error (ADR 005)
        } catch {
            if case .loaded(let rows, _) = state {
                state = .loaded(rows, isStale: true)   // a failed refresh keeps what is on screen
            } else {
                state = .failed(AppError(error))
            }
        }
    }

    static func row(_ suggestion: PlaceSuggestion) -> SuggestionRowData {
        let (text, symbol): (String, String) = switch suggestion.status {
        case .pending: (String(localized: "profile.suggestions.pending", bundle: #bundle), "clock")
        case .approved: (String(localized: "profile.suggestions.approved", bundle: #bundle), "checkmark.circle.fill")
        case .rejected: (String(localized: "profile.suggestions.rejected", bundle: #bundle), "xmark.circle")
        }
        return SuggestionRowData(id: suggestion.id.rawValue, name: suggestion.name, statusText: text,
                                 statusSymbol: symbol, status: suggestion.status, note: suggestion.reviewNote)
    }
}
