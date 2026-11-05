import Core
import Foundation
import Models

/// A2: sign in with an email address and a 6-digit code (stub only in Phase 1; the stub's code is 123456).
/// Step 1 checks the address and sends a code; step 2 takes the code (typed, autofilled or pasted), checks it as soon
/// as all 6 digits are in, and offers Resend after a 30-second countdown.
///
/// The countdown runs on the injected clock (`now`): the ViewModel stores when the code was sent and works out the
/// seconds left, so tests move a fake clock instead of waiting. A wrong, expired or rate-limited code arrives as an
/// `AppError` from the server, and its message is shown.
@MainActor @Observable
final class EmailCodeViewModel {
    enum Step: Equatable {
        case email
        case code
    }

    static let codeLength = 6
    static let resendWait = 30

    /// What the person typed. Editing it allows the inline error to show.
    var email: String {
        didSet { hasEditedEmail = true }
    }
    private(set) var hasEditedEmail = false
    private(set) var step: Step = .email
    /// The digits entered so far (at most 6).
    private(set) var code = ""
    private(set) var isSending = false
    private(set) var isVerifying = false
    /// Why the last send or check failed, shown on the current step.
    private(set) var errorMessage: String?
    /// When the last code was sent; the resend countdown starts here.
    private(set) var sentAt: Date?

    private let auth: any AuthRepository
    private let session: SessionStore
    private let router: Router
    private let now: @Sendable () -> Date

    /// Cheap: no loading here (ADR 005). `now` is injected, never `Date()`.
    init(auth: any AuthRepository, session: SessionStore, router: Router, now: @escaping @Sendable () -> Date) {
        self.auth = auth
        self.session = session
        self.router = router
        self.now = now
        email = ""
    }

    // MARK: Email

    var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// One "@", something before it, and a dot inside the part after it, with no spaces: "riya@example.com".
    static func isValidEmail(_ text: String) -> Bool {
        let address = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = address.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !address.contains(where: \.isWhitespace) else { return false }
        let domain = parts[1].split(separator: ".", omittingEmptySubsequences: false)
        return domain.count >= 2 && domain.allSatisfy { !$0.isEmpty }
    }

    var isEmailValid: Bool { Self.isValidEmail(email) }

    /// Shown under the field only after the person has typed.
    var emailError: String? { hasEditedEmail && !isEmailValid ? EmailCodeText.emailError : nil }

    var canSendCode: Bool { isEmailValid && !isSending }

    func sendCodeTapped() async {
        guard canSendCode else { return }
        await send()
    }

    func changeEmailTapped() {
        step = .email
        code = ""
        errorMessage = nil
    }

    // MARK: Resend

    /// Seconds until Resend is allowed (0 when it is).
    var resendSecondsLeft: Int {
        guard let sentAt else { return 0 }
        let waited = Int(now().timeIntervalSince(sentAt))
        return max(0, Self.resendWait - waited)
    }

    var canResend: Bool { resendSecondsLeft == 0 && !isSending && !isVerifying }

    /// "Resend code in 0:30" while counting down, then "Resend code".
    var resendText: String {
        let left = resendSecondsLeft
        guard left > 0 else { return EmailCodeText.resend }
        return EmailCodeText.resendIn(Duration.seconds(left).formatted(.time(pattern: .minuteSecond)))
    }

    func resendTapped() async {
        guard canResend else { return }
        code = ""
        await send()
    }

    // MARK: Code

    var isCodeComplete: Bool { code.count == Self.codeLength }

    /// Typing, autofill and paste all land here: only digits are kept, at most 6.
    func codeChanged(_ text: String) {
        code = String(text.filter(\.isWholeNumber).prefix(Self.codeLength))
        if !code.isEmpty { errorMessage = nil }
    }

    /// Called as soon as all 6 digits are in.
    func verifyCode() async {
        guard isCodeComplete, !isVerifying else { return }
        isVerifying = true
        defer { isVerifying = false }
        do {
            let user = try await auth.verifyEmailCode(code, email: trimmedEmail)
            SignedInRoute.finish(user, session: session, router: router)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = AppError(error).message   // wrong, expired or rate-limited: the server's own words
            code = ""
        }
    }

    // MARK: Sending

    private func send() async {
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            try await auth.sendEmailCode(to: trimmedEmail)
            sentAt = now()
            step = .code
        } catch is CancellationError {
            return
        } catch {
            errorMessage = AppError(error).message
        }
    }
}

/// A2's text, read from AuthFeature's own catalog (`bundle: #bundle`, task X-3).
enum EmailCodeText {
    static var emailTitle: String { String(localized: "auth.emailCode.emailTitle", bundle: #bundle) }
    static var emailPlaceholder: String { String(localized: "auth.emailCode.emailPlaceholder", bundle: #bundle) }
    static var emailError: String { String(localized: "auth.emailCode.emailError", bundle: #bundle) }
    static var sendCode: String { String(localized: "auth.emailCode.sendCode", bundle: #bundle) }
    static var codeTitle: String { String(localized: "auth.emailCode.codeTitle", bundle: #bundle) }
    static var changeEmail: String { String(localized: "auth.emailCode.changeEmail", bundle: #bundle) }
    static var resend: String { String(localized: "auth.emailCode.resend", bundle: #bundle) }
    static var codeLabel: String { String(localized: "auth.emailCode.codeLabel", bundle: #bundle) }

    /// "Enter the 6-digit code we sent to riya@example.com."
    static func codeSentTo(_ email: String) -> String {
        String(localized: "auth.emailCode.codeSentTo \(email)", bundle: #bundle)
    }

    /// "Resend code in 0:30"
    static func resendIn(_ time: String) -> String {
        String(localized: "auth.emailCode.resendIn \(time)", bundle: #bundle)
    }
}
