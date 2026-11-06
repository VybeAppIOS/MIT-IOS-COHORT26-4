import SwiftUI

/// A pill that turns a filter on or off. A selected chip is filled with the accent colour and keeps the same size as
/// an unselected one (no tick mark that would change its width). VoiceOver still hears "selected" from the trait.
public struct FilterChip: View {
    private let title: VybeText
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ title: LocalizedStringResource, isSelected: Bool, action: @escaping () -> Void) {
        self.title = .fixed(title)
        self.isSelected = isSelected
        self.action = action
    }

    public init(verbatim title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = .verbatim(title)
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            title.text
                .font(Theme.Font.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? Theme.Color.onAccent : Theme.Color.textPrimary)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
                .background(isSelected ? Theme.Color.accent : Theme.Color.surfaceRaised, in: Capsule())
                .overlay { Capsule().strokeBorder(isSelected ? Color.clear : Theme.Color.separator) }
                // The pill looks small; the tappable area is still 44 pt tall (HIG), and it grows with the text.
                .frame(minHeight: Theme.Size.minTapTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .vybeAnimation(Theme.Motion.quick, value: isSelected)
        .vybeHaptic(.selection, trigger: isSelected)
    }
}

private struct ChipDemo: View {
    @State private var selected: Set<String> = ["Café"]
    private let tags = ["Café", "Street food", "Park/garden", "Board-game café"]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.small) {
                ForEach(tags, id: \.self) { tag in
                    FilterChip(verbatim: tag, isSelected: selected.contains(tag)) {
                        if selected.contains(tag) { selected.remove(tag) } else { selected.insert(tag) }
                    }
                }
            }
            .padding(Theme.Spacing.large)
        }
        .scrollIndicators(.hidden)
        .background(Theme.Color.surface)
    }
}

#Preview("FilterChip, tap to toggle") {
    ChipDemo()
}

#Preview("FilterChip, large text") {
    ChipDemo()
        .dynamicTypeSize(.accessibility3)
}

#Preview("FilterChip, dark") {
    ChipDemo()
        .preferredColorScheme(.dark)
}
