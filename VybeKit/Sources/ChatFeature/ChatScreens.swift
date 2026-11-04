import Core
import Design
import Models
import SwiftUI

/// The only public type in ChatFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum ChatScreens {
    @ViewBuilder
    public static func view(for route: ChatRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .list: ScreenPlaceholder(id: "CH1", name: "Chats list")
        case .conversation: ScreenPlaceholder(id: "CH2", name: "Conversation")
        case .groupInfo: ScreenPlaceholder(id: "CH4", name: "Group info")
        }
    }

    @ViewBuilder
    public static func shareSheet(_ item: ShareItem, _ deps: AppDependencies) -> some View {
        ScreenPlaceholder(id: "CH5", name: "Share to…")
    }

    @ViewBuilder
    public static func groupInvitationSheet(_ id: ConversationID, _ deps: AppDependencies) -> some View {
        ScreenPlaceholder(id: "CH7", name: "Group invitation")
    }
}

/// Stands in for a screen until its task replaces the `case` in this feature's `Screens` (task F-16).
/// Developer-only text, so it is not localized.
private struct ScreenPlaceholder: View {
    let id: String
    let name: String

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            Text(verbatim: id).font(Theme.Font.largeTitle)
            Text(verbatim: name).font(Theme.Font.headline)
            Text(verbatim: "Placeholder until this screen's task replaces it")
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: name))
    }
}
