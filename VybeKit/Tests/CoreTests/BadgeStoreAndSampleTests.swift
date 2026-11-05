import Foundation
import Models
import Testing
@testable import Core

@MainActor
struct BadgeStoreTests {
    private func store(_ mode: StubMode = .loaded) -> (BadgeStore, SocialStubStore) {
        let social = SocialStubStore()
        let badges = BadgeStore(chat: StubChatRepository(mode: mode, store: social),
                                feed: StubFeedRepository(mode: mode, store: social),
                                friends: StubFriendsRepository(mode: mode, store: social))
        return (badges, social)
    }

    @Test func countsComeFromChatActivityAndRequests() async {
        let (badges, _) = store()
        #expect(badges.communityBadge == 0)
        await badges.refresh()
        #expect(badges.unreadChatCount == 4)       // 2 in the friend chat, 2 in the crew chat
        #expect(badges.unseenActivityCount == 3)   // the sample has 3 unread of 6
        #expect(badges.pendingRequestCount == 1)   // the "Other" folder does not count
        #expect(badges.communityBadge == 8)
    }

    @Test func readingThingsLowersTheCounts() async throws {
        let (badges, social) = store()
        await badges.refresh()
        try await StubChatRepository(store: social).markRead(SampleSocialData.crew.id)
        try await StubFeedRepository(store: social).markActivityRead()
        await badges.refresh()
        #expect(badges.unreadChatCount == 2 && badges.unseenActivityCount == 0)
    }

    @Test func screensCanLowerTheCountsAtOnce() async {
        let (badges, _) = store()
        await badges.refresh()
        badges.activityWasSeen()
        badges.chatWasRead(unread: 3)
        #expect(badges.unseenActivityCount == 0 && badges.unreadChatCount == 1)
        badges.chatWasRead(unread: 99)
        #expect(badges.unreadChatCount == 0)
    }

    @Test func oneFailingSourceDoesNotStopTheOthers() async {
        let social = SocialStubStore()
        let badges = BadgeStore(chat: StubChatRepository(store: social), feed: StubFeedRepository(mode: .failing),
                                friends: StubFriendsRepository(store: social))
        await badges.refresh()
        #expect(badges.unreadChatCount == 4 && badges.pendingRequestCount == 1)
        #expect(badges.unseenActivityCount == 0)   // its load failed, so it keeps its previous value (0)
    }

    @Test func everySourceFailingLeavesZeros() async {
        let (badges, _) = store(.failing)
        await badges.refresh()
        #expect(badges.communityBadge == 0)
    }

    @Test func emptyModeGivesZero() async {
        let (badges, _) = store(.empty)
        await badges.refresh()
        #expect(badges.communityBadge == 0)
    }
}

struct SampleSocialDataTests {
    @Test func itHasThePeoplePostsChatsAndReportsTheTaskAsks() {
        #expect(SampleSocialData.people.count == 12)
        #expect(Set(SampleSocialData.people.map(\.id)).count == 12)
        #expect(SampleSocialData.posts.count == 8)
        #expect(SampleSocialData.posts.filter { $0.runnerID == SampleSocialData.vybe.id }.count == 2)
        #expect(SampleSocialData.conversations.count == 3)
        #expect(SampleSocialData.conversations.filter { $0.kind == .group }.count == 1)
        #expect(!SampleSocialData.comments.isEmpty && SampleSocialData.comments.contains { $0.parentID != nil })
        #expect(SampleSocialData.reports.count >= 2)
    }

    @Test func everythingIsClearlySampleAndPointsAtRealSamples() {
        let ids = Set(SampleSocialData.people.map(\.id))
        for person in SampleSocialData.people where person.id != SampleSocialData.vybe.id {
            #expect(person.username.hasPrefix("sample.") && person.displayName.hasPrefix("Sample "))
        }
        #expect(SampleSocialData.posts.allSatisfy { ids.contains($0.runnerID) })
        #expect(SampleSocialData.comments.allSatisfy { ids.contains($0.authorID) })
        #expect(SampleSocialData.messages.allSatisfy { ids.contains($0.senderID) })
        let runIDs = Set(SampleSocialData.posts.map(\.id))
        #expect(SampleSocialData.comments.allSatisfy { runIDs.contains($0.runID) })
        let commentIDs = Set(SampleSocialData.comments.map(\.id))
        #expect(SampleSocialData.comments.compactMap(\.parentID).allSatisfy { commentIDs.contains($0) })
        let chatIDs = Set(SampleSocialData.conversations.map(\.id))
        #expect(SampleSocialData.messages.allSatisfy { chatIDs.contains($0.conversationID) })
    }

    @Test func messagesCoverEveryPayloadKindThePreviewsNeed() {
        let kinds = Set(SampleSocialData.messages.map { message -> String in
            switch message.payload {
            case .text: "text"
            case .photos: "photos"
            case .hangout: "hangout"
            case .link: "link"
            case .voice: "voice"
            case .poll: "poll"
            case .unsupported: "unsupported"
            }
        })
        #expect(kinds == ["text", "photos", "hangout", "link", "voice", "poll"])
    }
}
