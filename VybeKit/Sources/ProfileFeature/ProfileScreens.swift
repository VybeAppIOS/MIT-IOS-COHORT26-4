import Core
import SwiftUI

/// The only public type in ProfileFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. A screen task replaces only its own placeholder `case`.
public enum ProfileScreens {
    @ViewBuilder
    public static func root(_ deps: AppDependencies) -> some View {
        ProfileView(viewModel: ProfileViewModel(
            profiles: deps.profiles, auth: deps.auth, feed: deps.feed, photos: deps.photos, session: deps.session,
            libraryStore: deps.libraryStore, router: deps.router))
    }

    @ViewBuilder
    public static func view(for route: ProfileRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .saved:
            SavedView(viewModel: SavedViewModel(
                hangouts: deps.hangouts, places: deps.places, photos: deps.photos, libraryStore: deps.libraryStore,
                router: deps.router))
        case .drafts:
            DraftsView(viewModel: DraftsViewModel(
                places: deps.places, photos: deps.photos, libraryStore: deps.libraryStore, router: deps.router))
        case .readyToPost:
            ReadyToPostView(viewModel: ReadyToPostViewModel(libraryStore: deps.libraryStore, router: deps.router))
        case .settings: SettingsView(viewModel: SettingsViewModel(session: deps.session, router: deps.router))
        case .settingsPage(let page): settingsPage(page, deps)
        case .deleteAccount:
            DeleteAccountView(viewModel: DeleteAccountViewModel(
                auth: deps.auth, session: deps.session, libraryStore: deps.libraryStore, liveStore: deps.liveStore,
                network: deps.network, router: deps.router))
        }
    }

    @ViewBuilder
    private static func settingsPage(_ page: SettingsPage, _ deps: AppDependencies) -> some View {
        switch page {
        case .account:
            AccountSettingsView(viewModel: AccountSettingsViewModel(
                auth: deps.auth, session: deps.session, network: deps.network, router: deps.router))
        case .privacy:
            PrivacyView(viewModel: PrivacyViewModel(profiles: deps.profiles, session: deps.session,
                                                    network: deps.network))
        case .blocked:
            BlockedView(viewModel: BlockedViewModel(safety: deps.safety, session: deps.session, photos: deps.photos,
                                                    network: deps.network))
        case .notifications:
            NotificationsView(viewModel: NotificationsViewModel(
                loadChoices: { NotificationChoices(session: deps.session) },
                saveChoices: { $0.save(to: deps.session) }))
        case .help: HelpView(viewModel: HelpViewModel(router: deps.router))
        case .placeSuggestions:
            MySuggestionsView(viewModel: MySuggestionsViewModel(admin: deps.admin, session: deps.session))
        case .about: AboutView(viewModel: AboutViewModel(hangouts: deps.hangouts, places: deps.places))
        }
    }
}
