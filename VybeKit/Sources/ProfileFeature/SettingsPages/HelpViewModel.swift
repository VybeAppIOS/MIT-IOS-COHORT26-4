import Core
import Foundation
import Models

/// ST5, Help and contact. A fixed page: how to get help, the grievance officer (required by India's IT Rules and Apple
/// guideline 1.2), and the Terms and Privacy pages. The support email, the officer and the documents are not decided
/// yet (BK-13, a lawyer question), so the page says so instead of inventing them.
@MainActor @Observable
final class HelpViewModel {
    private let router: Router

    /// Cheap: nothing loads here (ADR 005).
    init(router: Router) {
        self.router = router
    }

    var title: String { String(localized: "profile.help.title", bundle: #bundle) }
    var intro: String { String(localized: "profile.help.intro", bundle: #bundle) }
    var contactHeader: String { String(localized: "profile.help.contact.header", bundle: #bundle) }
    var supportLabel: String { String(localized: "profile.help.support", bundle: #bundle) }
    var grievanceLabel: String { String(localized: "profile.help.grievance", bundle: #bundle) }
    var pendingValue: String { String(localized: "profile.help.pending", bundle: #bundle) }
    var grievanceFooter: String { String(localized: "profile.help.grievance.footer", bundle: #bundle) }
    var documentsHeader: String { String(localized: "profile.help.documents.header", bundle: #bundle) }
    var termsLabel: String { String(localized: "profile.help.terms", bundle: #bundle) }
    var privacyLabel: String { String(localized: "profile.help.privacyPolicy", bundle: #bundle) }
    var safetyHeader: String { String(localized: "profile.help.safety.header", bundle: #bundle) }
    var reportTitle: String { String(localized: "profile.help.report", bundle: #bundle) }
    var reportSubtitle: String { String(localized: "profile.help.report.subtitle", bundle: #bundle) }
    var blockedTitle: String { String(localized: "profile.help.blocked", bundle: #bundle) }

    /// "Report a problem with someone" leads to the Blocked list, where people can be managed; reporting a post,
    /// comment, person or Place happens from its ••• menu (R1).
    func blockedTapped() { router.open(.settingsPage(.blocked)) }
}
