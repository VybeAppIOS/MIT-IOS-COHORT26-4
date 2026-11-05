import Core
import Foundation
import Models
import Synchronization
import Testing
@testable import AuthFeature

/// The auth stub's rules, counting availability lookups and completed accounts. `Mutex` keeps it safe to share.
private final class CountingAuth: AuthRepository {
    private let base = StubAuthRepository()
    private let lookups = Mutex<[String]>([])
    private let completed = Mutex(0)

    var lookedUp: [String] { lookups.withLock { $0 } }
    var completedCount: Int { completed.withLock { $0 } }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        lookups.withLock { $0.append(username) }
        return try await base.isUsernameAvailable(username)
    }

    func completeAccount(username: String, dateOfBirth: Date, confirmed18: Bool) async throws -> UserProfile {
        completed.withLock { $0 += 1 }
        return try await base.completeAccount(username: username, dateOfBirth: dateOfBirth, confirmed18: confirmed18)
    }

    func signInWithApple() async throws -> UserProfile { try await base.signInWithApple() }
    func signInWithGoogle() async throws -> UserProfile { try await base.signInWithGoogle() }
    func sendEmailCode(to email: String) async throws {}
    func verifyEmailCode(_ code: String, email: String) async throws -> UserProfile {
        try await base.verifyEmailCode(code, email: email)
    }
    func signOut() async throws {}
    func deleteAccount() async throws {}
}

@MainActor
struct AccountBasicsViewModelTests {
    private let calendar = AccountBasicsViewModel.pune

