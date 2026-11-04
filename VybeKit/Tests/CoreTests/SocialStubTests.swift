import Foundation
import Models
import Testing
@testable import Core

private let myID = SampleSocialData.currentUser.id

struct SocialContractTests {
    @Test func feedStubKeepsTheContract() async throws {
        try await FeedRepositoryContract.verify(StubFeedRepository())
    }

    @Test func friendsStubKeepsTheContract() async throws {
        try await FriendsRepositoryContract.verify(StubFriendsRepository(), myID: myID)
    }

    @Test func chatStubKeepsTheContract() async throws {
        try await ChatRepositoryContract.verify(StubChatRepository(), myID: myID)
    }

    @Test func safetyStubKeepsTheContract() async throws {
        let victim = SampleSocialData.tara.id
        try await SafetyRepositoryContract.verify(StubSafetyRepository(), reporter: myID, victim: victim)
    }

    @Test func contractsAcceptTheEmptyMode() async throws {
        try await FeedRepositoryContract.verify(StubFeedRepository(mode: .empty))
        try await ChatRepositoryContract.verify(StubChatRepository(mode: .empty), myID: myID)
    }
}

struct SocialStubModeTests {
    @Test func everyStubSupportsLoadedEmptyFailingAndNeverReturns() async throws {
        #expect(try await StubFeedRepository(mode: .loaded).trending().count == 4)
        #expect(try await StubFeedRepository(mode: .empty).trending().isEmpty)
        await #expect(throws: AppError.offline) { try await StubFeedRepository(mode: .failing).trending() }
        await #expect(throws: AppError.offline) { try await StubFriendsRepository(mode: .failing).friends() }
        await #expect(throws: AppError.offline) { try await StubChatRepository(mode: .failing).conversations() }
        await #expect(throws: AppError.offline) { try await StubSafetyRepository(mode: .failing).blocked() }
        await #expect(throws: AppError.offline) { try await StubAdminRepository(mode: .failing).reports() }
        await #expect(throws: AppError.offline) { try await StubAuthRepository(mode: .failing).signOut() }

        let task = Task { try await StubFeedRepository(mode: .neverReturns).trending() }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func emptyModeAnswersWithNothingAndMissingItemsAreNotFound() async throws {
        #expect(try await StubFriendsRepository(mode: .empty).requests() == FriendRequests())
        #expect(try await StubChatRepository(mode: .empty).unreadCounts().isEmpty)
        await #expect(throws: AppError.notFound) { try await StubFeedRepository(mode: .empty).post(id: "run-sample-1") }
    }

    @Test func theChatStreamFollowsTheMode() async throws {
        for try await list in StubChatRepository(mode: .empty).messages(in: SampleSocialData.crew.id) {
            #expect(list.isEmpty)
            break
        }
        do {
            for try await _ in StubChatRepository(mode: .failing).messages(in: SampleSocialData.crew.id) {}
            Issue.record("expected the stream to fail")
        } catch {
            #expect(error as? AppError == .offline)
        }
    }
}

struct SocialBehaviourTests {
    private func firstList(_ chat: StubChatRepository, _ id: ConversationID) async throws -> [Message] {
        for try await list in chat.messages(in: id) { return list }
        return []
    }

    @Test func feedShowsFriendsFirstThenNewestInPages() async throws {
        let feed = StubFeedRepository()
        let first = try await feed.feed(after: nil)
        #expect(first.items.count == 3 && first.nextCursor == "3")
        let order = first.items.map(\.runnerID)
        #expect(order.first == SampleSocialData.vybe.id || order.first == SampleSocialData.friend.id)
        await #expect(throws: AppError.self) { try await feed.feed(after: "999") }
    }

    @Test func friendsOnlyPostsOfStrangersAreHidden() async throws {
        let feed = StubFeedRepository()
        let all = try await feed.feed(after: nil).items + (try await feed.feed(after: "3").items)
        // Post 7 is friends-only by Kabir, who is not my friend.
        #expect(!all.contains { $0.id == "run-sample-7" })
        await #expect(throws: AppError.notFound) { try await feed.post(id: "run-sample-7") }
    }

