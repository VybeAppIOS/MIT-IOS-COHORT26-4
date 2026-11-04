import Core
import Models
import Testing
@testable import FriendsFeature

/// Builds every entry point of `FriendsScreens` (task F-16).
@MainActor
struct FriendsScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = FriendsScreens.view(for: .hub, deps)
        _ = FriendsScreens.view(for: .profile("u1"), deps)
        _ = FriendsScreens.view(for: .mutualFriends("u1"), deps)
    }
}
