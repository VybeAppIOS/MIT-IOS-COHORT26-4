import Core
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
            Section {
                Picker(selection: $viewModel.appearance) {
                    ForEach(AppearanceChoice.allCases, id: \.self) { choice in
                        Text(verbatim: viewModel.appearanceName(choice)).tag(choice)
                    }
                } label: {
                    Text(verbatim: viewModel.appearanceTitle)
                }
                .pickerStyle(.segmented)
                .frame(minHeight: Theme.Size.minTapTarget)
                .accessibilityIdentifier("profile.settings.appearance")
            } header: {
                Text(verbatim: viewModel.appearanceTitle)
            }
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
        .vybeListBackground()
        .navigationTitle(Text(verbatim: viewModel.title))
        .confirmationDialog(viewModel.resetConfirmTitle, isPresented: $viewModel.isConfirmingReset,
                            titleVisibility: .visible) {
            Button(viewModel.resetConfirmButton, role: .destructive) { viewModel.resetConfirmed() }
            Button(SharedStrings.cancel, role: .cancel) {}
        } message: {
            Text(verbatim: viewModel.resetConfirmMessage)
        }
        .hidesTabBar()
    }
}
