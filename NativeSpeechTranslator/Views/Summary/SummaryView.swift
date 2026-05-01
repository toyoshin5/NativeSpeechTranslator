import SwiftUI

struct SummaryView: View {
    @State var viewModel: SummaryViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text("要約を生成中...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("再試行") {
                        viewModel.retry()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.summaryText.isEmpty {
                Text("要約するデータがありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(viewModel.summaryText)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(viewModel.summaryText, forType: .string)
                } label: {
                    Label("コピー", systemImage: "doc.on.doc")
                }
                .help("要約をコピー")
                .disabled(viewModel.summaryText.isEmpty)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.retry()
                } label: {
                    Label("再要約", systemImage: "arrow.clockwise")
                }
                .help("再要約")
                .disabled(viewModel.isLoading)
            }
        }
    }
}
