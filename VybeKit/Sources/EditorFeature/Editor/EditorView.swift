import Components
import Design
import SwiftUI

/// Layout only: the editor cover's root. Details, Spots (reorder, swipe to delete, minutes and note), budget, time,
/// tags and best times. Close (top left) asks before throwing work away; Done (top right) needs a valid Hangout.
struct EditorView: View {
    @State private var viewModel: EditorViewModel

    init(viewModel: EditorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: { Task { await viewModel.reload() } }) { _ in
            form
        } placeholder: {
            List { Text(verbatim: viewModel.screenTitle) }
        } empty: {
            EmptyView()
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.screenTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "editor.close", bundle: #bundle)) { viewModel.closeTapped() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "editor.done", bundle: #bundle)) { Task { await viewModel.doneTapped() } }
                    .disabled(!viewModel.canFinish)
                    .accessibilityIdentifier("editor.done")
            }
        }
        .sheet(isPresented: $viewModel.isAddingSpot) {
            AddSpotView(viewModel: viewModel.makeAddSpotViewModel())
        }
        .confirmationDialog(String(localized: "editor.close.title", bundle: #bundle),
                            isPresented: $viewModel.isConfirmingClose, titleVisibility: .visible) {
            Button(String(localized: "editor.close.keep", bundle: #bundle)) {
                Task { await viewModel.keepDraftAndClose() }
            }
            Button(String(localized: "editor.close.discard", bundle: #bundle), role: .destructive) {
                Task { await viewModel.discardAndClose() }
            }
            Button(SharedStrings.cancel, role: .cancel) {}
        }
        .task { await viewModel.load() }
    }

    private var form: some View {
        List {
            if let banner = viewModel.remixBanner {
                Section { SafetyNote(banner, style: viewModel.keepsCredit ? .info : .warning) }
            }
            EditorDetailsSection(viewModel: viewModel)
            EditorSpotsSection(viewModel: viewModel)
            EditorBudgetSection(viewModel: viewModel)
            EditorChipsSection(title: String(localized: "editor.section.tags", bundle: #bundle),
                               chips: viewModel.tagOptions, selected: viewModel.tags) { viewModel.toggleTag($0) }
            EditorChipsSection(title: String(localized: "editor.section.bestTimes", bundle: #bundle),
                               chips: viewModel.timeOptions, selected: viewModel.bestTimes) {
                viewModel.toggleBestTime($0)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
    }
}

/// Title (3 to 60) and summary (up to 200), with their errors right under them.
private struct EditorDetailsSection: View {
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        Section {
            VybeTextField(verbatim: String(localized: "editor.field.title", bundle: #bundle), text: $viewModel.title,
                          errorText: viewModel.titleError)
                .onChange(of: viewModel.title) { _, _ in viewModel.edited() }
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                TextField(String(localized: "editor.field.summary", bundle: #bundle), text: $viewModel.summary,
                          axis: .vertical)
                    .font(Theme.Font.body)
                    .lineLimit(2...5)
                    .onChange(of: viewModel.summary) { _, _ in viewModel.edited() }
                if let error = viewModel.summaryError {
                    Text(verbatim: error).font(Theme.Font.caption).foregroundStyle(Theme.Color.critical)
                }
            }
            .frame(minHeight: Theme.Size.minTapTarget)
        } header: {
            Text(String(localized: "editor.section.details", bundle: #bundle))
        }
    }
}

/// The Spots in order: drag to reorder (Edit), swipe to delete, minutes and a note each, then Add Spot.
private struct EditorSpotsSection: View {
    let viewModel: EditorViewModel

    var body: some View {
        Section {
            ForEach(viewModel.spotRows) { row in
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    SpotRow(row, showsReorderHandle: true)
                    Stepper(value: Binding(get: { viewModel.minutes(for: row.id) },
                                           set: { viewModel.setMinutes($0, for: row.id) }),
                            in: 0...600, step: 15) {
                        Text(verbatim: viewModel.minutesText(for: row.id)).font(Theme.Font.subheadline)
                    }
                    TextField(String(localized: "editor.spot.note", bundle: #bundle),
                              text: Binding(get: { viewModel.note(for: row.id) },
                                            set: { viewModel.setNote($0, for: row.id) }))
                        .font(Theme.Font.subheadline)
                        .frame(minHeight: Theme.Size.minTapTarget)
                }
            }
            .onMove { viewModel.moveSpots(from: $0, to: $1) }
            .onDelete { viewModel.removeSpots(at: $0) }

            Button {
                viewModel.addSpotTapped()
            } label: {
                Label(String(localized: "editor.addSpot", bundle: #bundle), systemImage: "plus.circle.fill")
                    .font(Theme.Font.headline)
                    .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget, alignment: .leading)
            }
            .disabled(!viewModel.canAddSpot)
            .accessibilityIdentifier("editor.addSpot")
        } header: {
            HStack {
                Text(String(localized: "editor.section.spots", bundle: #bundle))
                Spacer(minLength: Theme.Spacing.small)
                EditButton().font(Theme.Font.subheadline)
            }
        } footer: {
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                if let error = viewModel.spotCountError { Label(error, systemImage: "exclamationmark.circle") }
                if let warning = viewModel.duplicateWarning { Label(warning, systemImage: "exclamationmark.triangle") }
            }
        }
    }
}

/// Budget per person (₹, whole rupees) and the estimated time.
private struct EditorBudgetSection: View {
    @Bindable var viewModel: EditorViewModel

    var body: some View {
        Section {
            HStack(spacing: Theme.Spacing.medium) {
                TextField(String(localized: "editor.budget.from", bundle: #bundle), value: $viewModel.budgetLower,
                          format: .number)
                Text(verbatim: "–").accessibilityHidden(true)
                TextField(String(localized: "editor.budget.to", bundle: #bundle), value: $viewModel.budgetUpper,
                          format: .number)
            }
            .keyboardType(.numberPad)
            .font(Theme.Font.body)
            .frame(minHeight: Theme.Size.minTapTarget)
            .onChange(of: viewModel.budgetLower) { _, _ in viewModel.edited() }
            .onChange(of: viewModel.budgetUpper) { _, _ in viewModel.edited() }
            Stepper(value: Binding(get: { viewModel.estimatedMinutes }, set: { viewModel.setEstimate($0) }),
                    in: 0...1440, step: 15) {
                Text(verbatim: viewModel.estimatedText).font(Theme.Font.body)
            }
        } header: {
            Text(String(localized: "editor.section.budget", bundle: #bundle))
        } footer: {
            if let error = viewModel.budgetError { Text(verbatim: error).foregroundStyle(Theme.Color.critical) }
        }
    }
}

/// A titled set of chips from a fixed list.
private struct EditorChipsSection: View {
    let title: String
    let chips: [EditorChip]
    let selected: Set<String>
    let toggle: (EditorChip) -> Void

    var body: some View {
        Section {
            FlowLayout(spacing: Theme.Spacing.small, lineSpacing: Theme.Spacing.small) {
                ForEach(chips) { chip in
                    FilterChip(verbatim: chip.title, isSelected: selected.contains(chip.id)) { toggle(chip) }
                }
            }
        } header: {
            Text(verbatim: title)
        }
    }
}