    @Test func blockingHidesAPersonEverywhere() async throws {
        let store = SocialStubStore()
        let feed = StubFeedRepository(store: store)
        let friends = StubFriendsRepository(store: store)
        let safety = StubSafetyRepository(store: store)
        let aarav = SampleSocialData.aarav.id
        #expect(try await friends.friends().contains { $0.id == aarav })

        try await safety.block(aarav)
        #expect(try await friends.friends().contains { $0.id == aarav } == false)
        await #expect(throws: AppError.notFound) { try await feed.post(id: "run-sample-4") }
        // The chat stays; only the blocked person's messages hide.
        #expect(try await StubChatRepository(store: store).conversations().count == 3)
        let messages = try await firstList(StubChatRepository(store: store), SampleSocialData.crew.id)
        #expect(!messages.contains { $0.senderID == aarav })
        await #expect(throws: AppError.self) { try await friends.sendRequest(to: aarav) }

        try await safety.unblock(aarav)
        // Unblocking does not bring the friendship back: they are a stranger again, so they show as a suggestion.
        #expect(try await friends.friends().contains { $0.id == aarav } == false)
        #expect(try await friends.suggestions().contains { $0.id == aarav })
    }

    @Test func reportingNudityHidesItAtOnceButHarassmentDoesNot() async throws {
        let store = SocialStubStore()
        let safety = StubSafetyRepository(store: store)
        let feed = StubFeedRepository(store: store)
        _ = try await safety.report(.comment("comment-sample-1"), reason: .harassment, detail: nil)
        #expect(try await feed.comments(for: "run-sample-1", after: nil).items.contains { $0.id == "comment-sample-1" })
        _ = try await safety.report(.comment("comment-sample-1"), reason: .nudity, detail: nil)
        let afterNudity = try await feed.comments(for: "run-sample-1", after: nil).items
        #expect(afterNudity.contains { $0.id == "comment-sample-1" } == false)
        _ = try await safety.report(.run("run-sample-4"), reason: .selfHarm, detail: nil)
        await #expect(throws: AppError.notFound) { try await feed.post(id: "run-sample-4") }
    }

    @Test func reportsNameTheOwnerOfTheReportedThing() async throws {
        let filed = try await StubSafetyRepository().report(.comment("comment-sample-3"), reason: .spam, detail: nil)
        #expect(filed.targetOwnerID == SampleSocialData.isha.id && filed.status == .open)
    }

