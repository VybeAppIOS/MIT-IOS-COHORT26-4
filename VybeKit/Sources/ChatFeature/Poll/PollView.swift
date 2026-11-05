import Design
import SwiftUI

/// Layout only: every value comes from `PollViewModel`, every tap goes to it. A local sheet with its own stack.
struct PollView: View {
    @State private var viewModel: PollViewModel
    @FocusState private var focused: Bool

    init(viewModel: PollViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(text: $viewModel.question, axis: .vertical) { Text(verbatim: viewModel.placeholder) }
                        .lineLimit(1...4)
                        .focused($focused)
                        .frame(minHeight: Theme.Size.minTapTarget)
                } header: { Text(verbatim: viewModel.questionLabel) }
                Section {
                    ForEach(viewModel.options, id: \.self) { option in
                        Label { Text(verbatim: option) } icon: { Image(systemName: "circle") }
                            .frame(minHeight: Theme.Size.minTapTarget)
                            .foregroundStyle(Theme.Color.textPrimary)
                    }
                } header: { Text(verbatim: viewModel.optionsHeader) }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text(verbatim: viewModel.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { viewModel.cancelTapped() } label: { Text(verbatim: viewModel.cancelLabel) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await viewModel.sendTapped() } } label: { Text(verbatim: viewModel.sendLabel) }
                        .disabled(!viewModel.canSend)
                }
            }
            .task { focused = true }
            .alert(
                Text(verbatim: viewModel.notice ?? ""),
                isPresented: Binding(get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } })
            ) {
                Button(role: .cancel) {} label: { Text(verbatim: viewModel.okLabel) }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
