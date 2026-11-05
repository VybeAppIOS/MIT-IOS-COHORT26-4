#if DEBUG
import Components
import Design
import Models
import SwiftUI

/// The EXAMPLE Evening Hangout's card, as the map passes it to the preview card.
private func sampleCard(saved: Bool) -> HangoutCardData {
    HangoutCardData(SampleData.evening, coverURL: nil, isSaved: saved)
}

/// The card at the bottom of a plain background, the way it sits over the map.
private func onMap(_ card: some View) -> some View {
    ZStack(alignment: .bottom) {
        Theme.Color.surfaceRaised.ignoresSafeArea()
        card
    }
}

#Preview("Not saved") {
    onMap(PinPreviewCard(card: sampleCard(saved: false), onOpen: {}, onSave: {}, onDismiss: {}))
}

#Preview("Saved") {
    onMap(PinPreviewCard(card: sampleCard(saved: true), onOpen: {}, onSave: {}, onDismiss: {}))
}

#Preview("Large text") {
    onMap(PinPreviewCard(card: sampleCard(saved: false), onOpen: {}, onSave: {}, onDismiss: {}))
        .dynamicTypeSize(.accessibility3)
}

/// Tap "Show / hide" to watch the entrance: it slides up normally, and only fades with Reduce Motion.
private struct EntranceDemo: View {
    let reduceMotion: Bool
    @State private var isShowing = true

    var body: some View {
        onMap(VStack {
            Button { isShowing.toggle() } label: { Text(verbatim: "Show / hide") }   // preview-only text
                .buttonStyle(.bordered)
            Spacer()
            if isShowing {
                PinPreviewCard(card: sampleCard(saved: false), onOpen: {}, onSave: {},
                               onDismiss: { isShowing = false })
                    .pinPreviewTransition()
            }
        }
        .vybeAnimation(Theme.Motion.standard, value: isShowing))
        .environment(\.vybeReduceMotionOverride, reduceMotion)
    }
}

#Preview("Slide up") { EntranceDemo(reduceMotion: false) }
#Preview("Reduce Motion: fade") { EntranceDemo(reduceMotion: true) }
#endif
