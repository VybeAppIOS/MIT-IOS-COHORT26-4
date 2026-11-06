#if DEBUG
import Foundation

/// Fake social data for previews and tests (task F-7). Every person, post, comment and chat is made up: names start
/// with "Sample", usernames are `sample.<name>`, and nothing refers to a real person (`AGENTS.md` 4).
/// Places and Hangouts come from `SampleData` (EXAMPLE values).
public enum SampleSocialData {
    private static var day: Date { SampleData.day }
    private static func hours(_ amount: Double) -> Date { day.addingTimeInterval(amount * 3600) }

    private static func person(_ name: String, friends: Int, isPrivate: Bool = false) -> UserProfile {
        UserProfile(
            id: UserID("user-sample-\(name.lowercased())"), username: "sample.\(name.lowercased())",
            displayName: "Sample \(name)", bio: "EXAMPLE bio, Kothrud", isPrivate: isPrivate,
            interests: ["cafes", "treks"], friendCount: friends, createdAt: day)
    }

    public static let currentUser = SampleData.signedInUser
    public static let vybe = SampleData.vybeTeam
    public static let friend = SampleData.friend
    public static let aarav = person("Aarav", friends: 8)
    public static let isha = person("Isha", friends: 12)
    public static let rohan = person("Rohan", friends: 5)
    public static let meera = person("Meera", friends: 9)
    public static let kabir = person("Kabir", friends: 3, isPrivate: true)
    public static let sanya = person("Sanya", friends: 14)
    public static let vihaan = person("Vihaan", friends: 6)
    public static let tara = person("Tara", friends: 2)
    public static let neel = person("Neel", friends: 7)

    /// 12 people: currentUser, the Vybe account and 10 sample friends and strangers.
    public static let people: [UserProfile] = [
        currentUser, vybe, friend, aarav, isha, rohan, meera, kabir, sanya, vihaan, tara, neel
    ]

    /// Who I am friends with.
    public static let myFriendIDs: [UserID] = [friend.id, aarav.id, isha.id, rohan.id, meera.id]

    // MARK: Posts (8, including 2 Picks from the Vybe account)

    private struct PostSpec {
        var number: Int
        var runner: UserProfile
        var hangout: Hangout
        var hoursAgo: Double
        var likes: Int
        var comments: Int
        var audience: Visibility = .friends
    }

    private static func post(_ spec: PostSpec) -> HangoutRun {
        let hangout = spec.hangout
        return HangoutRun(
            id: RunID("run-sample-\(spec.number)"), hangoutID: hangout.id, runnerID: spec.runner.id, state: .posted,
            visits: hangout.spots.enumerated().map { Visit(spotID: $1.id, placeID: $1.placeID, order: $0 + 1) },
            durationMinutes: hangout.estimatedMinutes, caption: "EXAMPLE caption", tags: hangout.tags,
            visibility: spec.audience, audience: spec.audience,
            card: RunCardCopy(hangoutTitle: hangout.title, totalSpots: hangout.spots.count,
                              budgetPerPerson: hangout.budgetPerPerson, runnerUsername: spec.runner.username,
                              runnerDisplayName: spec.runner.displayName),
            likeCount: spec.likes, commentCount: spec.comments, postedAt: hours(-spec.hoursAgo))
    }

    public static let posts: [HangoutRun] = [
        post(PostSpec(number: 1, runner: vybe, hangout: SampleData.evening, hoursAgo: 2, likes: 24, comments: 3,
                      audience: .public)),
        post(PostSpec(number: 2, runner: vybe, hangout: SampleData.evening, hoursAgo: 30, likes: 40, comments: 0,
                      audience: .public)),
        post(PostSpec(number: 3, runner: friend, hangout: SampleData.morning, hoursAgo: 5, likes: 6, comments: 2)),
        post(PostSpec(number: 4, runner: aarav, hangout: SampleData.evening, hoursAgo: 8, likes: 3, comments: 0)),
        post(PostSpec(number: 5, runner: isha, hangout: SampleData.morning, hoursAgo: 12, likes: 9, comments: 1)),
        post(PostSpec(number: 6, runner: sanya, hangout: SampleData.evening, hoursAgo: 20, likes: 15, comments: 0,
                      audience: .public)),
        post(PostSpec(number: 7, runner: kabir, hangout: SampleData.morning, hoursAgo: 26, likes: 1, comments: 0)),
        post(PostSpec(number: 8, runner: neel, hangout: SampleData.evening, hoursAgo: 50, likes: 11, comments: 0,
                      audience: .public))
    ]

