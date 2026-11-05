import Core
import Models

/// What happens once someone is signed in, shared by Sign in (A1) and Email sign-in (A2).
///
/// A new person (a profile with no username yet; A3 is where it is chosen) goes on to Account basics. Someone who
/// already has an account skips onboarding: their interests are copied into the draft first, because finishing saves
/// the draft's interests onto the profile.
@MainActor
enum SignedInRoute {
    static func finish(_ user: UserProfile, session: SessionStore, router: Router) {
        session.setCurrentUser(user)
        if user.username.isEmpty {
            router.open(.accountBasics)         // new: choose a username, date of birth, 18+
            return
        }
        session.onboardingDraft.interests = user.interests
        session.completeOnboarding()
        router.reset()                          // RootView switches to the tabs
    }
}
