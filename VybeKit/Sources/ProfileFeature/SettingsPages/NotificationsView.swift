import Components
import Design
import SwiftUI

/// Layout only: one switch per event. No permission prompt here.
struct NotificationsView: View {
    @State private var viewModel: NotificationsViewModel

    init(viewModel: NotificationsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private func retry() { Task { await viewModel.reload() } }

    var body: some View {
        LoadStateView(viewModel.state, onRetry: retry) { switches in
            List {
                Section {
                    ForEach(switches) { item in
                        ToggleRow(verbatim: item.title, subtitle: nil, isOn: Binding(
                            get: { item.isOn },
                            set: { newValue in Task { await viewModel.setSwitch(item.kind, isOn: newValue) } }))
                    }
                } footer: {
                    Text(verbatim: viewModel.footer)
                }
                if viewModel.saveFailed {
                    Section { SafetyNote(viewModel.errorText, style: .warning) }
                }
            }
            .listStyle(.insetGrouped)
        } placeholder: {
            List { Text(verbatim: viewModel.title) }.redacted(reason: .placeholder)
        } empty: {
            EmptyView()
        }
        .background(Theme.Color.surface)
        .navigationTitle(Text(verbatim: viewModel.title))
        .task { await viewModel.load() }
    }
}
