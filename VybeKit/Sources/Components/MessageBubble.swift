import Design
import Models
import SwiftUI

/// What a message bubble can ask the chat screen to do.
public struct MessageBubbleActions {
    public var openHangout: (HangoutID) -> Void
    public var openLink: (URL) -> Void
    public var openPhoto: (Int) -> Void
    public var togglePlayback: () -> Void
    public var vote: (PollChoice) -> Void

    public init(
        openHangout: @escaping (HangoutID) -> Void = { _ in }, openLink: @escaping (URL) -> Void = { _ in },
        openPhoto: @escaping (Int) -> Void = { _ in }, togglePlayback: @escaping () -> Void = {},
        vote: @escaping (PollChoice) -> Void = { _ in }
    ) {
        self.openHangout = openHangout
        self.openLink = openLink
        self.openPhoto = openPhoto
        self.togglePlayback = togglePlayback
        self.vote = vote
    }
}

/// One chat message: mine on the right in the accent colour, theirs on the left with the sender's name at the start
/// of a group. Every variant (text, photos, a Hangout, a link, a voice note, a poll, deleted, a system line) is here,
/// plus the "Edited" tag and the read receipt under my last message.
public struct MessageBubble: View {
    private let data: MessageRowData
    private let actions: MessageBubbleActions

    public init(_ data: MessageRowData, actions: MessageBubbleActions = MessageBubbleActions()) {
        self.data = data
        self.actions = actions
    }

    public var body: some View {
        if case .system(let text) = data.content {
            Text(verbatim: text)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.small)
        } else {
            HStack {
                if data.isMine { Spacer(minLength: Theme.Spacing.huge) }
                VStack(alignment: data.isMine ? .trailing : .leading, spacing: Theme.Spacing.tiny) {
                    if !data.isMine && data.startsGroup {
                        Text(verbatim: data.senderName)
                            .font(Theme.Font.caption.weight(.semibold))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    MessageContent(data: data, actions: actions)
                    footer
                }
                if !data.isMine { Spacer(minLength: Theme.Spacing.huge) }
            }
            .padding(.top, data.startsGroup ? Theme.Spacing.small : 0)
        }
    }

    @ViewBuilder private var footer: some View {
        let parts = [data.isEdited ? ComponentStrings.messageEdited : nil, receiptText].compactMap(\.self)
        if !parts.isEmpty {
            Text(verbatim: parts.joined(separator: " · "))
                .font(Theme.Font.caption2)
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private var receiptText: String? {
        switch data.receipt {
        case .sent: ComponentStrings.receiptSent
        case .delivered: ComponentStrings.receiptDelivered
        case .seen: ComponentStrings.receiptSeen
        case nil: nil
        }
    }
}

/// The inside of a bubble, per kind of message.
private struct MessageContent: View {
    let data: MessageRowData
    let actions: MessageBubbleActions

    var body: some View {
        switch data.content {
        case .text(let text):
            bubble { Text(verbatim: text).font(Theme.Font.body) }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: spoken(text)))
        case .photos(let urls):
            PhotoMessage(urls: urls, open: actions.openPhoto)
                .accessibilityLabel(Text(verbatim: spoken(ComponentStrings.photo)))
        case .hangout(let card):
            HangoutCard(card, style: .compact) { actions.openHangout(card.id) }
                .frame(maxWidth: 320)
        case .link(let url):
            Button { actions.openLink(url) } label: {
                bubble { Label(url.host() ?? url.absoluteString, systemImage: "link").font(Theme.Font.body) }
            }
            .buttonStyle(.plain)
        case .voice(let note):
            VoiceNoteBubble(note, isMine: data.isMine, toggle: actions.togglePlayback)
                .accessibilityLabel(Text(verbatim: spoken(ComponentStrings.voiceNote(note.durationText))))
        case .poll(let poll):
            PollBubble(poll, vote: actions.vote)
        case .deleted:
            bubble {
                Text(verbatim: ComponentStrings.messageDeleted).font(Theme.Font.body.italic())
            }
        case .system:
            EmptyView()
        }
    }

    /// The coloured rounded shape around text: accent for mine, raised surface for theirs.
    private func bubble<Inside: View>(@ViewBuilder _ content: () -> Inside) -> some View {
        content()
            .foregroundStyle(data.isMine ? Theme.Color.onAccent : Theme.Color.textPrimary)
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .background(data.isMine ? Theme.Color.accent : Theme.Color.surfaceRaised,
                        in: .rect(cornerRadius: Theme.Radius.large))
    }

    /// "Sample Isha, EXAMPLE see you at 5" or "You, …"
    private func spoken(_ content: String) -> String {
        "\(data.isMine ? ComponentStrings.you : data.senderName), \(content)"
    }
}

/// One or two photos side by side; tapping one opens it.
private struct PhotoMessage: View {
    let urls: [URL?]
    let open: (Int) -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.tiny) {
            ForEach(Array(urls.prefix(2).enumerated()), id: \.offset) { offset, url in
                Button { open(offset) } label: {
                    PlaceImage(url: url, aspectRatio: urls.count > 1 ? 3 / 4 : 4 / 3)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 280)
        .clipShape(.rect(cornerRadius: Theme.Radius.large))
    }
}

// MARK: - Previews

#if DEBUG
private let previewMessages: [MessageRowData] = [
    MessageRowData(id: "m0", senderName: "", isMine: false, content: .system("Sample Aarav added Sample Isha")),
    MessageRowData(id: "m1", senderName: "Sample Isha", isMine: false, content: .text("EXAMPLE free this evening?")),
    MessageRowData(id: "m2", senderName: "Sample Isha", isMine: false,
                   content: .hangout(.previewPick), startsGroup: false),
    MessageRowData(id: "m3", senderName: "Sample Me", isMine: true,
                   content: .text("EXAMPLE Yes! A much longer answer that wraps onto a few lines so the bubble can be "
                                  + "checked at large text sizes."), isEdited: true),
    MessageRowData(id: "m4", senderName: "Sample Aarav", isMine: false,
                   content: .voice(VoiceNoteData(durationText: "0:12", progress: 0.4, isPlaying: true,
                                                 levels: [0.2, 0.5, 0.9, 0.4, 0.7, 0.3, 0.6, 0.8, 0.2, 0.5]))),
    MessageRowData(id: "m5", senderName: "Sample Me", isMine: true,
                   content: .poll(PollData(question: "EXAMPLE coffee at 5?", imInCount: 3, notForMeCount: 1,
                                           myVote: .imIn))),
    MessageRowData(id: "m6", senderName: "Sample Rohan", isMine: false, content: .photos([nil, nil])),
    MessageRowData(id: "m7", senderName: "Sample Rohan", isMine: false,
                   content: .link(URL(string: "https://example.com/EXAMPLE")!), startsGroup: false),
    MessageRowData(id: "m8", senderName: "Sample Me", isMine: true, content: .deleted, receipt: .seen)
]

#Preview("Every kind") {
    ScrollView {
        VStack(spacing: Theme.Spacing.tiny) {
            ForEach(previewMessages) { MessageBubble($0) }
        }
        .padding(Theme.Spacing.large)
    }
    .background(Theme.Color.surface)
}

#Preview("Large text") {
    ScrollView {
        VStack(spacing: Theme.Spacing.tiny) {
            ForEach(previewMessages.prefix(5)) { MessageBubble($0) }
        }
        .padding(Theme.Spacing.large)
    }
    .dynamicTypeSize(.accessibility3)
}
#endif
