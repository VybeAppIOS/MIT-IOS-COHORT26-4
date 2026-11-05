import Design
import SwiftUI

/// The microphone in the composer. Layout and touches only: every decision is in `ConversationViewModel`.
/// Hold to record, let go to send, slide left to cancel. A held touch does not work with VoiceOver, so the control
/// also has an accessibility action: activate once to start, again to send (and a Discard action while recording).
struct MicControl: View {
    let viewModel: ConversationViewModel
    /// True while a finger is on the microphone (the system resets it if the touch is interrupted).
    @GestureState private var isPressing = false

    var body: some View {
        Image(systemName: "mic.fill")
            .font(Theme.Font.title3)
            .foregroundStyle(viewModel.isRecording ? Theme.Color.critical : Theme.Color.textPrimary)
            .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            .contentShape(.rect)
            .opacity(viewModel.canWrite ? 1 : 0.4)
            .disabled(!viewModel.canWrite && !viewModel.isRecording)   // VoiceOver says "dimmed", not just a faded icon
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressing) { _, pressing, _ in pressing = true }
                    .onChanged { viewModel.micDragged($0.translation.width) })
            .onChange(of: isPressing) { _, pressing in
                if pressing { viewModel.micPressed() } else { Task { await viewModel.micReleased() } }
            }
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: viewModel.micControlLabel))
            .accessibilityHint(Text(verbatim: viewModel.micHint))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { Task { await viewModel.micTapped() } }
            .accessibilityActions {
                if viewModel.isRecording {
                    Button { Task { await viewModel.cancelRecording() } } label: {
                        Text(verbatim: viewModel.cancelRecordingLabel)
                    }
                }
            }
    }
}

/// While recording: the words "Recording" and how to cancel (text and an icon, not only colour). It slides with the
/// finger directly, so there is no animation to reduce.
struct RecordingBar: View {
    let viewModel: ConversationViewModel

    var body: some View {
        HStack {
            Image(systemName: "waveform").foregroundStyle(Theme.Color.critical).accessibilityHidden(true)
            Text(verbatim: viewModel.recordingText).font(Theme.Font.body)
            Spacer(minLength: 0)
            if viewModel.isHolding {
                Label { Text(verbatim: viewModel.slideHint) } icon: {
                    Image(systemName: viewModel.willCancel ? "trash" : "chevron.left")
                }
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.Color.textSecondary)
            } else {
                IconButton(systemImage: "trash", verbatimLabel: viewModel.cancelRecordingLabel) {
                    Task { await viewModel.cancelRecording() }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .frame(minHeight: Theme.Size.minTapTarget)
        .background(Theme.Color.surfaceRaised, in: .rect(cornerRadius: Theme.Radius.large))
        .offset(x: viewModel.slideOffset)
    }
}
