import Core
import Models
import Testing
@testable import ProfileFeature

@MainActor
struct EditProfileViewModelTests {
    private func make(_ mode: StubMode = .loaded) -> (viewModel: EditProfileViewModel, deps: AppDependencies) {
        let deps = AppDependencies.preview(mode)
        let viewModel = EditProfileViewModel(profile: SampleData.signedInUser, profiles: deps.profiles,
                                             auth: deps.auth, session: deps.session)
        return (viewModel, deps)
    }

    @Test(arguments: [("sample.me2", true), ("ab", false), ("has space", false), ("UPPER", true),
                      (".dot", false), ("dot.", false), ("two..dots", false), ("under_score", true),
                      (String(repeating: "a", count: 31), false)])
    func usernameRules(value: String, valid: Bool) {
        #expect((EditProfileViewModel.usernameProblem(value.lowercased()) == nil) == valid)
    }

    @Test func theBioLimitIs150() {
        let (viewModel, _) = make()
        viewModel.bio = String(repeating: "a", count: 150)
        #expect(viewModel.bioError == nil)
        viewModel.bio += "a"
        #expect(viewModel.bioError != nil && !viewModel.canSave)
    }

    @Test func atLeastThreeInterests() {
        let (viewModel, _) = make()
        for option in viewModel.interestOptions where viewModel.isSelected(option) { viewModel.toggleInterest(option) }
        viewModel.toggleInterest(viewModel.interestOptions[0])
        viewModel.toggleInterest(viewModel.interestOptions[1])
        #expect(viewModel.interestsError != nil && !viewModel.canSave)
        viewModel.toggleInterest(viewModel.interestOptions[2])
        #expect(viewModel.interestsError == nil)
    }

    @Test func nothingChangedMeansSaveIsOffAndCloseNeedsNoConfirm() {
        let (viewModel, _) = make()
        #expect(!viewModel.hasChanges && !viewModel.canSave)
        #expect(viewModel.closeTapped())
    }

    @Test func closingWithChangesAsksFirst() {
        let (viewModel, _) = make()
        viewModel.name = "Sample Me Again"
        #expect(!viewModel.closeTapped())
        #expect(viewModel.isConfirmingDiscard)
    }

    @Test func changingTheUsernameShowsTheThirtyDayHold() {
        let (viewModel, _) = make()
        #expect(viewModel.usernameHoldNote == nil)
        viewModel.username = "sample.me.new"
        #expect(viewModel.usernameHoldNote != nil)
    }

    @Test func aTakenUsernameIsRefusedAndNothingIsSaved() async {
        let (viewModel, deps) = make()
        selectThreeInterests(viewModel)
        viewModel.username = SampleSocialData.isha.username
        await viewModel.save()
        #expect(viewModel.usernameError != nil)
        #expect(deps.session.currentUser?.username == SampleData.signedInUser.username)
    }

    @Test func savingUpdatesTheSessionAndCloses() async {
        let (viewModel, deps) = make()
        selectThreeInterests(viewModel)
        viewModel.name = "  Sample Me Again  "
        viewModel.bio = "EXAMPLE chai and treks"
        await viewModel.save()
        #expect(viewModel.isSaved)
        #expect(deps.session.currentUser?.displayName == "Sample Me Again")
        #expect(deps.session.currentUser?.bio == "EXAMPLE chai and treks")
    }

    @Test func aFailedSaveKeepsWhatWasTyped() async {
        let (viewModel, _) = make(.failing)
        selectThreeInterests(viewModel)
        viewModel.name = "Sample Me Again"
        await viewModel.save()
        #expect(viewModel.hasFailed && viewModel.name == "Sample Me Again")
    }

    private func selectThreeInterests(_ viewModel: EditProfileViewModel) {
        for option in viewModel.interestOptions.prefix(3) where !viewModel.isSelected(option) {
            viewModel.toggleInterest(option)
        }
    }
}
