import Design
import SwiftUI

/// Layout only: how to report, who to contact, and the legal documents.
struct HelpView: View {
    @State private var viewModel: HelpViewModel

    init(viewModel: HelpViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Text(verbatim: viewModel.intro)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section {
                VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                    Text(verbatim: viewModel.reportTitle).font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(verbatim: viewModel.reportSubtitle).font(Theme.Font.subheadline)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.tiny)
                NavRow(verbatim: viewModel.blockedTitle, systemImage: "hand.raised") { viewModel.blockedTapped() }
            } header: {
                Text(verbatim: viewModel.safetyHeader)
            }
            Section {
                InfoRow(verbatim: viewModel.supportLabel, value: viewModel.pendingValue)
                    .textSelection(.enabled)
                InfoRow(verbatim: viewModel.grievanceLabel, value: viewModel.pendingValue)
                    .textSelection(.enabled)
            } header: {
                Text(verbatim: viewModel.contactHeader)
            } footer: {
                Text(verbatim: viewModel.grievanceFooter)
            }
            Section {
                InfoRow(verbatim: viewModel.termsLabel, value: viewModel.pendingValue)
                InfoRow(verbatim: viewModel.privacyLabel, value: viewModel.pendingValue)
            } header: {
                Text(verbatim: viewModel.documentsHeader)
            }
        }
        .listStyle(.insetGrouped)
        .vybeListBackground()
        .navigationTitle(Text(verbatim: viewModel.title))
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
    }
}