    @Test func commentsStayThreadedAndCountsMove() async throws {
        let feed = StubFeedRepository()
        let reply = try await feed.addComment(to: "run-sample-1", text: "EXAMPLE reply", replyingTo: "comment-sample-1")
        #expect(reply.parentID == "comment-sample-1")
        #expect(try await feed.post(id: "run-sample-1").commentCount == 4)
        await #expect(throws: AppError.notFound) {
            try await feed.addComment(to: "run-sample-1", text: "x", replyingTo: "comment-missing")
        }
        await #expect(throws: AppError.invalid("You can only delete your own comments.")) {
            try await feed.deleteComment("comment-sample-1")
        }
        try await feed.deleteComment("comment-sample-4")   // mine, on a friend's post
    }

    @Test func friendRequestsAreAcceptedIntoFriendships() async throws {
        let friends = StubFriendsRepository()
        let requests = try await friends.requests()
        #expect(requests.received.map(\.fromID) == [SampleSocialData.sanya.id])
        #expect(requests.other.map(\.fromID) == [SampleSocialData.tara.id] && requests.other.allSatisfy(\.isOther))
        try await friends.acceptRequest(from: SampleSocialData.tara.id)   // from the "Other" folder
        #expect(try await friends.friends().contains { $0.id == SampleSocialData.tara.id })
        #expect(try await friends.requests().other.isEmpty)
    }

    @Test func chatsListNewestFirstWithUnreadCounts() async throws {
        let chat = StubChatRepository()
        let list = try await chat.conversations()
        #expect(list.count == 3)
        let newestFirst = list.compactMap { $0.lastMessage?.sentAt }
        #expect(newestFirst == newestFirst.sorted(by: >))
        #expect(list.allSatisfy { $0.lastMessage != nil })
        let unread = try await chat.unreadCounts()
        #expect(unread[SampleSocialData.crew.id] == 2 && unread[SampleSocialData.friendChat.id] == 2)
        #expect(unread[SampleSocialData.aaravChat.id] == 0)
    }

    @Test func sendingReachesEveryListener() async throws {
        let store = SocialStubStore()
        let chat = StubChatRepository(store: store)
        let crew = SampleSocialData.crew.id
        var iterator = chat.messages(in: crew).makeAsyncIterator()
        let initial = try await iterator.next()
        #expect(initial?.count == 4)
        let sent = try await chat.send(.text("EXAMPLE hello crew"), in: crew)
        let updated = try await iterator.next()
        #expect(updated?.last?.id == sent.id && updated?.count == 5)
    }

    @Test func pollsHaveOneVoteEach() async throws {
        let chat = StubChatRepository()
        try await chat.vote(.notForMe, on: "message-sample-7")   // I had voted "I'm in"
        let votes = try await chat.votes(for: "message-sample-7")
        #expect(votes.count == 2)
        #expect(votes.first { $0.userID == myID }?.choice == .notForMe)
        await #expect(throws: AppError.invalid("That message is not a poll.")) {
            try await chat.vote(.imIn, on: "message-sample-6")
        }
    }

    @Test func groupRules() async throws {
        let chat = StubChatRepository()
        let aarav = SampleSocialData.aarav.id
        let isha = SampleSocialData.isha.id
        await #expect(throws: AppError.invalid("A group needs at least 3 people.")) {
            try await chat.createGroup(name: "EXAMPLE", members: [aarav])
        }
        await #expect(throws: AppError.invalid("Give the group a name.")) {
            try await chat.createGroup(name: "  ", members: [aarav, isha])
        }
        let group = try await chat.createGroup(name: "EXAMPLE New Group", members: [aarav, isha])
        #expect(group.kind == .group && group.adminID == myID && group.memberIDs == [myID, aarav, isha])

        try await chat.rename(group.id, to: "EXAMPLE Renamed")
        try await chat.add([SampleSocialData.rohan.id], to: group.id)
        try await chat.remove(aarav, from: group.id)
        await #expect(throws: AppError.invalid("Use Leave to leave the group.")) {
            try await chat.remove(myID, from: group.id)
        }
        try await chat.leave(group.id)
        #expect(try await chat.conversations().contains { $0.id == group.id } == false)
    }

    @Test func leavingPassesTheAdminRoleOn() async throws {
        let store = SocialStubStore()
        try await StubChatRepository(store: store).leave(SampleSocialData.crew.id)
        let admin = await store.conversations.first { $0.id == SampleSocialData.crew.id }?.adminID
        #expect(admin == SampleSocialData.friend.id)
        await #expect(throws: AppError.invalid("This is not a group.")) {
            try await StubChatRepository().leave(SampleSocialData.friendChat.id)
        }
    }

    @Test func startingAChatIsIdempotent() async throws {
        let chat = StubChatRepository()
        let existing = try await chat.startChat(with: SampleSocialData.friend.id)
        #expect(existing.id == SampleSocialData.friendChat.id)
        let created = try await chat.startChat(with: SampleSocialData.meera.id)
        #expect(created.id == .dm(myID, SampleSocialData.meera.id))
        #expect(try await chat.startChat(with: SampleSocialData.meera.id) == created)
    }

    @Test func aMessageArrivesAfterTwoSecondsWhenSimulated() async throws {
        let chat = StubChatRepository(store: SocialStubStore(simulateIncomingMessages: true))
        var iterator = chat.messages(in: SampleSocialData.friendChat.id).makeAsyncIterator()
        let start = Date()
        let initial = try await iterator.next()
        let arrived = try await iterator.next()
        #expect(arrived?.count == (initial?.count ?? 0) + 1)
        #expect(arrived?.last?.payload == .text("EXAMPLE incoming message"))
        #expect(Date().timeIntervalSince(start) >= 1.9)
    }
}

