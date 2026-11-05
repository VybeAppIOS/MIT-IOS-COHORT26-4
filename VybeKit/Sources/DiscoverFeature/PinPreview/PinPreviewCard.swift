import Components
import Design
import SwiftUI

/// D2: the card for the selected pin, drawn over the bottom of the map. It is an overlay, not a sheet, because a sheet
/// would cover the tab bar (IA principle 4). It has no ViewModel of its own: it shows plain values from
/// `DiscoverMapViewModel` and hands every tap back to it (SC-D2 shares SC-D1's state).
///
/// Tapping the card or "See Hangout" opens the Hangout. A swipe down, a tap on the map, or the VoiceOver escape
/// gesture closes it.
struct PinPreviewCard: View {
    let card: HangoutCardData
    let onOpen: () -> Void
    let onSave: () -> Void
    let onDismiss: () -> Void

    /// How far the card is being dragged down right now (it follows the finger, never up).
    @State private var dragOffset: CGFloat = 0
    /// How far a swipe must go before it closes the card.
    private let dismissDistance = Theme.Spacing.huge * 2

    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            HangoutCard(card, style: .compact, action: onOpen)
                .vybeZoomSource(id: card.id)            // zooms into Hangout detail (MOTION moment 2)
            HStack(spacing: Theme.Spacing.small) {
                Button(action: onSave) {
                    Label(card.isSaved ? PinPreviewText.saved : PinPreviewText.save,
                          systemImage: card.isSaved ? "bookmark.fill" : "bookmark")
                        .font(Theme.Font.headline)
                        .frame(minHeight: Theme.Size.minTapTarget)
                }
                .buttonStyle(.bordered)
                .vybeHaptic(.selection, trigger: card.isSaved)
                .accessibilityIdentifier("discover.pinPreview.save")
                PrimaryButton(verbatim: PinPreviewText.seeHangout, action: onOpen)
                    .accessibilityIdentifier("discover.pinPreview.seeHangout")
            }
        }
        .padding(Theme.Spacing.large)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.large))
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.bottom, Theme.Spacing.small)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { dragOffset = max(0, $0.translation.height) }
                .onEnded { value in
                    if value.translation.height > dismissDistance { onDismiss() }
                    dragOffset = 0
                })
        .accessibilityAction(.escape, onDismiss)        // VoiceOver: two-finger "Z" closes the card
        .accessibilityHint(Text(verbatim: PinPreviewText.closeHint))
    }
}

extension View {
    /// The card's entrance: slides up from the bottom, or only fades with Reduce Motion (MOTION moment 1).
    func pinPreviewTransition() -> some View {
        modifier(PinPreviewTransition())
    }
}

private struct PinPreviewTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.vybeReduceMotionOverride) private var reduceMotionOverride   // previews only

    func body(content: Content) -> some View {
        content.transition(Theme.Motion.slideUp(reduceMotion: reduceMotionOverride ?? systemReduceMotion))
    }
}

/// The preview card's text, read from DiscoverFeature's own catalog (`bundle: #bundle`, task X-3).
enum PinPreviewText {
    static var save: String { String(localized: "discover.pinPreview.save", bundle: #bundle) }
    static var saved: String { String(localized: "discover.pinPreview.saved", bundle: #bundle) }
    static var seeHangout: String { String(localized: "discover.pinPreview.seeHangout", bundle: #bundle) }
    static var closeHint: String { String(localized: "discover.pinPreview.closeHint", bundle: #bundle) }
}
