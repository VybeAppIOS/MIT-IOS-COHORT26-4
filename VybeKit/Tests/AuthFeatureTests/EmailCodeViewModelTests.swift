import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import AuthFeature

/// A clock the test moves by hand. `Mutex` keeps it safe to read from any thread (no unchecked Sendable).
private final class FakeClock: Sendable {
    private let time = Mutex(SampleData.day)
    func advance(seconds: Int) { time.withLock { $0 += TimeInterval(seconds) } }
    var now: @Sendable () -> Date { { [self] in time.withLock { $0 } } }
}

/// The stub, but the verified person is new (no username yet).
private struct NewUserAuth: AuthRepository {
    let base = StubAuthRepository()
    func signInWithApple() async throws -> UserProfile { try await base.signInWithApple() }
    func signInWithGoogle() async throws -> UserProfile { try await base.signInWithGoogle() }
    func sendEmailCode(to email: String) async throws { try await base.sendEmailCode(to: email) }
    func verifyEmailCode(_ code: String, email: String) async throws -> UserProfile {
        _ = try await base.verifyEmailCode(code, email: email)
        return UserProfile(id: "user-example-new", username: "", displayName: "", createdAt: SampleData.day)
    }
    func isUsernameAvailable(_ username: String) async throws -> Bool { true }
    func completeAccount(username: String, dateOfBirth: Date, confirmed18: Bool) async throws -> UserProfile {
        try await base.completeAccount(username: username, dateOfBirth: dateOfBirth, confirmed18: confirmed18)
    }
    func signOut() async throws {}
    func deleteAccount() async throws {}
}

@MainActor
struct EmailCodeViewModelTests {
    private struct Fixture {
        let viewModel: EmailCodeViewModel
        let session: SessionStore
        let router: Router
        let clock: FakeClock
    }

    private func makeFixture(_ auth: any AuthRepository = StubAuthRepository()) -> Fixture {
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.test.\(UUID().uuidString)"))
        let router = Router()
        router.setOnboarding(true)
        let clock = FakeClock()
        let viewModel = EmailCodeViewModel(auth: auth, session: session, router: router, now: clock.now)
        return Fixture(viewModel: viewModel, session: session, router: router, clock: clock)
    }

    private func onCodeStep(_ auth: any AuthRepository = StubAuthRepository()) async -> Fixture {
        let fixture = makeFixture(auth)
        fixture.viewModel.email = "riya@example.com"
        await fixture.viewModel.sendCodeTapped()
        return fixture
    }

    // MARK: Validation (task SC-A2)

    @Test(arguments: ["riya@example.com", "  riya@example.com  ", "r.k@mail.example.in"])
    func goodAddressesPass(email: String) {
        #expect(EmailCodeViewModel.isValidEmail(email))
    }

    @Test(arguments: ["", "riya", "riya@", "@example.com", "riya@example", "riya@@example.com", "ri ya@example.com",
                      "riya@example."])
    func badAddressesFail(email: String) {
        #expect(!EmailCodeViewModel.isValidEmail(email))
    }

    @Test func sendCodeStaysDisabledForABadAddress() {
        let fixture = makeFixture()
        fixture.viewModel.email = "riya@"
        #expect(!fixture.viewModel.canSendCode)
        #expect(fixture.viewModel.emailError == EmailCodeText.emailError)
    }

    @Test func noErrorBeforeTyping() {
        #expect(makeFixture().viewModel.emailError == nil)
    }

    // MARK: The resend timer (task SC-A2, injected clock)

    @Test func resendCountsDownThirtySecondsOnTheInjectedClock() async {
        let fixture = await onCodeStep()
        let viewModel = fixture.viewModel
        #expect(viewModel.step == .code)
        #expect(viewModel.resendSecondsLeft == 30)
        #expect(!viewModel.canResend)
        #expect(viewModel.resendText == "Resend code in 0:30")
        fixture.clock.advance(seconds: 29)
        #expect(viewModel.resendSecondsLeft == 1)
        #expect(!viewModel.canResend)
        fixture.clock.advance(seconds: 1)
        #expect(viewModel.resendSecondsLeft == 0)
        #expect(viewModel.canResend)
        #expect(viewModel.resendText == "Resend code")
    }

    @Test func resendingStartsTheCountdownAgain() async {
        let fixture = await onCodeStep()
        fixture.clock.advance(seconds: 45)
        await fixture.viewModel.resendTapped()
        #expect(fixture.viewModel.resendSecondsLeft == 30)
    }

    @Test func resendBeforeTheCountdownEndsDoesNothing() async {
        let fixture = await onCodeStep()
        fixture.clock.advance(seconds: 10)
        await fixture.viewModel.resendTapped()
        #expect(fixture.viewModel.resendSecondsLeft == 20)
    }

    // MARK: Code entry

    @Test func aPastedCodeKeepsOnlySixDigits() {
        let viewModel = makeFixture().viewModel
        viewModel.codeChanged("Your code: 12-34-56 78")
        #expect(viewModel.code == "123456")
        #expect(viewModel.isCodeComplete)
    }

    @Test func theRightCodeSignsAnExistingPersonIn() async {
        let fixture = await onCodeStep()
        fixture.viewModel.codeChanged(StubAuthRepository.workingEmailCode)
        await fixture.viewModel.verifyCode()
        #expect(fixture.session.onboardingDone)
        #expect(!fixture.router.isOnboarding)
    }

    @Test func theRightCodeTakesANewPersonToAccountBasics() async {
        let fixture = await onCodeStep(NewUserAuth())
        fixture.viewModel.codeChanged(StubAuthRepository.workingEmailCode)
        await fixture.viewModel.verifyCode()
        #expect(fixture.router.path(for: .onboarding) == [.accountBasics])
        #expect(!fixture.session.onboardingDone)
    }

    @Test func aWrongCodeShowsTheErrorAndClearsTheBoxes() async {
        let fixture = await onCodeStep()
        fixture.viewModel.codeChanged("111111")
        await fixture.viewModel.verifyCode()
        #expect(fixture.viewModel.errorMessage == "That code is not right.")
        #expect(fixture.viewModel.code.isEmpty)
        #expect(!fixture.session.onboardingDone)
    }

    @Test func changeEmailGoesBackToTheFirstStep() async {
        let fixture = await onCodeStep()
        fixture.viewModel.codeChanged("12")
        fixture.viewModel.changeEmailTapped()
        #expect(fixture.viewModel.step == .email)
        #expect(fixture.viewModel.code.isEmpty)
    }

    @Test func textsResolveToRealText() {
        #expect(EmailCodeText.codeTitle == "We sent you a code")
        #expect(EmailCodeText.codeSentTo("riya@example.com") == "Enter the 6-digit code we sent to riya@example.com.")
    }
}
