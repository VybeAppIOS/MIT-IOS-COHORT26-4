import Components
import Core
import Foundation
import Models

/// How Suggest a Place was opened: as the router's sheet (Search, the editor) or pushed inside a sheet.
enum SuggestPlacePresentation: Equatable {
    case sheet
    case pushed
}

/// One category in the picker.
struct CategoryOption: Identifiable, Equatable {
    let category: PlaceCategory
    let title: String

    var id: String { category.rawValue }
}

/// E3, Suggest a Place. Name, the spot on a map (a centre pin), a category, a note, and a photo taken there (required,
/// made safe by `PhotoProcessor`). The team checks every suggestion; homes and hostels are never accepted.
@MainActor @Observable
final class SuggestPlaceViewModel {
    enum Phase: Equatable {
        case editing
        case sending
        case failed
        case sent
    }

    static let nameRange = 2...60
    static let noteLimit = 300
    /// Where the map starts: the middle of Kothrud, the first area.
    static let startCentre = Coordinate(latitude: 18.5074, longitude: 73.8077)

    var name = ""
    var note = ""
    var category: PlaceCategory = .cafe
    /// The point under the map's centre pin; the View updates it when the map stops moving.
    var centre = SuggestPlaceViewModel.startCentre
    private(set) var photo: ProcessedPhoto?
    private(set) var photoFailed = false
    private(set) var phase: Phase = .editing
    /// Name errors appear only after the first try to send, so the form does not start red.
    private(set) var triedToSend = false

    private let presentation: SuggestPlacePresentation
    private let session: SessionStore
    private let router: Router
    private let processPhoto: @Sendable (Data) async throws -> ProcessedPhoto
    private let submit: @MainActor (PlaceSuggestion) async throws -> Void
    private let now: @Sendable () -> Date
    private let makeID: @Sendable () -> String

    /// Cheap: nothing loads here (ADR 005). `processPhoto` strips the photo's metadata (tests pass a fake);
    /// `submit` sends the suggestion (see the report: there is no repository call for it yet).
    init(
        presentation: SuggestPlacePresentation, session: SessionStore, router: Router,
        processPhoto: @escaping @Sendable (Data) async throws -> ProcessedPhoto = {
            try await PhotoProcessor().process($0)
        },
        submit: @escaping @MainActor (PlaceSuggestion) async throws -> Void,
        now: @escaping @Sendable () -> Date, makeID: @escaping @Sendable () -> String
    ) {
        self.presentation = presentation
        self.session = session
        self.router = router
        self.processPhoto = processPhoto
        self.submit = submit
        self.now = now
        self.makeID = makeID
    }

    // MARK: Words

    var title: String { String(localized: "editor.suggest.title", bundle: #bundle) }
    var promise: String { String(localized: "editor.suggest.promise", bundle: #bundle) }
    var nameLabel: String { String(localized: "editor.suggest.name", bundle: #bundle) }
    var mapHint: String { String(localized: "editor.suggest.map", bundle: #bundle) }
    var categoryLabel: String { String(localized: "editor.suggest.category", bundle: #bundle) }
    var noteLabel: String { String(localized: "editor.suggest.note", bundle: #bundle) }
    var photoLabel: String { String(localized: "editor.suggest.photo", bundle: #bundle) }
    var photoReady: String { String(localized: "editor.suggest.photo.ready", bundle: #bundle) }
    var photoError: String { String(localized: "editor.suggest.photo.error", bundle: #bundle) }
    var sendTitle: String { String(localized: "editor.suggest.send", bundle: #bundle) }
    var errorMessage: String { String(localized: "editor.suggest.error", bundle: #bundle) }
    var sentTitle: String { String(localized: "editor.suggest.sent.title", bundle: #bundle) }
    var sentBody: String { String(localized: "editor.suggest.sent.body", bundle: #bundle) }
    var doneTitle: String { String(localized: "editor.suggest.done", bundle: #bundle) }
    var showsCancel: Bool { presentation == .sheet }

    let categories: [CategoryOption] = PlaceCategory.allCases.filter { $0 != .unknown }.map {
        CategoryOption(category: $0, title: ComponentStrings.categoryName($0))
    }

    // MARK: Validation

    var nameError: String? {
        guard triedToSend else { return nil }
        let count = name.trimmingCharacters(in: .whitespacesAndNewlines).count
        return Self.nameRange.contains(count) ? nil : String(localized: "editor.suggest.error.name", bundle: #bundle)
    }

    var photoMissing: String? {
        triedToSend && photo == nil ? String(localized: "editor.suggest.error.photo", bundle: #bundle) : nil
    }

    var noteError: String? {
        note.count > Self.noteLimit ? String(localized: "editor.suggest.error.note", bundle: #bundle) : nil
    }

    var isValid: Bool {
        Self.nameRange.contains(name.trimmingCharacters(in: .whitespacesAndNewlines).count) && photo != nil
            && note.count <= Self.noteLimit
    }

    var isSending: Bool { phase == .sending }
    var hasFailed: Bool { phase == .failed }
    var isSent: Bool { phase == .sent }

    // MARK: What the person does

    func photoPicked(_ data: Data) async {
        do {
            photo = try await processPhoto(data)
            photoFailed = false
        } catch {
            photoFailed = true
        }
    }

    func sendTapped() async {
        triedToSend = true
        guard isValid, phase != .sending else { return }
        phase = .sending
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestion = PlaceSuggestion(
            id: PlaceSuggestionID("suggestion-\(makeID())"),
            submitterID: session.currentUser?.id ?? UserID("user-local"),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines), coordinate: centre, category: category,
            note: trimmedNote.isEmpty ? nil : trimmedNote, createdAt: now())
        do {
            try await submit(suggestion)
            phase = .sent
        } catch is CancellationError {
            phase = .editing   // leaving the screen is not an error (ADR 005)
        } catch {
            phase = .failed
        }
    }

    func closeTapped() {
        switch presentation {
        case .sheet: router.dismissSheet()
        case .pushed: router.pop()
        }
    }
}
