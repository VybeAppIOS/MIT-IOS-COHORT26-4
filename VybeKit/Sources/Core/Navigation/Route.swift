import Foundation

/// One case per feature, each carrying that feature's own route enum (ADR 003). Every pushed screen in
/// `docs/IA.md` has a route, in every phase. Pushes carry IDs only. Discover has no pushed routes of its own
/// (its screens are a tab root, a card and a local sheet).
public enum Route: Hashable, Codable, Sendable {
    case onboarding(OnboardingRoute)
    case auth(AuthRoute)
    case hangoutDetail(HangoutDetailRoute)
    case live(LiveRoute)
    case posting(PostingRoute)
    case search(SearchRoute)
    case profile(ProfileRoute)
    case community(CommunityRoute)
    case friends(FriendsRoute)
    case chat(ChatRoute)
    case moderation(ModerationRoute)
    case editor(EditorRoute)
}