struct AuthAndAdminStubTests {
    @Test func emailSignInNeedsTheRightCode() async throws {
        let auth = StubAuthRepository()
        try await auth.sendEmailCode(to: "sample@example.com")
        await #expect(throws: AppError.invalid("Enter a valid email address.")) {
            try await auth.sendEmailCode(to: "nope")
        }
        await #expect(throws: AppError.invalid("That code is not right.")) {
            try await auth.verifyEmailCode("000000", email: "sample@example.com")
        }
        #expect(try await auth.verifyEmailCode("123456", email: "sample@example.com") == SampleSocialData.currentUser)
    }

    @Test func accountBasicsAreChecked() async throws {
        let auth = StubAuthRepository()
        let birthday = Date(timeIntervalSince1970: 0)
        #expect(try await auth.isUsernameAvailable("sample.aarav") == false)
        #expect(try await auth.isUsernameAvailable("brand.new"))
        await #expect(throws: AppError.invalid("You must be 18 or older to use Vybe.")) {
            try await auth.completeAccount(username: "brand.new", dateOfBirth: birthday, confirmed18: false)
        }
        await #expect(throws: AppError.invalid("That username is taken.")) {
            try await auth.completeAccount(username: "Sample.Aarav", dateOfBirth: birthday, confirmed18: true)
        }
        await #expect(throws: AppError.self) {
            try await auth.completeAccount(username: "no spaces!", dateOfBirth: birthday, confirmed18: true)
        }
        let created = try await auth.completeAccount(username: "Brand.New", dateOfBirth: birthday, confirmed18: true)
        #expect(created.username == "brand.new")
    }

    @Test func adminListsReportsAndReviewsSuggestions() async throws {
        let admin = StubAdminRepository()
        #expect(try await admin.reports().map(\.id).first == "report-sample-1")
        try await admin.setStatus(.dismissed, for: "report-sample-1")
        #expect(try await admin.reports().first { $0.id == "report-sample-1" }?.status == .dismissed)
        await #expect(throws: AppError.notFound) { try await admin.setStatus(.actioned, for: "nope") }

        let pending = try await admin.placeSuggestions()
        #expect(pending.first?.status == .pending)
        await #expect(throws: AppError.invalid("Add a note.")) {
            try await admin.reject("suggestion-sample-1", note: " ")
        }
        try await admin.reject("suggestion-sample-1", note: "EXAMPLE: a home address")
        try await admin.approve("suggestion-sample-2", as: SampleData.park)
        let reviewed = try await admin.placeSuggestions()
        #expect(reviewed.first { $0.id == "suggestion-sample-2" }?.approvedPlaceID == SampleData.park.id)
        #expect(reviewed.first { $0.id == "suggestion-sample-1" }?.status == .rejected)
    }

    @Test func adminCanBanAndFindPeople() async throws {
        let store = SocialStubStore()
        let admin = StubAdminRepository(store: store)
        #expect(try await admin.user(username: "Sample.Sanya").id == SampleSocialData.sanya.id)
        await #expect(throws: AppError.notFound) { try await admin.user(username: "nobody") }
        try await admin.ban(SampleSocialData.sanya.id)
        await #expect(throws: AppError.notFound) { try await StubFeedRepository(store: store).post(id: "run-sample-6") }
        try await admin.unban(SampleSocialData.sanya.id)
        #expect(try await StubFeedRepository(store: store).post(id: "run-sample-6").id == "run-sample-6")
    }
}
