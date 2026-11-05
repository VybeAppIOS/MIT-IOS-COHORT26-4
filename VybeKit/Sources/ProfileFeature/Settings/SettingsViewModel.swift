import Core
import Foundation
import Models

/// One row of the Settings list, ready to draw: words, an SF Symbol and where it goes.
struct SettingsRow: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let route: Route
}

/// A titled group of rows.
struct SettingsSection: Identifiable, Equatable {
    let id: String
    let title: String
    let rows: [SettingsRow]
}

/// PR2, Settings (root). A fixed list, not a loaded one: every row opens a settings page through the router.
/// The Admin pages are reachable only with `-debugRoute` in DEBUG builds (decision of 5 Nov), so there is no row here.
@MainActor @Observable
final class SettingsViewModel {
    /// The "Reset onboarding" confirmation is up.
    var isConfirmingReset = false

    private let session: SessionStore
    private let router: Router

    /// Cheap: nothing loads here (ADR 005).
    init(session: SessionStore, router: Router) {
        self.session = session
        self.router = router
    }

    var title: String { String(localized: "profile.settings.title", bundle: #bundle) }
    var resetTitle: String { String(localized: "profile.settings.reset", bundle: #bundle) }
    var resetSubtitle: String { String(localized: "profile.settings.reset.subtitle", bundle: #bundle) }
    var resetConfirmTitle: String { String(localized: "profile.settings.reset.confirm.title", bundle: #bundle) }
    var resetConfirmMessage: String { String(localized: "profile.settings.reset.confirm.message", bundle: #bundle) }
    var resetConfirmButton: String { String(localized: "profile.settings.reset.confirm.button", bundle: #bundle) }
    var startAgainTitle: String { String(localized: "profile.settings.section.startAgain", bundle: #bundle) }

    let sections: [SettingsSection] = [
        SettingsSection(
            id: "account", title: String(localized: "profile.settings.section.account", bundle: #bundle),
            rows: [
                SettingsRowMaker.row("account", "profile.settings.row.account", "person.crop.circle",
                                     .settingsPage(.account)),
                SettingsRowMaker.row("privacy", "profile.settings.row.privacy", "lock", .settingsPage(.privacy)),
                SettingsRowMaker.row("blocked", "profile.settings.row.blocked", "hand.raised", .settingsPage(.blocked)),
                SettingsRowMaker.row("notifications", "profile.settings.row.notifications", "bell",
                                     .settingsPage(.notifications))
            ]),
        SettingsSection(
            id: "app", title: String(localized: "profile.settings.section.app", bundle: #bundle),
            rows: [
                SettingsRowMaker.row("help", "profile.settings.row.help", "questionmark.circle", .settingsPage(.help)),
                SettingsRowMaker.row("suggestions", "profile.settings.row.suggestions", "mappin.and.ellipse",
                         .settingsPage(.placeSuggestions)),
                SettingsRowMaker.row("about", "profile.settings.row.about", "info.circle", .settingsPage(.about))
            ])
    ]

    // MARK: What the person does

    func rowTapped(_ row: SettingsRow) { router.open(row.route) }

    func resetTapped() { isConfirmingReset = true }

    /// Back to the Welcome screen with an empty draft; every stack, sheet and cover closes.
    func resetConfirmed() {
        isConfirmingReset = false
        session.resetOnboarding()
        router.reset()
    }

    private static func row(_ id: String, _ key: String.LocalizationValue, _ symbol: String, _ route: Route)
        -> SettingsRow {
        SettingsRow(id: id, title: String(localized: key, bundle: #bundle), systemImage: symbol, route: route)
    }
}

/// Short name for building rows inside the stored property above.
private typealias SettingsRowMaker = SettingsViewModel