    /// 5 Nov 2026, noon, Pune.
    private var today: Date { day(2026, 11, 5) }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .distantPast
    }

    private struct Fixture {
        let viewModel: AccountBasicsViewModel
        let auth: CountingAuth
        let session: SessionStore
        let router: Router
    }

    private func makeFixture(today: Date? = nil) -> Fixture {
        let auth = CountingAuth()
        let session = SessionStore(settings: AppSettings(suiteName: "vybe.test.\(UUID().uuidString)"))
        let router = Router()
        router.setOnboarding(true)
        let now = today ?? self.today
        let viewModel = AccountBasicsViewModel(auth: auth, session: session, router: router, now: { now },
                                               calendar: calendar, debounce: { _ in })
        return Fixture(viewModel: viewModel, auth: auth, session: session, router: router)
    }

    /// A free username typed and checked, ready for a birth date.
    private func readyFixture(today: Date? = nil) async -> Fixture {
        let fixture = makeFixture(today: today)
        fixture.viewModel.username = "riya.k"
        await fixture.viewModel.waitForCheck()
        return fixture
    }

    // MARK: Username rules (task SC-A3)

    @Test(arguments: ["riya", "riya.k", "riya_k", "r1y4", "abc", String(repeating: "a", count: 20)])
    func usernamesThatFollowTheRules(name: String) {
        #expect(UsernameRules.problem(with: name) == nil)
    }

    @Test func tooShortOrTooLong() {
        #expect(UsernameRules.problem(with: "ab") == .length)
        #expect(UsernameRules.problem(with: String(repeating: "a", count: 21)) == .length)
    }

    @Test(arguments: ["riya k", "riya-k", "riya!", "riyá", "ri🌿ya", "रियाकुमारी"])
    // Lengths are counted as people see them, so a Devanagari example needs 3+ characters to reach this rule.
    func onlyLowerCaseLettersDigitsUnderscoreAndDot(name: String) {
        #expect(UsernameRules.problem(with: name) == .characters)
    }

    @Test func reservedWordsAreRefused() {
        #expect(UsernameRules.problem(with: "vybe") == .reserved)
        #expect(UsernameRules.problem(with: "admin") == .reserved)
    }

    @Test func typingCapitalsIsLowerCased() {
        let viewModel = makeFixture().viewModel
        viewModel.username = "Riya.K"
        #expect(viewModel.username == "riya.k")
        viewModel.username = "VYBE"
        #expect(viewModel.availability == .invalid(.reserved))
    }

    // MARK: Taken username (task SC-A3)

    @Test func aTakenUsernameIsReportedAndContinueStaysDisabled() async {
        let fixture = makeFixture()
        fixture.viewModel.username = "sample.friend"
        await fixture.viewModel.waitForCheck()
        #expect(fixture.viewModel.availability == .taken)
        fixture.viewModel.birthDate = day(2000, 1, 1)
        #expect(!fixture.viewModel.canContinue)
    }

    @Test func aFreeUsernameIsAvailable() async {
        let fixture = await readyFixture()
        #expect(fixture.viewModel.availability == .available)
        #expect(fixture.viewModel.statusText == "@riya.k is available")
    }

    @Test func onlyTheLastTypedNameIsLookedUp() async {
        let fixture = makeFixture()
        fixture.viewModel.username = "riy"
        fixture.viewModel.username = "riya"
        fixture.viewModel.username = "riya.k"
        await fixture.viewModel.waitForCheck()
        #expect(fixture.auth.lookedUp == ["riya.k"])
    }

    @Test func aNameThatBreaksTheRulesIsNeverLookedUp() async {
        let fixture = makeFixture()
        fixture.viewModel.username = "ri"
        await fixture.viewModel.waitForCheck()
        #expect(fixture.auth.lookedUp.isEmpty)
        #expect(fixture.viewModel.availability == .invalid(.length))
    }

    // MARK: Under 18 (task SC-A3)

    @Test func underEighteenShowsTheBlockAndSendsNothing() async {
        let fixture = await readyFixture()
        fixture.viewModel.birthDate = day(2009, 6, 1)           // 17
        await fixture.viewModel.continueTapped()
        #expect(fixture.viewModel.isBlocked)
        #expect(fixture.auth.completedCount == 0)
        #expect(fixture.router.path(for: .onboarding).isEmpty)
        #expect(!fixture.viewModel.canContinue)
    }

    @Test func continueNeedsADateToBePicked() async {
        let fixture = await readyFixture()
        #expect(!fixture.viewModel.canContinue)                // today's default is never taken as an answer
        fixture.viewModel.birthDate = day(2000, 1, 1)
        #expect(fixture.viewModel.canContinue)
    }

    // MARK: The boundary on the 18th birthday (task SC-A3)

    @Test func theDayBeforeTheEighteenthBirthdayIsBlocked() {
        #expect(!AgeRule.isAdult(bornOn: day(2008, 11, 6), today: today, calendar: calendar))
    }

    @Test func theEighteenthBirthdayItselfIsAllowed() {
        #expect(AgeRule.isAdult(bornOn: day(2008, 11, 5), today: today, calendar: calendar))
    }

    @Test func theDayAfterIsAllowed() {
        #expect(AgeRule.isAdult(bornOn: day(2008, 11, 4), today: today, calendar: calendar))
    }

    @Test func bornOnTwentyNinthFebruaryTurnsEighteenOnFirstMarch() {
        let born = day(2008, 2, 29)                             // 2026 has no 29 February
        #expect(!AgeRule.isAdult(bornOn: born, today: day(2026, 2, 28), calendar: calendar))
        #expect(AgeRule.isAdult(bornOn: born, today: day(2026, 3, 1), calendar: calendar))
    }

    // MARK: The adult path

    @Test func anAdultCompletesTheAccountAndGoesOnToNameAndPhoto() async {
        let fixture = await readyFixture()
        fixture.viewModel.birthDate = day(2008, 11, 5)          // 18 today
        await fixture.viewModel.continueTapped()
        #expect(fixture.auth.completedCount == 1)
        #expect(fixture.session.currentUser?.username == "riya.k")
        #expect(fixture.router.path(for: .onboarding) == [.nameAndPhoto])
        #expect(!fixture.viewModel.isBlocked)
    }

    @Test func textsResolveToRealText() {
        #expect(AccountBasicsText.birthDate == "Date of birth")
        #expect(AccountBasicsText.blockedTitle == "Vybe is for people 18 and over")
    }
}
