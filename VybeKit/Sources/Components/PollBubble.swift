import Design
import Models
import SwiftUI

/// A poll in a group chat: the question and the two fixed answers, "I'm in" and "Not for me", each with its count.
/// My answer has a checkmark and the words "Your vote", so it is never colour alone. Tapping the other answer
/// changes my vote.
public struct PollBubble: View {
    private let data: PollData
    private let vote: (PollChoice) -> Void

    public init(_ data: PollData, vote: @escaping (PollChoice) -> Void) {
        self.data = data
        self.vote = vote
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label(data.question, systemImage: "chart.bar")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityLabel(Text(verbatim: "\(ComponentStrings.pollTitle), \(data.question)"))
            ForEach(PollChoice.allCases, id: \.self) { choice in
                answer(choice)
            }
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: 300, alignment: .leading)
        .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.large))
    }

    private func answer(_ choice: PollChoice) -> some View {
        let isMine = data.myVote == choice
        let count = data.count(for: choice)
        return Button { vote(choice) } label: {
            HStack(spacing: Theme.Spacing.small) {
                Image(systemName: isMine ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isMine ? Theme.Color.accent : Theme.Color.textSecondary)
                Text(verbatim: Self.title(choice)).font(Theme.Font.body)
                Spacer(minLength: Theme.Spacing.small)
                Text(count, format: .number).font(Theme.Font.subheadline.monospacedDigit())
            }
            .foregroundStyle(Theme.Color.textPrimary)
            .frame(minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: Self.title(choice)))
        .accessibilityValue(Text(verbatim: isMine ? "\(count.formatted()), \(ComponentStrings.pollYourVote)"
                                                   : count.formatted()))
        .accessibilityAddTraits(isMine ? [.isButton, .isSelected] : .isButton)
    }

    static func title(_ choice: PollChoice) -> String {
        switch choice {
        case .imIn: ComponentStrings.pollImIn
        case .notForMe: ComponentStrings.pollNotForMe
        }
    }
}

#if DEBUG
#Preview("Voted and not voted") {
    VStack(spacing: Theme.Spacing.medium) {
        PollBubble(PollData(question: "EXAMPLE coffee at 5?", imInCount: 3, notForMeCount: 1,
                            myVote: .imIn)) { _ in }
        PollBubble(PollData(question: "EXAMPLE Vetal Tekdi on Sunday morning?")) { _ in }
    }
    .padding(Theme.Spacing.large)
}

#Preview("Large text") {
    PollBubble(PollData(question: "EXAMPLE coffee at 5?", imInCount: 3, notForMeCount: 1,
                        myVote: .notForMe)) { _ in }
        .padding(Theme.Spacing.large)
        .dynamicTypeSize(.accessibility3)
}
#endif
