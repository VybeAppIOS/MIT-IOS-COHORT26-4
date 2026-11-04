import Design
import SwiftUI

/// A voice note: play/pause, a waveform that fills as it plays, and the length. The chat screen owns the player
/// (Core's `AudioPlayer`) and passes `progress` and `isPlaying` in.
public struct VoiceNoteBubble: View {
    private let data: VoiceNoteData
    private let isMine: Bool
    private let toggle: () -> Void
    @ScaledMetric(relativeTo: .body) private var waveHeight = 28.0

    public init(_ data: VoiceNoteData, isMine: Bool, toggle: @escaping () -> Void) {
        self.data = data
        self.isMine = isMine
        self.toggle = toggle
    }

    public var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            Button(action: toggle) {
                Image(systemName: data.isPlaying ? "pause.fill" : "play.fill")
                    .font(Theme.Font.title3)
                    .foregroundStyle(foreground)
                    .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: data.isPlaying ? ComponentStrings.pauseVoiceNote
                                                              : ComponentStrings.playVoiceNote))
            Waveform(levels: data.levels, progress: data.progress, played: foreground,
                     unplayed: foreground.opacity(0.35))
                .frame(height: waveHeight)
                .accessibilityHidden(true)
            Text(verbatim: data.durationText)
                .font(Theme.Font.caption.monospacedDigit())
                .foregroundStyle(foreground)
        }
        .padding(.trailing, Theme.Spacing.medium)
        .frame(maxWidth: 280)
        .background(isMine ? Theme.Color.accent : Theme.Color.surfaceRaised,
                    in: .rect(cornerRadius: Theme.Radius.large))
    }

    private var foreground: Color { isMine ? Theme.Color.onAccent : Theme.Color.textPrimary }
}

/// Bars from the recorded loudness; the played part is drawn in the strong colour.
private struct Waveform: View {
    let levels: [Float]
    let progress: Double
    let played: Color
    let unplayed: Color

    var body: some View {
        Canvas { context, size in
            let bars = levels.isEmpty ? Array(repeating: Float(0.3), count: 24) : levels
            let slot = size.width / CGFloat(bars.count)
            for (index, level) in bars.enumerated() {
                let height = max(3, size.height * CGFloat(min(max(level, 0), 1)))
                let bar = CGRect(x: CGFloat(index) * slot + slot * 0.2, y: (size.height - height) / 2,
                                 width: slot * 0.6, height: height)
                let isPlayed = (Double(index) + 0.5) / Double(bars.count) <= progress
                context.fill(Path(roundedRect: bar, cornerRadius: bar.width / 2),
                             with: .color(isPlayed ? played : unplayed))
            }
        }
    }
}

#if DEBUG
#Preview("Playing, paused, mine") {
    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
        VoiceNoteBubble(VoiceNoteData(durationText: "0:12", progress: 0.4, isPlaying: true,
                                      levels: [0.2, 0.5, 0.9, 0.4, 0.7, 0.3, 0.6, 0.8, 0.2, 0.5]),
                        isMine: false) {}
        VoiceNoteBubble(VoiceNoteData(durationText: "1:58"), isMine: false) {}
        VoiceNoteBubble(VoiceNoteData(durationText: "0:45", progress: 1), isMine: true) {}
    }
    .padding(Theme.Spacing.large)
}
#endif
