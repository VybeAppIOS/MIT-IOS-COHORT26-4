import Core
import Models
import Testing
@testable import ChatFeature

/// Builds every entry point of `ChatScreens` (task F-16).
@MainActor
struct ChatScreensTests {
    @Test func everyEntryPointBuilds() {
        let deps = AppDependencies.preview(.loaded)
        _ = ChatScreens.view(for: .list, deps)
        _ = ChatScreens.view(for: .conversation("c1"), deps)
        _ = ChatScreens.view(for: .groupInfo("c1"), deps)
        _ = ChatScreens.shareSheet(.hangout("h1"), deps)
        _ = ChatScreens.groupInvitationSheet("c1", deps)
    }
}
