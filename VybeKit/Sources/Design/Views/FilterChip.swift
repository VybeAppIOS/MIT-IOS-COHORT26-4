import SwiftUI

/// A pill that turns a filter on or off. Selected chips show a checkmark, so state is never colour alone.
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
        styledButton
            .buttonBorderShape(.capsule)
            .tint(Theme.Color.accent)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .vybeAnimation(Theme.Motion.quick, value: isSelected)
            .vybeHaptic(.selection, trigger: isSelected)
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.tiny) {
                if isSelected {
                    Image(systemName: "checkmark").accessibilityHidden(true)
                }
                title.text
                    .font(Theme.Font.subheadline)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: Theme.Size.minTapTarget)
        }
    }

    @ViewBuilder private var styledButton: some View {
        if isSelected {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
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
