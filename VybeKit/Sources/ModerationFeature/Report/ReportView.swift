import Components
import Design
import SwiftUI

/// Layout only: every value comes from `ReportViewModel`, every tap goes to it.
struct ReportView: View {
    @State private var viewModel: ReportViewModel
    @FocusState private var detailFocused: Bool

    init(viewModel: ReportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if case .sent(let hidden) = viewModel.phase {
                ReportSentView(viewModel: viewModel, hidden: hidden)
            } else {
                form
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.showsCancel && !viewModel.isSent {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SharedStrings.cancel) { viewModel.cancelTapped() }
                }
            }
        }
        .vybeAnimation(Theme.Motion.standard, value: viewModel.phase)
        .vybeHaptic(.success, trigger: viewModel.isSent)
    }

    private var form: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    header
                    if viewModel.showsHelp {
                        SelfHarmHelpCard(viewModel: viewModel).transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    reasonList
                    if viewModel.showsDetail { detailField.id(Self.detailID) }
                    if viewModel.hasFailed { SafetyNote(viewModel.errorMessage, style: .warning) }
                }
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.top, Theme.Spacing.small)
                .padding(.bottom, Theme.Spacing.extraLarge)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.selected) { _, reason in
                guard reason == .other else { return }
                withVybeAnimation(Theme.Motion.standard) { proxy.scrollTo(Self.detailID, anchor: .bottom) }
                detailFocused = true
            }
        }
        .safeAreaInset(edge: .bottom) { sendBar }
    }

    private static let detailID = "report-detail"

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(verbatim: viewModel.headline)
                .font(Theme.Font.title2.bold())
                .foregroundStyle(Theme.Color.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Label {
                Text(verbatim: viewModel.subtitle)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lock.fill")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.accent)
            }
        }
    }

    private var reasonList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.reasons) { row in
                ReportReasonRowView(row: row, isSelected: viewModel.selected == row.reason) {
                    viewModel.select(row.reason)
                }
                if row.id != viewModel.reasons.last?.id {
                    Divider().padding(.leading, Theme.Spacing.large + Theme.Size.minTapTarget)
                }
            }
        }
        .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.large))
        .accessibilityElement(children: .contain)
    }

    private var detailField: some View {
        VStack(alignment: .trailing, spacing: Theme.Spacing.tiny) {
            TextField(viewModel.detailPlaceholder, text: $viewModel.detail, axis: .vertical)
                .font(Theme.Font.body)
                .lineLimit(3...6)
                .focused($detailFocused)
                .padding(Theme.Spacing.medium)
                .background(Theme.Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .strokeBorder(viewModel.isDetailTooLong ? Theme.Color.critical : Theme.Color.separator)
                }
            Text(verbatim: viewModel.detailCountText)
                .font(Theme.Font.caption)
                .foregroundStyle(viewModel.isDetailTooLong ? Theme.Color.critical : Theme.Color.textSecondary)
        }
    }

    private var sendBar: some View {
        PrimaryButton(verbatim: viewModel.sendTitle, isLoading: viewModel.isSending) {
            detailFocused = false
            Task { await viewModel.sendTapped() }
        }
        .disabled(!viewModel.canSend)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(.bar)
    }
}

/// One reason: a tinted symbol, the words, and a tick when chosen.
private struct ReportReasonRowView: View {
    let row: ReportReasonRow
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric private var iconSize: CGFloat = 32

    private var tint: Color { row.isSevere ? Theme.Color.critical : Theme.Color.accent }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: row.symbol)
                    .font(Theme.Font.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: iconSize, height: iconSize)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.small))
                    .accessibilityHidden(true)
                Text(verbatim: row.title)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Theme.Spacing.small)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Theme.Font.title3)
                    .foregroundStyle(isSelected ? Theme.Color.accent : Theme.Color.separator)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.small)
            .frame(minHeight: Theme.Size.minTapTarget + Theme.Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
