import Core
import Foundation
import Models
import Testing
@testable import ChatFeature

@MainActor
struct GroupInfoViewModelTests {
    private let crew = SampleSocialData.crew.id

    private func makeViewModel(
        chat: (any ChatRepository)? = nil, deps: AppDependencies = .preview(.loaded), group: ConversationID? = nil,
        offline: Bool = false
    ) -> GroupInfoViewModel {
        GroupInfoViewModel(
            conversationID: group ?? crew, chat: chat ?? deps.chat, friends: deps.friends, profiles: deps.profiles,
            session: deps.session, network: offline ? NetworkMonitor(isOffline: true) : deps.network,
            router: deps.router)
    }

    private func member(_ id: UserID, in viewModel: GroupInfoViewModel) -> MemberRowData? {
        content(viewModel)?.members.first { $0.id == id }
    }

    private func content(_ viewModel: GroupInfoViewModel) -> GroupInfoContent? {
        if case .loaded(let content, _) = viewModel.state { content } else { nil }
    }

    @Test func membersShowTheirRolesAndTheAdminCanRemoveOthersButNotThemselves() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let loaded = content(viewModel)
        #expect(loaded?.isAdmin == true)
        #expect(loaded?.members.filter(\.isAdmin).count == 1)
        for member in loaded?.members ?? [] { #expect(member.canRemove == !member.isMe) }
    }

    @Test func aMemberWhoIsNotTheAdminCannotEditOrRemove() async {
        let deps = AppDependencies.preview(.loaded)
        let controlled = ControlledChat(base: deps.chat)
        controlled.adminOverride.withLock { $0 = SampleSocialData.isha.id }
        let viewModel = makeViewModel(chat: controlled, deps: deps)
        await viewModel.load()
        #expect(content(viewModel)?.isAdmin == false)
        #expect(content(viewModel)?.members.allSatisfy { !$0.canRemove } == true)
        viewModel.draftName = "A new name"
        #expect(!viewModel.canSaveName)
    }

    @Test func theAdminRenamesTheGroup() async throws {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        #expect(!viewModel.canSaveName)
        viewModel.draftName = "  "
        #expect(!viewModel.canSaveName)
        viewModel.draftName = "Kothrud Weekenders"
        #expect(viewModel.canSaveName)
        await viewModel.saveNameTapped()
        #expect(content(viewModel)?.name == "Kothrud Weekenders")
    }

