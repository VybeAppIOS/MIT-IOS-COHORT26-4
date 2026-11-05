import Design
import SwiftUI

/// Layout only: every value comes from `MiniBarViewModel`, the tap goes to it. One VoiceOver button.
struct MiniBarView: View {
    let viewModel: MiniBarViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        Button { viewModel.tapped() } label: {
            HStack(spacing: Theme.Spacing.medium) {
                Circle()
                    .fill(Theme.Color.accent)
                    .frame(width: Theme.Spacing.small, height: Theme.Spacing.small)
                    .opacity(pulsing ? 0.35 : 1)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: viewModel.currentSpotName ?? viewModel.hangoutTitle)
                        .font(Theme.Font.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .lineLimit(1)
                    Text(verbatim: viewModel.hangoutTitle)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: Theme.Spacing.small)
                if let startedAt = viewModel.startedAt {
                    Text(startedAt, style: .timer)
                        .font(Theme.Font.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                Image(systemName: "chevron.up")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: viewModel.accessibilityLabel))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("live.miniBar")
        .task(id: viewModel.liveHangoutID) { await viewModel.loadSpots() }
        .onAppear {
            guard !reduceMotion else { return }       // a still dot with Reduce Motion
            withAnimation(Theme.Motion.gentle.repeatForever(autoreverses: true)) { pulsing = true }
        }
    }
}

/// Attaches the mini-bar to the App's `TabView` (via `LiveScreens.miniBarAccessory`). The bar is switched off when no
/// run is live: `isEnabled:` needs iOS 26.1; on 26.0 the accessory stays and its content is empty.
struct MiniBarAccessory: ViewModifier {
    @State var viewModel: MiniBarViewModel

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: viewModel.isVisible) { MiniBarView(viewModel: viewModel) }
        } else {
            content.tabViewBottomAccessory {
                if viewModel.isVisible { MiniBarView(viewModel: viewModel) }
            }
        }
    }
}