    // MARK: Comments (threads on posts 1, 3 and 5)

    private static func comment(
        _ number: Int, run: Int, by author: UserProfile, _ text: String, reply parent: Int? = nil, hoursAgo: Double,
        likes: Int = 0
    ) -> Comment {
        Comment(id: CommentID("comment-sample-\(number)"), runID: RunID("run-sample-\(run)"), authorID: author.id,
                parentID: parent.map { CommentID("comment-sample-\($0)") }, text: text, likeCount: likes,
                createdAt: hours(-hoursAgo))
    }

    public static let comments: [Comment] = [
        comment(1, run: 1, by: friend, "EXAMPLE comment: looks fun!", hoursAgo: 1.5, likes: 2),
        comment(2, run: 1, by: aarav, "EXAMPLE reply", reply: 1, hoursAgo: 1.2),
        comment(3, run: 1, by: isha, "EXAMPLE comment: which Spot was best?", hoursAgo: 1),
        comment(4, run: 3, by: currentUser, "EXAMPLE comment", hoursAgo: 4),
        comment(5, run: 3, by: rohan, "EXAMPLE reply", reply: 4, hoursAgo: 3.5),
        comment(6, run: 5, by: meera, "EXAMPLE comment", hoursAgo: 11)
    ]

    // MARK: Friend requests and suggestions

    public static let receivedRequests = [FriendRequest(fromID: sanya.id, toID: currentUser.id, createdAt: hours(-3))]
    public static let otherRequests = [
        FriendRequest(fromID: tara.id, toID: currentUser.id, createdAt: hours(-20), isOther: true)
    ]
    public static let sentRequests = [FriendRequest(fromID: currentUser.id, toID: neel.id, createdAt: hours(-30))]

    // MARK: Chats (3, including 1 group)

    public static let friendChat = Conversation(
        id: .dm(currentUser.id, friend.id), kind: .directMessage, memberIDs: [currentUser.id, friend.id],
        createdAt: hours(-72))
    public static let aaravChat = Conversation(
        id: .dm(currentUser.id, aarav.id), kind: .directMessage, memberIDs: [currentUser.id, aarav.id],
        createdAt: hours(-48))
    public static let crew = Conversation(
        id: "conversation-sample-crew", kind: .group, name: "EXAMPLE Kothrud Crew", adminID: currentUser.id,
        memberIDs: [currentUser.id, friend.id, aarav.id, isha.id], createdAt: hours(-24))
    /// A group I was added to by someone who is not my friend. It waits for Join or Leave and block.
    public static let invitation = Conversation(
        id: "conversation-sample-invitation", kind: .group, name: "Sunday Walkers", adminID: vihaan.id,
        memberIDs: [vihaan.id, tara.id, currentUser.id], createdAt: hours(-5))
    public static let conversations = [friendChat, aaravChat, crew, invitation]
    /// Groups I have been invited to but not joined yet.
    public static let pendingInvitationIDs: Set<ConversationID> = [invitation.id]
    /// Who added whom: group, then member, then the person who added them.
    public static let addedBy: [ConversationID: [UserID: UserID]] = [
        crew.id: [friend.id: currentUser.id, aarav.id: currentUser.id, isha.id: currentUser.id],
        invitation.id: [tara.id: vihaan.id, currentUser.id: vihaan.id]
    ]

    private static func message(
        _ number: Int, in chat: Conversation, by sender: UserProfile, hoursAgo: Double, _ payload: MessagePayload
    ) -> Message {
        Message(id: MessageID("message-sample-\(number)"), conversationID: chat.id, senderID: sender.id,
                createdAt: hours(-hoursAgo), payload: payload)
    }

