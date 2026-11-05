import Core
import Testing
@testable import OnboardingFeature

@MainActor
struct WelcomeViewModelTests {
    @Test func textsResolveToRealText() {
        #expect(WelcomeText.wordmark == "Vybe")
        #expect(WelcomeText.pitch == "Find your Vybe.")
        #expect(WelcomeText.getStarted == "Get started")
        #expect(WelcomeText.haveAccount == "Already have an account?")
        #expect(WelcomeText.signIn == "Sign in")
    }

    @Test func getStartedOpensNameAndPhoto() {
        let router = Router()
        router.setOnboarding(true)
        WelcomeViewModel(router: router).getStarted()
        #expect(router.path(for: .onboarding) == [.nameAndPhoto])
    }

    @Test func signInOpensSignIn() {
        let router = Router()
        router.setOnboarding(true)
        WelcomeViewModel(router: router).signIn()
        #expect(router.path(for: .onboarding) == [.signIn])
    }
}
