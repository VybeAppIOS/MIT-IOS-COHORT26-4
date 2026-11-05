import AuthFeature
import ChatFeature
import CommunityFeature
import Core
import EditorFeature
import FriendsFeature
import HangoutDetailFeature
import LiveFeature
import ModerationFeature
import OnboardingFeature
import PostingFeature
import ProfileFeature
import SearchFeature
import SwiftUI

/// Maps a route group, a `Sheet` or a `Cover` to the feature that owns it. It never names a View or a ViewModel
/// (ADR 002): each feature's `Screens` builds its own. Discover has no pushed routes, so it is not here.
struct ScreenFactory {
    let deps: AppDependencies

    // One case per feature (ADR 003), kept exhaustive so a new feature cannot be forgotten.
    // Exemption from the 10-branch limit approved by Lohitaksh.
    @ViewBuilder
    // swiftlint:disable:next cyclomatic_complexity
    func screen(for route: Route) -> some View {
        switch route {
        case .onboarding(let route): OnboardingScreens.view(for: route, deps)
        case .auth(let route): AuthScreens.view(for: route, deps)
        case .hangoutDetail(let route): HangoutDetailScreens.view(for: route, deps)
        case .live(let route): LiveScreens.view(for: route, deps)
        case .posting(let route): PostingScreens.view(for: route, deps)
        case .search(let route): SearchScreens.view(for: route, deps)
        case .profile(let route): ProfileScreens.view(for: route, deps)
        case .community(let route): CommunityScreens.view(for: route, deps)
        case .friends(let route): FriendsScreens.view(for: route, deps)
        case .chat(let route): ChatScreens.view(for: route, deps)
        case .moderation(let route): ModerationScreens.view(for: route, deps)
        case .editor(let route): EditorScreens.view(for: route, deps)
        }
    }

    @ViewBuilder
    func sheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .spot(let id): HangoutDetailScreens.spotSheet(id, deps)
        case .report(let target): ModerationScreens.reportSheet(target, deps)
        case .blockConfirm(let id): ModerationScreens.blockConfirmSheet(id, deps)
        case .share(let item): ChatScreens.shareSheet(item, deps)
        case .suggestPlace: EditorScreens.suggestPlaceSheet(deps)
        case .editPost(let id): PostingScreens.editPostSheet(id, deps)
        case .groupInvitation(let id): ChatScreens.groupInvitationSheet(id, deps)
        }
    }

    @ViewBuilder
    func cover(for cover: Cover) -> some View {
        switch cover {
        case .live(let id): LiveScreens.liveCover(id, deps)
        case .editor(let start): EditorScreens.editorCover(start, deps)
        }
    }
}
