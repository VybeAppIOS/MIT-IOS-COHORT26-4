import Core
import Testing
@testable import OnboardingFeature

/// Builds every entry point of `OnboardingScreens` (task F-16).
@MainActor
struct OnboardingScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = OnboardingScreens.root(deps)
        _ = OnboardingScreens.view(for: .nameAndPhoto, deps)
        _ = OnboardingScreens.view(for: .interests, deps)
        _ = OnboardingScreens.view(for: .location, deps)
        _ = OnboardingScreens.view(for: .findFriends, deps)
    }
}
