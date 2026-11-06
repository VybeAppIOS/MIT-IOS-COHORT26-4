import Design
import SwiftUI

/// Layout only: version, photo credits (loaded), licences. The version and licences show even if credits fail.
struct AboutView: View {
    @State private var viewModel: AboutViewModel

    init(viewModel: AboutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Text(verbatim: viewModel.tagline)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                InfoRow(verbatim: viewModel.versionLabel, value: viewModel.version)
            }
            Section {
                credits
            } header: {
                Text(verbatim: viewModel.creditsHeader)
            }
            Section {
                Text(verbatim: viewModel.licencesBody)
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.Color.textSecondary)
            } header: {
                Text(verbatim: viewModel.licencesHeader)
            }
        }
        .listStyle(.insetGrouped)
        .vybeListBackground()
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.reload() }
        .hidesTabBar()
    }

    /// The credits part follows the load state inside its own section, so the rest of the page never waits.
    @ViewBuilder private var credits: some View {
        switch viewModel.state {
        case .loading:
            InfoRow(verbatim: "EXAMPLE Café", value: "EXAMPLE Teammate").redacted(reason: .placeholder)
        case .loaded(let rows, _):
            ForEach(rows) { row in InfoRow(verbatim: row.placeName, value: row.credit) }
        case .empty:
            Text(verbatim: viewModel.creditsEmpty)
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.Color.textSecondary)
        case .failed(let error):
            ErrorView(error) { Task { await viewModel.reload() } }
        }
    }
}
