import Design
import SwiftUI

/// Layout only: a grouped list of settings pages, then "Reset onboarding" on its own (destructive, confirmed).
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        NavRow(verbatim: row.title, systemImage: row.systemImage) { viewModel.rowTapped(row) }
                            .accessibilityIdentifier("profile.settings.\(row.id)")
                    }
                } header: {
                    Text(verbatim: section.title)
                }
            }
            Section {
                Button(role: .destructive) {
                    viewModel.resetTapped()
                } label: {
                    Label(viewModel.resetTitle, systemImage: "arrow.counterclockwise")
                        .font(Theme.Font.body)
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget, alignment: .leading)
                }
                .foregroundStyle(Theme.Color.critical)
                .accessibilityIdentifier("profile.settings.reset")
            } header: {
                Text(verbatim: viewModel.startAgainTitle)
            } footer: {
                Text(verbatim: viewModel.resetSubtitle)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Text(verbatim: viewModel.title))
        .confirmationDialog(viewModel.resetConfirmTitle, isPresented: $viewModel.isConfirmingReset,
                            titleVisibility: .visible) {
            Button(viewModel.resetConfirmButton, role: .destructive) { viewModel.resetConfirmed() }
            Button(SharedStrings.cancel, role: .cancel) {}
        } message: {
            Text(verbatim: viewModel.resetConfirmMessage)
        }
    }
}
