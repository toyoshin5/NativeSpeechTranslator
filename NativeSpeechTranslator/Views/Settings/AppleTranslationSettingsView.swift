import SwiftUI
import Translation

struct AppleTranslationSettingsView: View {
    @AppStorage("sourceLanguage") var sourceLanguageIdentifier: String = "en-US"
    @AppStorage("targetLanguage") var targetLanguageIdentifier: String = "ja-JP"

    @State private var downloadConfiguration: TranslationSession.Configuration?
    @State private var status: LanguageAvailability.Status?
    @State private var errorMessage: String?

    private var sourceLanguage: Locale.Language {
        Locale.Language(identifier: sourceLanguageIdentifier)
    }

    private var targetLanguage: Locale.Language {
        Locale.Language(identifier: targetLanguageIdentifier)
    }

    var body: some View {
        Section("翻訳モデル (\(getDisplayLanguageName(for: sourceLanguageIdentifier)) → \(getDisplayLanguageName(for: targetLanguageIdentifier)))") {
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
        .task(id: sourceLanguageIdentifier) { await checkStatus() }
        .task(id: targetLanguageIdentifier) { await checkStatus() }
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
        downloadConfiguration = TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
    }

    private func checkStatus() async {
        let availability = LanguageAvailability()
        let status = await availability.status(from: sourceLanguage, to: targetLanguage)
        self.status = status
    }
    
    private func getDisplayLanguageName(for identifier: String) -> String {
        if let lang = SupportedLanguage(rawValue: identifier){
            return lang.displayName
        }
        return identifier
    }
}
