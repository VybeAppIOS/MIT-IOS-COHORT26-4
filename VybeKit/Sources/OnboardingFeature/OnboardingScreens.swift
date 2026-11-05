import Core
import SwiftUI

/// The only public type in OnboardingFeature (ADR 002). The App's screen factory calls these; each one builds the
/// feature's View and ViewModel from `AppDependencies`. Every onboarding screen is built (O1 to O5).
public enum OnboardingScreens {
    @ViewBuilder
    public static func root(_ deps: AppDependencies) -> some View {
        WelcomeView(viewModel: WelcomeViewModel(router: deps.router))
    }

    @ViewBuilder
    public static func view(for route: OnboardingRoute, _ deps: AppDependencies) -> some View {
        switch route {
        case .nameAndPhoto:
            NameAndPhotoView(viewModel: NameAndPhotoViewModel(
                session: deps.session, router: deps.router, processor: PhotoProcessor()))
        case .interests: InterestsView(viewModel: InterestsViewModel(session: deps.session, router: deps.router))
        case .location:
            LocationView(viewModel: LocationViewModel(
                location: deps.location, hangouts: deps.hangouts, places: deps.places, session: deps.session,
                router: deps.router))
        case .findFriends:
            FindFriendsView(viewModel: FindFriendsViewModel(
                friends: deps.friends, photos: deps.photos, session: deps.session, router: deps.router))
        }
    }
}
