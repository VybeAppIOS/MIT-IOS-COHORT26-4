import Core
import Foundation
import Models

/// One photo credit: who took the photos of which Place.
struct PhotoCreditRow: Identifiable, Equatable {
    let id: String
    let placeName: String
    let credit: String
}

/// ST7, About and credits: the app version, the photo credits read from the content (`Photo.credit`) and the licences.
@MainActor @Observable
final class AboutViewModel {
    private(set) var state: LoadState<[PhotoCreditRow]> = .loading

    private let hangouts: any HangoutRepository
    private let places: any PlaceRepository
    private let versionText: String
    private var hasLoaded = false

    /// Cheap: nothing loads here (ADR 005). `version` is injected so tests do not depend on the app bundle.
    init(hangouts: any HangoutRepository, places: any PlaceRepository, version: String = AboutViewModel.appVersion) {
        self.hangouts = hangouts
        self.places = places
        self.versionText = version
    }

    /// "1.0 (12)" from the app's Info.plist.
    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var title: String { String(localized: "profile.about.title", bundle: #bundle) }
    var tagline: String { String(localized: "profile.about.tagline", bundle: #bundle) }
    var versionLabel: String { String(localized: "profile.about.version", bundle: #bundle) }
    var version: String { versionText }
    var creditsHeader: String { String(localized: "profile.about.credits", bundle: #bundle) }
    var creditsEmpty: String { String(localized: "profile.about.credits.empty", bundle: #bundle) }
    var licencesHeader: String { String(localized: "profile.about.licences", bundle: #bundle) }
    var licencesBody: String { String(localized: "profile.about.licences.body", bundle: #bundle) }

    func load() async {
        guard !hasLoaded else { return }
        await fetch()
    }

    func reload() async { await fetch() }

    /// Every Place used by a published Hangout, once, with the credit of each photo (several credits are joined).
    private func fetch() async {
        do {
            var seen: [PlaceID: PhotoCreditRow] = [:]
            for hangout in try await hangouts.hangouts(near: nil, filters: HangoutFilters()) {
                for place in try await places.spots(for: hangout) where seen[place.id] == nil {
                    let credits = Array(Set(place.photos.compactMap(\.credit))).sorted()
                    guard !credits.isEmpty else { continue }
                    seen[place.id] = PhotoCreditRow(id: place.id.rawValue, placeName: place.name,
                                                    credit: credits.joined(separator: ", "))
                }
            }
            let rows = seen.values.sorted { $0.placeName < $1.placeName }
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
}
