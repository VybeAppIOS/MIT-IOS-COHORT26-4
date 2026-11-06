#if DEBUG
import Foundation
import Models

/// The chat half of the shared social store: conversations, messages, polls and the live message streams.
extension SocialStubStore {
    // MARK: Chat

    private func previewText(_ payload: MessagePayload) -> String {
        switch payload {
        case .text(let text): text
        case .photos: "Photo"
        case .hangout: "Hangout"
        case .link: "Link"
        case .voice: "Voice note"
        case .poll(let question): "Poll: \(question)"
        case .unsupported: "New message"
        }
    }

    private func visibleMessages(in id: ConversationID) -> [Message] {
        messages.filter {
            $0.conversationID == id && !isHidden(authoredBy: $0.senderID) && !hiddenTargets.contains(.message($0.id))
        }
    }

    private func requireConversation(_ id: ConversationID) throws -> Int {
        guard let index = conversations.firstIndex(where: {
            $0.id == id && $0.memberIDs.contains(currentUserID) && !pendingIDs.contains($0.id)
        }) else { throw AppError.notFound }
        return index
    }

    func myConversations() -> [Conversation] {
        conversations.filter {
            $0.memberIDs.contains(currentUserID) && !pendingIDs.contains($0.id)
        }.map { conversation in
            var shown = conversation
            if let last = visibleMessages(in: conversation.id).last {
                shown.lastMessage = LastMessagePreview(senderID: last.senderID, text: previewText(last.payload),
                                                       sentAt: last.createdAt)
            }
            return shown
        }.sorted { ($0.lastMessage?.sentAt ?? $0.createdAt) > ($1.lastMessage?.sentAt ?? $1.createdAt) }
    }

    func unreadCounts() -> [ConversationID: Int] {
        var counts: [ConversationID: Int] = [:]
        for conversation in myConversations() {
            let readAt = lastRead[conversation.id] ?? .distantPast
            counts[conversation.id] = visibleMessages(in: conversation.id)
                .filter { $0.senderID != currentUserID && $0.createdAt > readAt }.count
        }
        return counts
    }

    func messageList(in id: ConversationID) throws -> [Message] {
        _ = try requireConversation(id)
        return visibleMessages(in: id)
    }

