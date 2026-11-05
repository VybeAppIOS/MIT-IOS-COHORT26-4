import Foundation
import Models
import Testing
@testable import Core

/// Memberships, muting and pending invitations on the stub chat repository (the rules the screens rely on).
struct ChatMembersStubTests {
    private let myID = SampleSocialData.currentUser.id
    private let crew = SampleSocialData.crew.id
    private let invitation = SampleSocialData.invitation.id

    @Test func everyMemberHasAMembershipWithTheirRoleAndWhoAddedThem() async throws {
        let members = try await StubChatRepository().memberships(in: crew)
        #expect(Set(members.map(\.userID)) == Set(SampleSocialData.crew.memberIDs))
        #expect(members.filter { $0.role == .admin }.map(\.userID) == [myID])
        #expect(members.allSatisfy { $0.status == .active && $0.mutedAt == nil })
        #expect(members.filter { $0.userID != myID }.allSatisfy { $0.addedByID == myID })
    }

    @Test func aPendingGroupStaysOutOfConversationsUntilAccepted() async throws {
        let store = SocialStubStore()
        let chat = StubChatRepository(store: store)
        #expect(try await chat.conversations().contains { $0.id == invitation } == false)
        #expect(try await chat.pendingInvitations().map(\.id) == [invitation])
        #expect(try await chat.unreadCounts()[invitation] == nil)
        await #expect(throws: AppError.notFound) { _ = try await chat.messages(in: invitation).first { _ in true } }
        await #expect(throws: AppError.notFound) { _ = try await chat.send(.text("hi"), in: invitation) }

        try await chat.respondToInvitation(to: invitation, accept: true)
        #expect(try await chat.conversations().contains { $0.id == invitation })
        #expect(try await chat.pendingInvitations().isEmpty)
        await #expect(throws: AppError.notFound) { try await chat.respondToInvitation(to: invitation, accept: true) }
    }

    @Test func theInvitationNamesTheNonFriendWhoAddedMe() async throws {
        let chat = StubChatRepository()
        let mine = try await chat.memberships(in: invitation).first { $0.userID == myID }
        #expect(mine?.status == .pending)
        let adder = try #require(mine?.addedByID)
        #expect(!SampleSocialData.myFriendIDs.contains(adder))
        #expect(adder == SampleSocialData.invitation.adminID)
    }

    @Test func leavingAnInvitationRemovesItAndKeepsTheGroupOutOfMyChats() async throws {
        let chat = StubChatRepository()
        try await chat.respondToInvitation(to: invitation, accept: false)
        #expect(try await chat.pendingInvitations().isEmpty)
        #expect(try await chat.conversations().contains { $0.id == invitation } == false)
    }

    @Test func blockingThePersonWhoAddedMeHidesTheInvitation() async throws {
        let store = SocialStubStore()
        let adder = try #require(SampleSocialData.invitation.adminID)
        try await StubSafetyRepository(store: store).block(adder)
        #expect(try await StubChatRepository(store: store).pendingInvitations().isEmpty)
    }

    @Test func theAdminMutesAndUnmutesAMember() async throws {
        let chat = StubChatRepository()
        let other = SampleSocialData.isha.id
        try await chat.setMuted(true, member: other, in: crew)
        #expect(try await chat.memberships(in: crew).first { $0.userID == other }?.mutedAt != nil)
        try await chat.setMuted(false, member: other, in: crew)
        #expect(try await chat.memberships(in: crew).first { $0.userID == other }?.mutedAt == nil)
    }

    @Test func theAdminCannotBeMutedAndOnlyTheAdminCanMute() async throws {
        let chat = StubChatRepository()
        await #expect(throws: AppError.invalid("The admin cannot be muted.")) {
            try await chat.setMuted(true, member: myID, in: crew)
        }
        await #expect(throws: AppError.notFound) {
            try await chat.setMuted(true, member: SampleSocialData.meera.id, in: crew)
        }
        await #expect(throws: AppError.invalid("This is not a group.")) {
            try await chat.setMuted(true, member: SampleSocialData.friend.id, in: SampleSocialData.friendChat.id)
        }
        // Joined a group somebody else runs: I am not its admin.
        try await chat.respondToInvitation(to: invitation, accept: true)
        await #expect(throws: AppError.invalid("Only the admin can do this.")) {
            try await chat.setMuted(true, member: SampleSocialData.tara.id, in: invitation)
        }
    }

    @Test func aMutedPersonCannotSendButOthersChatsStillWork() async throws {
        let chat = StubChatRepository(store: SocialStubStore(mutedIn: [crew]))
        let mine = try await chat.memberships(in: crew).first { $0.userID == myID }
        #expect(mine?.mutedAt != nil)
        await #expect(throws: AppError.invalid("The admin has muted you in this group.")) {
            _ = try await chat.send(.text("hello"), in: crew)
        }
        _ = try await chat.send(.text("hello"), in: SampleSocialData.friendChat.id)
    }

    @Test func removingAMutedMemberClearsTheirMute() async throws {
        let chat = StubChatRepository()
        let other = SampleSocialData.isha.id
        try await chat.setMuted(true, member: other, in: crew)
        try await chat.remove(other, from: crew)
        try await chat.add([other], to: crew)
        #expect(try await chat.memberships(in: crew).first { $0.userID == other }?.mutedAt == nil)
    }

    @Test func emptyAndFailingModesAnswerLikeTheRestOfTheStub() async throws {
        #expect(try await StubChatRepository(mode: .empty).pendingInvitations().isEmpty)
        await #expect(throws: AppError.offline) { try await StubChatRepository(mode: .failing).pendingInvitations() }
        await #expect(throws: AppError.offline) { try await StubChatRepository(mode: .failing).memberships(in: crew) }
    }
}
