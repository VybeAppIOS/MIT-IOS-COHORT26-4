import Core
import Testing
@testable import AuthFeature

/// Builds every entry point of `AuthScreens` (task F-16).
@MainActor
struct AuthScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = AuthScreens.view(for: .signIn, deps)
        _ = AuthScreens.view(for: .emailSignIn, deps)
        _ = AuthScreens.view(for: .accountBasics, deps)
    }
}
