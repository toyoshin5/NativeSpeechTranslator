import SwiftUI
import Translation

struct AppleTranslationSettingsView: View {
    @State private var downloadConfiguration: TranslationSession.Configuration?
    @State private var status: LanguageAvailability.Status?
    @State private var errorMessage: String?

    private let targetLanguage = Locale.Language(identifier: "ja")

    var body: some View {
        Section("翻訳モデル") {
            HStack {
                if let status = status {
                    switch status {
                    case .installed:
                        Label("インストール済み", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    case .supported:
                        Label("ダウンロード可能", systemImage: "arrow.down.circle").foregroundStyle(.orange)
                    case .unsupported:
                        Label("非対応", systemImage: "xmark.circle").foregroundStyle(.red)
                    @unknown default:
                        Text("不明なステータス")
                    }
                } else {
                    ProgressView().controlSize(.small)
                }

                Spacer()

                if status == .supported {
                    Button("ダウンロード") {
                        startDownload()
                    }
                } else if status == .installed {
                    Button("再確認") {
                        Task { await checkStatus() }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .task {
            await checkStatus()
        }
        .translationTask(downloadConfiguration) { session in
            do {
                if let config = downloadConfiguration {
                    print("Starting preparation for \(config)")
                    try await session.prepareTranslation()
                    print("Preparation complete")
                    await checkStatus()
                }
            } catch {
                print("Prepare error: \(error)")
                self.errorMessage = error.localizedDescription
            }
            downloadConfiguration = nil
        }
    }

    private func startDownload() {
        let source = Locale.current.language
        downloadConfiguration = TranslationSession.Configuration(source: source, target: targetLanguage)
    }

    private func checkStatus() async {
        let availability = LanguageAvailability()
        let source = Locale.current.language
        let status = await availability.status(from: source, to: targetLanguage)
        self.status = status
    }
}
