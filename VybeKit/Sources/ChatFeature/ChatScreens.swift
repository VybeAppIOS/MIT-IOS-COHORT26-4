import Core
import Models
import SwiftUI

/// The only public type in ChatFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum ChatScreens {
    /// Builds the New chat sheet for the Chats list.
    private static func newChatFactory(_ deps: AppDependencies) -> NewChatFactory {
        { onExit in
            NewChatViewModel(
                friends: deps.friends, chat: deps.chat, session: deps.session, network: deps.network, onExit: onExit)
        }
    }

    @ViewBuilder
    public static func view(for route: ChatRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .list:
            ListView(viewModel: ListViewModel(
                chat: deps.chat, profiles: deps.profiles, session: deps.session, badges: deps.badges,
                network: deps.network, router: deps.router, now: deps.now, makeNewChat: newChatFactory(deps)))
        case .conversation(let id):
            ConversationView(viewModel: ConversationViewModel(
                conversationID: id, chat: deps.chat, profiles: deps.profiles, hangouts: deps.hangouts,
                photos: deps.photos, libraryStore: deps.libraryStore, session: deps.session, badges: deps.badges,
                network: deps.network, router: deps.router, now: deps.now, recorder: SystemVoiceRecorder(),
                player: AudioPlayer(),
                makePoll: { conversationID, onClose in
                    PollViewModel(
                        conversationID: conversationID, chat: deps.chat, network: deps.network, onClose: onClose)
                }))
        case .groupInfo(let id):
            GroupInfoView(viewModel: GroupInfoViewModel(
                conversationID: id, chat: deps.chat, friends: deps.friends, profiles: deps.profiles,
                session: deps.session, network: deps.network, router: deps.router))
        case .groupPhotos(let id):
            GroupPhotosView(viewModel: GroupPhotosViewModel(
                conversationID: id, chat: deps.chat, photos: deps.photos, session: deps.session))
        }
    }

    @ViewBuilder
    public static func shareSheet(_ item: ShareItem, _ deps: AppDependencies) -> some View {
        ShareSheetView(viewModel: ShareSheetViewModel(
            item: item, chat: deps.chat, friends: deps.friends, hangouts: deps.hangouts, feed: deps.feed,
            session: deps.session, network: deps.network, router: deps.router))
    }

    @ViewBuilder
    public static func groupInvitationSheet(_ id: ConversationID, _ deps: AppDependencies) -> some View {
        InvitationView(viewModel: InvitationViewModel(
            conversationID: id, chat: deps.chat, profiles: deps.profiles, session: deps.session,
            network: deps.network, router: deps.router))
    }
}
