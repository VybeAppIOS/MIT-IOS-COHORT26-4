import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import AuthFeature

/// An auth repository whose Apple and Google answers the test chooses: a user, a failure, or a cancel.
/// `Mutex` keeps it safe to share (no unchecked Sendable); `calls` counts attempts.
private final class FakeAuth: AuthRepository {
    enum Answer: Sendable { case user(UserProfile), fail, cancel }
    private let answers: Mutex<[Answer]>
    private let count = Mutex(0)

    /// Answers in order; the last one repeats.
    init(_ answers: Answer...) { self.answers = Mutex(answers) }

    var calls: Int { count.withLock { $0 } }

    private func next() throws -> UserProfile {
        count.withLock { $0 += 1 }
        let answer = answers.withLock { list in list.count > 1 ? list.removeFirst() : list[0] }
        switch answer {
        case .user(let user): return user
        case .fail: throw AppError.offline
        case .cancel: throw CancellationError()
        }
    }

    func signInWithApple() async throws -> UserProfile { try next() }
    func signInWithGoogle() async throws -> UserProfile { try next() }
    func sendEmailCode(to email: String) async throws {}
    func verifyEmailCode(_ code: String, email: String) async throws -> UserProfile { try next() }
    func isUsernameAvailable(_ username: String) async throws -> Bool { true }
    func completeAccount(username: String, dateOfBirth: Date, confirmed18: Bool) async throws -> UserProfile {
        try next()
    }
    func signOut() async throws {}
    func deleteAccount() async throws {}
}

@MainActor
struct SignInViewModelTests {
    /// A brand-new account: no username chosen yet.
    private let newUser = UserProfile(id: "user-example-new", username: "", displayName: "", createdAt: SampleData.day)

    /// The screen with a fresh session and a router on the onboarding stack.
    private struct Fixture {
        let viewModel: SignInViewModel
        let session: SessionStore
        let router: Router
    }

    private func makeViewModel(_ auth: any AuthRepository) -> Fixture {
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.test.\(UUID().uuidString)"))
        let router = Router()
        router.setOnboarding(true)
        return Fixture(viewModel: SignInViewModel(auth: auth, session: session, router: router), session: session,
                       router: router)
    }

    // MARK: The task: a new user goes to Account basics, an existing one finishes

    @Test func aNewUserGoesToAccountBasics() async {
        let fixture = makeViewModel(FakeAuth(.user(newUser)))
        let (viewModel, session, router) = (fixture.viewModel, fixture.session, fixture.router)
        await viewModel.appleTapped()
        #expect(router.path(for: .onboarding) == [.accountBasics])
        #expect(session.currentUser?.id == newUser.id)
        #expect(!session.onboardingDone)
    }

    @Test func anExistingUserFinishesAndKeepsTheirInterests() async {
        let existing = SampleSocialData.currentUser
        let fixture = makeViewModel(StubAuthRepository())
        let (viewModel, session, router) = (fixture.viewModel, fixture.session, fixture.router)
        await viewModel.googleTapped()
        #expect(session.onboardingDone)
        #expect(!router.isOnboarding)
        #expect(session.currentUser?.interests == existing.interests)
    }

    // MARK: Failure, retry, cancel

    @Test func aFailureShowsTheErrorAndRetryTriesTheSameProviderAgain() async {
        let auth = FakeAuth(.fail, .user(SampleSocialData.currentUser))
        let fixture = makeViewModel(auth)
        let (viewModel, session) = (fixture.viewModel, fixture.session)
        await viewModel.appleTapped()
        #expect(viewModel.errorMessage == SignInText.appleFailed)
        #expect(!session.onboardingDone)
        await viewModel.retryTapped()
        #expect(viewModel.errorMessage == nil)
        #expect(session.onboardingDone)
        #expect(auth.calls == 2)
    }

    @Test func cancellingShowsNoError() async {
        let fixture = makeViewModel(FakeAuth(.cancel))
        let (viewModel, session) = (fixture.viewModel, fixture.session)
        await viewModel.googleTapped()
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isBusy)
        #expect(!session.onboardingDone)
    }

    // MARK: Email

    @Test func continueWithEmailOpensEmailSignIn() {
        let fixture = makeViewModel(FakeAuth(.fail))
        let (viewModel, router) = (fixture.viewModel, fixture.router)
        viewModel.emailTapped()
        #expect(router.path(for: .onboarding) == [.emailSignIn])
    }

    @Test func textsResolveToRealText() {
        #expect(SignInText.google == "Continue with Google")
        #expect(SignInText.email == "Continue with email")
        #expect(SignInText.retry == "Try again")
    }
}
