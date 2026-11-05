import Foundation
import Testing
@testable import Models

struct CommunityModelsTests {
    private let day = Date(timeIntervalSince1970: 1_793_700_000)

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        try JSONCoding.decoder.decode(T.self, from: JSONCoding.encoder.encode(value))
    }

    private func json(_ value: some Encodable) throws -> String {
        String(bytes: try JSONCoding.encoder.encode(value), encoding: .utf8) ?? ""
    }

    // MARK: Community

    @Test func commentAndLikeRoundTrip() throws {
        let reply = Comment(id: "c2", runID: "r1", authorID: "u1", parentID: "c1", text: "EXAMPLE reply", likeCount: 2,
                            createdAt: day, editedAt: day, deletedAt: nil)
        #expect(try roundTrip(reply) == reply)
        #expect(reply.parentID == "c1")
        for target in [LikeTarget.run("r1"), .comment("c1")] {
            let like = Like(userID: "u1", target: target, createdAt: day)
            #expect(try roundTrip(like) == like)
        }
        #expect(try json(LikeTarget.comment("c1")) == #"{"id":"c1","kind":"comment"}"#)
    }

    @Test func friendRequestIDIsFromAndToAndIsNotStored() throws {
        let request = FriendRequest(fromID: "u1", toID: "u2", createdAt: day, isOther: true)
        #expect(request.id == "u1_u2")
        #expect(try roundTrip(request) == request)
        #expect(try json(request).contains("\"id\"") == false)
        #expect(FriendRequest(fromID: "u2", toID: "u1", createdAt: day).id == "u2_u1")
    }

    @Test func friendshipIsStoredInSortedOrder() throws {
        let one = Friendship("u9", "u1", createdAt: day)
        let other = Friendship("u1", "u9", createdAt: day)
        #expect(one == other && one.userA == "u1" && one.userB == "u9")
        #expect(one.contains("u9") && !one.contains("u5"))
        #expect(try roundTrip(one) == one)
    }

    @Test func blockCreditGuestAndSuggestionRoundTrip() throws {
        let block = Block(blockerID: "u1", blockedID: "u2", createdAt: day)
        #expect(try roundTrip(block) == block)
        let credit = RemixCredit(originalHangoutID: "h1", remixerID: "u2", remixHangoutID: "h2", runID: "r1",
                                 createdAt: day)
        #expect(try roundTrip(credit) == credit)
        let guest = GuestResponse(hangoutID: "h1", displayName: "EXAMPLE Guest", reminderEmail: nil, createdAt: day)
        #expect(try roundTrip(guest) == guest)
        let suggestion = PlaceSuggestion(
            id: "ps1", submitterID: "u1", name: "EXAMPLE Place",
            coordinate: Coordinate(latitude: 18.5, longitude: 73.8), category: .cafe, note: "EXAMPLE",
            photo: Photo(id: "ph1", path: "a.jpg", width: 1, height: 1), status: .approved,
            reviewNote: "EXAMPLE ok", approvedPlaceID: "place-example-cafe-a1b2", createdAt: day, reviewedAt: day)
        #expect(try roundTrip(suggestion) == suggestion)
        #expect(PlaceSuggestionStatus.pending.rawValue == "pending")
    }

    // MARK: Chat

    @Test func conversationsRoundTripAndDirectMessageIDsAreSorted() throws {
        #expect(ConversationID.dm("u2", "u1") == ConversationID.dm("u1", "u2"))
        #expect(ConversationID.dm("u2", "u1") == "dm_u1_u2")
        let chat = Conversation(id: .dm("u1", "u2"), kind: .directMessage, memberIDs: ["u1", "u2"],
                                lastMessage: LastMessagePreview(senderID: "u1", text: "EXAMPLE hi", sentAt: day),
                                createdAt: day)
        #expect(try roundTrip(chat) == chat)
        #expect(try json(ConversationKind.directMessage) == "\"dm\"")
        let group = Conversation(id: "c1", kind: .group, name: "EXAMPLE Crew", adminID: "u1",
                                 memberIDs: ["u1", "u2", "u3"], createdAt: day)
        #expect(try roundTrip(group) == group)
    }

    @Test func membershipRoundTripsAndDefaultsToActive() throws {
        let pending = Membership(conversationID: "c1", userID: "u2", status: .pending, joinedAt: day)
        #expect(pending.role == .member)
        #expect(try roundTrip(pending) == pending)
        let admin = Membership(conversationID: "c1", userID: "u1", role: .admin, joinedAt: day, lastReadAt: day)
        #expect(admin.status == .active)
        #expect(try roundTrip(admin) == admin)
    }

    private static let payloads: [MessagePayload] = [
        .text("EXAMPLE hello"),
        .photos([Photo(id: "ph1", path: "a.jpg", width: 10, height: 10),
                 Photo(id: "ph2", path: "b.jpg", width: 10, height: 10)]),
        .hangout("hangout-example-evening-c3d4"),
        .link(URL(string: "https://example.com/EXAMPLE")!),
        .voice(path: "voice/EXAMPLE.m4a", seconds: 42),
        .poll(question: "EXAMPLE: coffee at 5?")
    ]

    @Test(arguments: payloads)
    func everyPayloadKindRoundTrips(payload: MessagePayload) throws {
        #expect(try roundTrip(payload) == payload)
        let message = Message(id: "m1", conversationID: "c1", senderID: "u1", createdAt: day, payload: payload)
        #expect(try roundTrip(message) == message)
    }

    @Test func payloadsAreObjectsWithAKind() throws {
        #expect(try json(MessagePayload.text("hi")) == #"{"kind":"text","text":"hi"}"#)
        #expect(try json(MessagePayload.hangout("h1")) == #"{"hangoutID":"h1","kind":"hangout"}"#)
        let voice = MessagePayload.voice(path: "v.m4a", seconds: 7)
        #expect(try json(voice) == #"{"kind":"voice","path":"v.m4a","seconds":7}"#)
        #expect(try json(MessagePayload.poll(question: "Q?")) == #"{"kind":"poll","question":"Q?"}"#)
    }

    @Test func aPayloadKindFromANewerAppIsUnsupportedNotAFailure() throws {
        let sticker = Data(#"{"kind":"sticker","id":"x"}"#.utf8)
        #expect(try JSONCoding.decoder.decode(MessagePayload.self, from: sticker) == .unsupported)
        let message = """
        {"id":"m","conversationID":"c","senderID":"u","createdAt":"2026-11-03T10:00:00Z","payload":{"kind":"hologram"}}
        """
        #expect(try JSONCoding.decoder.decode(Message.self, from: Data(message.utf8)).payload == .unsupported)
    }

    @Test func aKnownKindMissingItsFieldIsAnError() {
        #expect(throws: DecodingError.self) {
            try JSONCoding.decoder.decode(MessagePayload.self, from: Data(#"{"kind":"text"}"#.utf8))
        }
    }

    @Test func deletedAndEditedMessagesRoundTrip() throws {
        let message = Message(id: "m1", conversationID: "c1", senderID: "u1", createdAt: day, editedAt: day,
                              deletedAt: day, payload: .text("gone"))
        #expect(try roundTrip(message) == message)
    }

    @Test func pollVotesUseTheTwoFixedChoices() throws {
        #expect(PollChoice.allCases == [.imIn, .notForMe])
        #expect(try json(PollChoice.imIn) == "\"im-in\"")
        let vote = PollVote(messageID: "m1", userID: "u2", choice: .notForMe, votedAt: day)
        #expect(try roundTrip(vote) == vote)
    }

    // MARK: Safety

    /// Every reason in `docs/PRODUCT.md` 4 and the report screen task (SC-R1).
    @Test func reportHasEveryReasonTheProductListsAndMore() {
        let listed: Set<ReportReason> = [
            .spam, .harassment, .hate, .nudity, .violence, .selfHarm, .illegalGoods, .scam, .impersonation,
            .copyright, .photoWithoutConsent, .privateAddress, .unsafePlace, .possiblyUnderage, .other
        ]
        #expect(Set(ReportReason.allCases).subtracting([.unknown]) == listed)
        #expect(ReportReason.allCases.count == 16)
    }

    @Test func nudityViolenceAndSelfHarmHideContentAtOnce() {
        let hiding = ReportReason.allCases.filter(\.hidesContentImmediately)
        #expect(Set(hiding) == [.nudity, .selfHarm, .violence])
    }

    @Test func reasonsUseKebabCaseWordsAndUnknownFallsBack() throws {
        #expect(ReportReason.selfHarm.rawValue == "self-harm")
        #expect(ReportReason.photoWithoutConsent.rawValue == "photo-without-consent")
        #expect(try JSONCoding.decoder.decode(ReportReason.self, from: Data("\"deepfake\"".utf8)) == .unknown)
    }

    @Test func reportUsesTheIDsOnlyReportTarget() throws {
        let report = Report(id: "rep1", reporterID: "u1", target: .comment("c1"), targetOwnerID: "u2",
                            reason: .harassment, detail: "EXAMPLE detail", createdAt: day)
        #expect(report.status == .open)
        #expect(try roundTrip(report) == report)
        #expect(try json(report).contains(#""target":{"id":"c1","kind":"comment"}"#))
        let targets: [ReportTarget] = [
            .run("r1"), .comment("c1"), .user("u1"), .message("m1"), .place("p1"), .hangout("h1")
        ]
        for target in targets {
            let sample = Report(id: "rep", reporterID: "u1", target: target, reason: .other, createdAt: day)
            #expect(try roundTrip(sample).target == target)
        }
        #expect([ReportStatus.open, .actioned, .dismissed].map(\.rawValue) == ["open", "actioned", "dismissed"])
    }

    @Test func activityRoundTripsForEveryKindAndTarget() throws {
        for kind in ActivityKind.allCases where kind != .unknown {
            let activity = Activity(id: "a1", recipientID: "u1", kind: kind, actorID: "u2", target: .run("r1"),
                                    createdAt: day)
            #expect(try roundTrip(activity) == activity)
        }
        for target in [ActivityTarget.run("r1"), .comment("c1"), .user("u1"), .hangout("h1")] {
            let activity = Activity(id: "a1", recipientID: "u1", kind: .like, actorID: "u2", target: target,
                                    createdAt: day, readAt: day)
            #expect(try roundTrip(activity) == activity)
        }
        #expect(try JSONCoding.decoder.decode(ActivityKind.self, from: Data("\"poke\"".utf8)) == .unknown)
        #expect(ActivityKind.friendRequest.rawValue == "friend-request")
    }
}
