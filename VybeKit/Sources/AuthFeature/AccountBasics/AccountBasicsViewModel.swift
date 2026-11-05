import Core
import Foundation
import Models

/// A3: a new person picks a unique username and gives their date of birth. Only people 18 and over may use Vybe:
/// under 18 shows a calm blocking screen and nothing is sent. Otherwise the account is completed and onboarding
/// continues with Name and photo.
///
/// The device should remember an under-18 answer across launches. That needs a flag in Core's `AppSettings` and a
/// check in the App's `RootView` (Lohitaksh); until then the block holds for this session.
@MainActor @Observable
final class AccountBasicsViewModel {
    enum Availability: Equatable {
        case idle
        case invalid(UsernameRules.Problem)
        case checking
        case available
        case taken
        /// The lookup failed; Retry tries again.
        case failed
    }

    /// Lower-cased as it is typed. Every change re-checks the rules at once and availability after a short pause.
    var username: String {
        didSet {
            let lower = username.lowercased()
            if lower != username {
                username = lower                // runs didSet again with the lower-cased name
                return
            }
            usernameChanged()
        }
    }
    private(set) var availability: Availability = .idle
    /// Starts at today; picking a date is what enables Continue (the default is never taken as an answer).
    var birthDate: Date {
        didSet { hasPickedDate = true }
    }
    private(set) var hasPickedDate = false
    /// Under 18: the form is replaced by the blocking screen for good.
    private(set) var isBlocked = false
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    private let auth: any AuthRepository
    private let session: SessionStore
    private let router: Router
    private let now: @Sendable () -> Date
    private let calendar: Calendar
    private let debounce: @Sendable (Duration) async -> Void
    private var checkTask: Task<Void, Never>?

    /// How long typing must pause before the availability lookup.
    static let pause = Duration.milliseconds(400)

    /// Pune's calendar, for the birthday.
    static let pune: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return calendar
    }()

    /// Cheap: no loading here (ADR 005). `now`, the calendar and the pause are injected for tests.
    init(
        auth: any AuthRepository, session: SessionStore, router: Router, now: @escaping @Sendable () -> Date,
        calendar: Calendar = pune,
        debounce: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.auth = auth
        self.session = session
        self.router = router
        self.now = now
        self.calendar = calendar
        self.debounce = debounce
        username = ""
        birthDate = now()                       // observers do not run in init: no date counts as picked yet
    }

    /// The latest date the picker offers.
    var today: Date { now() }

    var canContinue: Bool { availability == .available && hasPickedDate && !isSubmitting && !isBlocked }

    // MARK: Username

    private func usernameChanged() {
        checkTask?.cancel()
        errorMessage = nil
        guard !username.isEmpty else {
            availability = .idle
            return
        }
        if let problem = UsernameRules.problem(with: username) {
            availability = .invalid(problem)
            return
        }
        availability = .checking
        let name = username
        checkTask = Task { [debounce] in
            await debounce(Self.pause)
            guard !Task.isCancelled else { return }
            await self.lookUp(name)
        }
    }

    func retryCheck() {
        guard availability == .failed else { return }
        usernameChanged()
    }

    /// Waits for the current lookup (tests and previews).
    func waitForCheck() async { await checkTask?.value }

    private func lookUp(_ name: String) async {
        do {
            let isFree = try await auth.isUsernameAvailable(name)
            guard name == username else { return }       // a newer name was typed: ignore this answer
            availability = isFree ? .available : .taken
        } catch is CancellationError {
            return
        } catch {
            guard name == username else { return }
            availability = .failed
        }
    }

    // MARK: Continue

    func continueTapped() async {
        guard canContinue else { return }
        guard AgeRule.isAdult(bornOn: birthDate, today: now(), calendar: calendar) else {
            isBlocked = true                    // nothing is sent; Lohitaksh: remember it on the device here
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let user = try await auth.completeAccount(username: username, dateOfBirth: birthDate, confirmed18: true)
            session.setCurrentUser(user)
            router.open(.nameAndPhoto)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = AppError(error).message
        }
    }

    /// The line under the username field.
    var statusText: String? {
        switch availability {
        case .idle: nil
        case .invalid(.length): AccountBasicsText.ruleLength
        case .invalid(.characters): AccountBasicsText.ruleCharacters
        case .invalid(.reserved): AccountBasicsText.ruleReserved
        case .checking: AccountBasicsText.checking
        case .available: AccountBasicsText.available(username)
        case .taken: AccountBasicsText.taken(username)
        case .failed: AccountBasicsText.checkFailed
        }
    }
}

/// A3's text, read from AuthFeature's own catalog (`bundle: #bundle`, task X-3).
enum AccountBasicsText {
    static var title: String { String(localized: "auth.accountBasics.title", bundle: #bundle) }
    static var usernameLabel: String { String(localized: "auth.accountBasics.usernameLabel", bundle: #bundle) }
    static var usernamePlaceholder: String {
        String(localized: "auth.accountBasics.usernamePlaceholder", bundle: #bundle)
    }
    static var birthDate: String { String(localized: "auth.accountBasics.birthDate", bundle: #bundle) }
    static var continueButton: String { String(localized: "auth.accountBasics.continue", bundle: #bundle) }
    static var ruleLength: String { String(localized: "auth.accountBasics.ruleLength", bundle: #bundle) }
    static var ruleCharacters: String { String(localized: "auth.accountBasics.ruleCharacters", bundle: #bundle) }
    static var ruleReserved: String { String(localized: "auth.accountBasics.ruleReserved", bundle: #bundle) }
    static var checking: String { String(localized: "auth.accountBasics.checking", bundle: #bundle) }
    static var checkFailed: String { String(localized: "auth.accountBasics.checkFailed", bundle: #bundle) }
    static var retry: String { String(localized: "auth.accountBasics.retry", bundle: #bundle) }
    static var blockedTitle: String { String(localized: "auth.accountBasics.blockedTitle", bundle: #bundle) }
    static var blockedMessage: String { String(localized: "auth.accountBasics.blockedMessage", bundle: #bundle) }

    /// "@riya is available"
    static func available(_ username: String) -> String {
        String(localized: "auth.accountBasics.available \(username)", bundle: #bundle)
    }

    /// "@riya is taken"
    static func taken(_ username: String) -> String {
        String(localized: "auth.accountBasics.taken \(username)", bundle: #bundle)
    }
}