    public static let messages: [Message] = [
        message(1, in: friendChat, by: friend, hoursAgo: 6, .text("EXAMPLE hey, free this evening?")),
        message(2, in: friendChat, by: currentUser, hoursAgo: 5.9, .text("EXAMPLE yes!")),
        message(3, in: friendChat, by: friend, hoursAgo: 5.8, .hangout(SampleData.evening.id)),
        message(4, in: aaravChat, by: aarav, hoursAgo: 40, .link(URL(string: "https://example.com/EXAMPLE")!)),
        message(5, in: aaravChat, by: currentUser, hoursAgo: 39, .text("EXAMPLE thanks")),
        message(6, in: crew, by: isha, hoursAgo: 12, .text("EXAMPLE what are we doing on Saturday?")),
        message(7, in: crew, by: currentUser, hoursAgo: 11, .poll(question: "EXAMPLE: coffee at 5?")),
        message(8, in: crew, by: aarav, hoursAgo: 10, .voice(path: "voice/EXAMPLE.m4a", seconds: 12)),
        message(9, in: crew, by: friend, hoursAgo: 2, .photos([
            Photo(id: "photo-sample-1", path: "EXAMPLE.jpg", width: 800, height: 600),
            Photo(id: "photo-sample-2", path: "EXAMPLE2.jpg", width: 600, height: 800)
        ]))
    ]

    /// When I last read each chat (the friend chat and the crew chat have 2 unread messages each).
    public static let lastRead: [ConversationID: Date] = [
        friendChat.id: hours(-6.5), aaravChat.id: hours(-38), crew.id: hours(-11.5)
    ]

    /// When the other people last read each chat, so "Seen" shows under my last message. Only people in that chat.
    public static let othersLastRead: [ConversationID: [UserID: Date]] = [
        friendChat.id: [friend.id: hours(-5.5)],
        aaravChat.id: [aarav.id: hours(-38.5)],
        crew.id: [friend.id: hours(-1.5), isha.id: hours(-10.5), aarav.id: hours(-9)]
    ]

    public static let pollVotes = [
        PollVote(messageID: "message-sample-7", userID: currentUser.id, choice: .imIn, votedAt: hours(-10)),
        PollVote(messageID: "message-sample-7", userID: friend.id, choice: .notForMe, votedAt: hours(-9))
    ]

    // MARK: Safety and admin

    public static let reports: [Report] = [
        Report(id: "report-sample-1", reporterID: friend.id, target: .comment("comment-sample-3"),
               targetOwnerID: isha.id, reason: .harassment, detail: "EXAMPLE detail", createdAt: hours(-4)),
        Report(id: "report-sample-2", reporterID: aarav.id, target: .user(kabir.id), targetOwnerID: kabir.id,
               reason: .impersonation, createdAt: hours(-9)),
        Report(id: "report-sample-3", reporterID: isha.id, target: .run("run-sample-7"), targetOwnerID: kabir.id,
               reason: .nudity, status: .actioned, createdAt: hours(-30))
    ]

    public static let placeSuggestions: [PlaceSuggestion] = [
        PlaceSuggestion(id: "suggestion-sample-1", submitterID: friend.id, name: "EXAMPLE Suggested Café",
                        coordinate: Coordinate(latitude: 18.505, longitude: 73.805), category: .cafe,
                        note: "EXAMPLE note", createdAt: hours(-15)),
        PlaceSuggestion(id: "suggestion-sample-2", submitterID: rohan.id, name: "EXAMPLE Suggested Garden",
                        coordinate: Coordinate(latitude: 18.51, longitude: 73.81), category: .parkGarden,
                        createdAt: hours(-40))
    ]

    // MARK: Activity (for currentUser)

    public static let activity: [Activity] = [
        Activity(id: "activity-sample-1", recipientID: currentUser.id, kind: .friendRequest, actorID: sanya.id,
                 target: .user(sanya.id), createdAt: hours(-3)),
        Activity(id: "activity-sample-2", recipientID: currentUser.id, kind: .like, actorID: friend.id,
                 target: .run("run-sample-3"), createdAt: hours(-2)),
        Activity(id: "activity-sample-3", recipientID: currentUser.id, kind: .reply, actorID: rohan.id,
                 target: .comment("comment-sample-5"), createdAt: hours(-3.5), runID: "run-sample-3"),
        Activity(id: "activity-sample-4", recipientID: currentUser.id, kind: .friendAccepted, actorID: meera.id,
                 target: .user(meera.id), createdAt: hours(-26), readAt: hours(-25)),
        Activity(id: "activity-sample-5", recipientID: currentUser.id, kind: .remixCredit, actorID: isha.id,
                 target: .hangout(SampleData.morning.id), createdAt: hours(-50), readAt: hours(-49)),
        Activity(id: "activity-sample-6", recipientID: currentUser.id, kind: .comment, actorID: meera.id,
                 target: .comment("comment-sample-6"), createdAt: hours(-28), readAt: hours(-27), runID: "run-sample-5")
    ]
}
#endif