    @Test func removingAMemberAsksFirstThenRemoves() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let before = content(viewModel)?.members.count ?? 0
        let other = content(viewModel)?.members.first { !$0.isMe }?.id
        guard let other else { Issue.record("no other member"); return }
        viewModel.removeTapped(other)
        viewModel.cancelRemove()
        await viewModel.confirmRemove()
        #expect(content(viewModel)?.members.count == before)
        viewModel.removeTapped(other)
        await viewModel.confirmRemove()
        #expect(content(viewModel)?.members.count == before - 1)
    }

    @Test func onlyFriendsNotInTheGroupCanBeAdded() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let memberIDs = Set(content(viewModel)?.members.map(\.id) ?? [])
        let addable = content(viewModel)?.addable ?? []
        #expect(addable.allSatisfy { !memberIDs.contains($0.id) })
        guard let pick = addable.first else { return }
        viewModel.togglePick(pick.id)
        await viewModel.confirmAdd()
        #expect(content(viewModel)?.members.contains { $0.id == pick.id } == true)
    }

    @Test func leavingHandsTheAdminRoleToSomeoneElseAndGoesBack() async throws {
        let deps = AppDependencies.preview(.loaded)
        deps.router.open(.groupInfo(crew))
        let viewModel = makeViewModel(deps: deps)
        await viewModel.load()
        await viewModel.confirmLeave()
        let group = try await deps.chat.conversations().first { $0.id == crew }
        #expect(group?.memberIDs.contains(SampleData.signedInUser.id) != true)
        #expect(group?.adminID != SampleData.signedInUser.id)
        #expect(deps.router.path(for: deps.router.currentStack).isEmpty)
    }

    @Test func belowThreeMembersTheGroupIsReadOnly() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let others = content(viewModel)?.members.filter { !$0.isMe }.map(\.id) ?? []
        // Remove members until only two are left (you and one other).
        for id in others.dropFirst() {
            viewModel.removeTapped(id)
            await viewModel.confirmRemove()
        }
        #expect(content(viewModel)?.members.count == 2)
        #expect(content(viewModel)?.isReadOnly == true)
    }

    @Test func aFailedChangeShowsAMessage() async {
        let deps = AppDependencies.preview(.loaded)
        let controlled = ControlledChat(base: deps.chat)
        controlled.failChanges.withLock { $0 = true }
        let viewModel = makeViewModel(chat: controlled, deps: deps)
        await viewModel.load()
        viewModel.draftName = "Another name"
        await viewModel.saveNameTapped()
        #expect(viewModel.notice != nil)
    }

    @Test func tappingAMemberOpensTheirProfileButNotYours() async {
        let deps = AppDependencies.preview(.loaded)
        let viewModel = makeViewModel(deps: deps)
        viewModel.memberTapped(SampleData.signedInUser.id)
        #expect(deps.router.path(for: deps.router.currentStack).isEmpty)
        viewModel.memberTapped(SampleSocialData.isha.id)
        #expect(deps.router.path(for: deps.router.currentStack).last == .profile(SampleSocialData.isha.id))
    }

    @Test func aMissingGroupIsTheEmptyState() async {
        let viewModel = makeViewModel(group: "conversation-gone")
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test func aFailedFirstLoadShowsTheError() async {
        let viewModel = GroupInfoViewModel.preview(.failing)
        await viewModel.load()
        #expect(viewModel.state == .failed(.offline))
    }

    // MARK: Mute, the ••• menu and Add members

    @Test func theAdminHasAMenuOnEveryoneElseAndNotOnThemselves() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        for row in content(viewModel)?.members ?? [] {
            #expect(row.hasMenu == !row.isMe)
            #expect(row.canMute == !row.isMe)
            #expect(row.canRemove == !row.isMe)
        }
    }

    @Test func mutingKeepsThePersonInTheGroupAndTheAdminSeesTheLabel() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let before = content(viewModel)?.members.count
        let other = SampleSocialData.isha.id
        #expect(member(other, in: viewModel)?.isMuted == false)
        #expect(member(other, in: viewModel)?.showsMutedLabel == false)
        await viewModel.muteTapped(other)
        #expect(member(other, in: viewModel)?.isMuted == true)
        #expect(member(other, in: viewModel)?.showsMutedLabel == true)
        #expect(content(viewModel)?.members.count == before)
        #expect(content(viewModel)?.members.filter(\.showsMutedLabel).count == 1)
    }

    @Test func theMenuOffersUnmuteForAMutedPersonAndUnmutingClearsIt() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let other = SampleSocialData.isha.id
        let muteWord = member(other, in: viewModel)?.muteLabel
        await viewModel.muteTapped(other)
        #expect(member(other, in: viewModel)?.muteLabel != muteWord)
        await viewModel.muteTapped(other)
        #expect(member(other, in: viewModel)?.isMuted == false)
        #expect(member(other, in: viewModel)?.muteLabel == muteWord)
    }

    @Test func theAdminCannotMuteThemselves() async {
        let viewModel = makeViewModel()
        await viewModel.load()
        let myID = SampleData.signedInUser.id
        await viewModel.muteTapped(myID)
        #expect(member(myID, in: viewModel)?.isMuted == false)
        #expect(viewModel.notice == nil)
    }

    @Test func aMutedPersonSeesTheLabelOnThemselvesAndNobodyElseDoes() async {
        // I am muted here, and somebody else is the admin.
        let store = SocialStubStore(mutedIn: [crew])
        let controlled = ControlledChat(base: StubChatRepository(store: store))
        controlled.adminOverride.withLock { $0 = SampleSocialData.isha.id }
        let viewModel = makeViewModel(chat: controlled)
        await viewModel.load()
        let myID = SampleData.signedInUser.id
        #expect(member(myID, in: viewModel)?.isMuted == true)
        #expect(member(myID, in: viewModel)?.showsMutedLabel == true)
        #expect(content(viewModel)?.members.filter(\.showsMutedLabel).map(\.id) == [myID])
        #expect(content(viewModel)?.members.allSatisfy { !$0.hasMenu } == true)
    }

    @Test func aMemberWhoIsNotTheAdminDoesNotSeeWhoElseIsMuted() async throws {
        let store = SocialStubStore()
        let base = StubChatRepository(store: store)
        try await base.setMuted(true, member: SampleSocialData.isha.id, in: crew)   // done as the admin
        let controlled = ControlledChat(base: base)
        controlled.adminOverride.withLock { $0 = SampleSocialData.friend.id }       // now somebody else is the admin
        let viewModel = makeViewModel(chat: controlled)
        await viewModel.load()
        #expect(member(SampleSocialData.isha.id, in: viewModel)?.isMuted == true)
        #expect(content(viewModel)?.members.allSatisfy { !$0.showsMutedLabel } == true)
    }

    @Test func everyMemberCanAddMembersButNotOffline() async {
        let controlled = ControlledChat(base: AppDependencies.preview(.loaded).chat)
        controlled.adminOverride.withLock { $0 = SampleSocialData.isha.id }
        let viewModel = makeViewModel(chat: controlled)
        await viewModel.load()
        #expect(content(viewModel)?.isAdmin == false)
        #expect(viewModel.canAdd)
        viewModel.addTapped()
        #expect(viewModel.isAddingMembers)

        let offline = makeViewModel(offline: true)
        await offline.load()
        #expect(!offline.canAdd)
        offline.addTapped()
        #expect(!offline.isAddingMembers)
    }

    @Test func offlineTheAdminCannotRemoveMuteOrRename() async {
        let viewModel = makeViewModel(offline: true)
        await viewModel.load()
        let other = SampleSocialData.isha.id
        #expect(!viewModel.canAdminister)
        viewModel.removeTapped(other)
        #expect(viewModel.removingID == nil)
        await viewModel.muteTapped(other)
        #expect(member(other, in: viewModel)?.isMuted == false)
        viewModel.draftName = "Another name"
        #expect(!viewModel.canSaveName)
    }

    @Test func aFailedMuteShowsAMessageAndKeepsTheList() async {
        let deps = AppDependencies.preview(.loaded)
        let controlled = ControlledChat(base: deps.chat)
        let viewModel = makeViewModel(chat: controlled, deps: deps)
        await viewModel.load()
        controlled.failChanges.withLock { $0 = true }
        let before = content(viewModel)?.members
        await viewModel.muteTapped(SampleSocialData.isha.id)
        #expect(viewModel.notice != nil)
        #expect(content(viewModel)?.members == before)
    }
}