    func send(_ payload: MessagePayload, in id: ConversationID) throws -> Message {
        _ = try requireConversation(id)
        guard mutedAt[id]?[currentUserID] == nil else {
            throw AppError.invalid("The admin has muted you in this group.")
        }
        if case .text(let text) = payload, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AppError.invalid("Write something first.")
        }
        let sentMessage = Message(id: MessageID(makeID()), conversationID: id, senderID: currentUserID,
                                  createdAt: now(), payload: payload)
        messages.append(sentMessage)
        publish(id)
        return sentMessage
    }

    private func ownMessageIndex(_ id: MessageID) throws -> Int {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { throw AppError.notFound }
        guard messages[index].senderID == currentUserID else {
            throw AppError.invalid("You can only change your own messages.")
        }
        return index
    }

    func edit(_ id: MessageID, text: String) throws {
        let index = try ownMessageIndex(id)
        guard case .text = messages[index].payload, messages[index].deletedAt == nil else {
            throw AppError.invalid("Only text messages can be edited.")
        }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.invalid("Write something first.")
        }
        messages[index].payload = .text(text)
        messages[index].editedAt = now()
        publish(messages[index].conversationID)
    }

    func delete(_ id: MessageID) throws {
        let index = try ownMessageIndex(id)
        messages[index].payload = .text("")
        messages[index].deletedAt = now()
        publish(messages[index].conversationID)
    }

    func markRead(_ id: ConversationID) throws {
        _ = try requireConversation(id)
        lastRead[id] = now()
    }

    func vote(_ choice: PollChoice, on id: MessageID) throws {
        guard let message = messages.first(where: { $0.id == id }), case .poll = message.payload else {
            throw AppError.invalid("That message is not a poll.")
        }
        votes.removeAll { $0.messageID == id && $0.userID == currentUserID }
        votes.append(PollVote(messageID: id, userID: currentUserID, choice: choice, votedAt: now()))
    }

    func votes(for id: MessageID) -> [PollVote] { votes.filter { $0.messageID == id } }

    func startChat(with user: UserID) throws -> Conversation {
        _ = try requireProfile(user)
        guard user != currentUserID, !isHidden(authoredBy: user) else {
            throw AppError.invalid("You cannot message this person.")
        }
        let id = ConversationID.dm(currentUserID, user)
        if let existing = myConversations().first(where: { $0.id == id }) { return existing }
        let created = Conversation(id: id, kind: .directMessage, memberIDs: [currentUserID, user], createdAt: now())
        conversations.append(created)
        return created
    }

    func createGroup(name: String, members: [UserID]) throws -> Conversation {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw AppError.invalid("Give the group a name.") }
        var others: [UserID] = []
        for member in members where member != currentUserID && !others.contains(member) {
            _ = try requireProfile(member)
            guard !isHidden(authoredBy: member) else { throw AppError.invalid("You cannot add this person.") }
            others.append(member)
        }
        guard others.count >= 2 else { throw AppError.invalid("A group needs at least 3 people.") }
        let created = Conversation(id: ConversationID("conversation-\(makeID())"), kind: .group, name: title,
                                   adminID: currentUserID, memberIDs: [currentUserID] + others, createdAt: now())
        conversations.append(created)
        for member in others { addedBy[created.id, default: [:]][member] = currentUserID }
        return created
    }

    private func requireGroup(_ id: ConversationID) throws -> Int {
        let index = try requireConversation(id)
        guard conversations[index].kind == .group else { throw AppError.invalid("This is not a group.") }
        return index
    }

    func rename(_ id: ConversationID, to name: String) throws {
        let index = try requireGroup(id)
        guard conversations[index].adminID == currentUserID else {
            throw AppError.invalid("Only the admin can do this.")
        }
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw AppError.invalid("Give the group a name.") }
        conversations[index].name = title
    }

    func add(_ members: [UserID], to id: ConversationID) throws {
        let index = try requireGroup(id)
        for member in members where !conversations[index].memberIDs.contains(member) {
            _ = try requireProfile(member)
            guard !isHidden(authoredBy: member) else { throw AppError.invalid("You cannot add this person.") }
            conversations[index].memberIDs.append(member)
            addedBy[id, default: [:]][member] = currentUserID
            joinedAt[id, default: [:]][member] = now()
        }
    }

    func remove(_ member: UserID, from id: ConversationID) throws {
        let index = try requireGroup(id)
        guard conversations[index].adminID == currentUserID else {
            throw AppError.invalid("Only the admin can do this.")
        }
        guard member != currentUserID else { throw AppError.invalid("Use Leave to leave the group.") }
        guard conversations[index].memberIDs.contains(member) else { throw AppError.notFound }
        conversations[index].memberIDs.removeAll { $0 == member }
        mutedAt[id]?[member] = nil
    }

    private func membership(of user: UserID, in conversation: Conversation) -> Membership {
        Membership(
            conversationID: conversation.id, userID: user, role: conversation.adminID == user ? .admin : .member,
            status: user == currentUserID && pendingIDs.contains(conversation.id) ? .pending : .active,
            joinedAt: joinedAt[conversation.id]?[user] ?? conversation.createdAt,
            lastReadAt: user == currentUserID ? lastRead[conversation.id] : nil,
            mutedAt: mutedAt[conversation.id]?[user], addedByID: addedBy[conversation.id]?[user])
    }

    /// Works for a group I am invited to as well, so the invitation can name who added me.
    func memberships(in id: ConversationID) throws -> [Membership] {
        guard let conversation = conversations.first(where: { $0.id == id && $0.memberIDs.contains(currentUserID) })
        else { throw AppError.notFound }
        return conversation.memberIDs.map { membership(of: $0, in: conversation) }
    }

    func setMuted(_ muted: Bool, member: UserID, in id: ConversationID) throws {
        let index = try requireGroup(id)
        guard conversations[index].adminID == currentUserID else {
            throw AppError.invalid("Only the admin can do this.")
        }
        guard member != currentUserID else { throw AppError.invalid("The admin cannot be muted.") }
        guard conversations[index].memberIDs.contains(member) else { throw AppError.notFound }
        if muted {
            mutedAt[id, default: [:]][member] = mutedAt[id]?[member] ?? now()
        } else {
            mutedAt[id]?[member] = nil
        }
    }

    func pendingInvitations() -> [Conversation] {
        conversations.filter { conversation in
            guard pendingIDs.contains(conversation.id), conversation.memberIDs.contains(currentUserID) else {
                return false
            }
            let adder = addedBy[conversation.id]?[currentUserID] ?? conversation.adminID
            return adder.map { !isHidden(authoredBy: $0) } ?? true   // a blocked person's invitation is hidden
        }
    }

    /// Leaving passes the admin role to the oldest remaining member.
    func leave(_ id: ConversationID) throws {
        let index = try requireGroup(id)
        conversations[index].memberIDs.removeAll { $0 == currentUserID }
        mutedAt[id]?[currentUserID] = nil
        if conversations[index].adminID == currentUserID {
            conversations[index].adminID = conversations[index].memberIDs.first
            if let newAdmin = conversations[index].adminID { mutedAt[id]?[newAdmin] = nil }   // admins are not muted
        }
    }

    func respondToInvitation(to id: ConversationID, accept: Bool) throws {
        guard let index = conversations.firstIndex(where: { $0.id == id }), pendingIDs.contains(id),
              conversations[index].memberIDs.contains(currentUserID) else { throw AppError.notFound }
        pendingIDs.remove(id)
        if accept {
            joinedAt[id, default: [:]][currentUserID] = now()
        } else {
            conversations[index].memberIDs.removeAll { $0 == currentUserID }
            addedBy[id]?[currentUserID] = nil
        }
    }

    // MARK: Live messages

    /// Starts sending the conversation's message list to `listener`: now, and after every change.
    func subscribe(_ id: ConversationID, listener: Listener) -> UUID {
        let token = UUID()
        listeners[id, default: [:]][token] = listener
        listener.yield(visibleMessages(in: id))
        if simulateIncoming, simulated.insert(id).inserted {
            Task {
                try? await Task.sleep(for: .seconds(2))
                self.receiveSimulatedMessage(in: id)
            }
        }
        return token
    }

    func unsubscribe(_ id: ConversationID, token: UUID) { listeners[id]?[token] = nil }

    private func publish(_ id: ConversationID) {
        let list = visibleMessages(in: id)
        listeners[id]?.values.forEach { $0.yield(list) }
    }

    /// Pretends another member wrote (the "incoming message after 2 seconds" the chat preview needs).
    private func receiveSimulatedMessage(in id: ConversationID) {
        guard let conversation = conversations.first(where: { $0.id == id }),
              let sender = conversation.memberIDs.first(where: { $0 != currentUserID && !isHidden(authoredBy: $0) })
        else { return }
        let newest = messages.filter { $0.conversationID == id }.map(\.createdAt).max() ?? now()
        messages.append(Message(id: MessageID(makeID()), conversationID: id, senderID: sender,
                                createdAt: max(now(), newest.addingTimeInterval(1)),
                                payload: .text("Just got here, where are you?")))
        publish(id)
    }
}
#endif
