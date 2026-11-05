import Core
import Foundation
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct PrivacyViewModelTests {
    private func make(_ mode: StubMode = .loaded) -> (PrivacyViewModel, AppDependencies) {
        let deps = AppDependencies.preview(mode)
        return (PrivacyViewModel(profiles: deps.profiles, session: deps.session, network: deps.network), deps)
    }

    @Test func loadsMyProfileWithTheSafeDefaults() async {
        let (viewModel, _) = make()
        await viewModel.load()
        let settings = viewModel.profile?.settings
        #expect(settings?.defaultAudience == .friends)
        #expect(settings?.whoCanComment == .friends)
        #expect(settings?.whoCanAddMeToGroups == .askMe)
        #expect(viewModel.isPrivate == false)
    }

    @Test func aFirstLoadThatFailsShowsTheError() async {
        let (viewModel, _) = make(.failing)
        await viewModel.load()
        if case .failed = viewModel.state {} else { Issue.record("expected the failed state") }
    }

    @Test func everyMenuListsEveryPolicy() {
        let (viewModel, _) = make()
        #expect(viewModel.commentChoices.map(\.value) == CommentPolicy.allCases)
        #expect(viewModel.requestChoices.map(\.value) == FriendRequestPolicy.allCases)
        #expect(viewModel.groupChoices.map(\.value) == GroupAddPolicy.allCases)
        #expect(viewModel.audienceChoices.map(\.value) == [.friends, .public])
    }

    @Test func aChangeIsShownAndKeptInTheSession() async {
        let (viewModel, deps) = make()
        await viewModel.load()
        await viewModel.setComment(.nobody)
        #expect(viewModel.profile?.settings.whoCanComment == .nobody)
        #expect(deps.session.currentUser?.settings.whoCanComment == .nobody)
        #expect(viewModel.saveFailed == false)
    }

    @Test func choosingEveryoneForNewPostsShowsAWarning() async {
        let (viewModel, _) = make()
        await viewModel.load()
        #expect(viewModel.showsPublicWarning == false)
        await viewModel.setAudience(.public)
        #expect(viewModel.showsPublicWarning)
    }

    @Test func aPrivateProfileForcesFriendsOnlyAndLocksTheAudienceMenu() async {
        let (viewModel, _) = make()
        await viewModel.load()
        await viewModel.setAudience(.public)
        await viewModel.setPrivate(true)
        #expect(viewModel.isPrivate)
        #expect(viewModel.profile?.settings.defaultAudience == .friends)
        #expect(viewModel.canChangeAudience == false)
        #expect(viewModel.showsPublicWarning == false)
        await viewModel.setAudience(.public)
        #expect(viewModel.profile?.settings.defaultAudience == .friends)
    }

    @Test func hidingMyselfFromSearchIsSaved() async {
        let (viewModel, _) = make()
        await viewModel.load()
        await viewModel.setShowInSearch(false)
        #expect(viewModel.profile?.settings.showMeInSearch == false)
    }
}
