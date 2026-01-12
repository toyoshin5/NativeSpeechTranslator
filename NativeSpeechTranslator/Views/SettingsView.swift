import SwiftUI
import Translation
import FoundationModels

struct SettingsView: View {
    @AppStorage("llmTranslationEnabled") private var llmTranslationEnabled: Bool = false
    @AppStorage("llmProvider") private var llmProviderString: String = "foundation"
    @AppStorage("llmModel") private var llmModel: String = "default"
    @AppStorage("openaiAPIKey") private var openaiAPIKey: String = ""
    @AppStorage("geminiAPIKey") private var geminiAPIKey: String = ""
    @AppStorage("groqAPIKey") private var groqAPIKey: String = ""

    @State private var connectionTestResult: ConnectionTestResult?
    @State private var isTestingConnection = false

    private var llmProvider: LLMProvider {
        LLMProvider(rawValue: llmProviderString) ?? .foundation
    }

    private var currentAPIKey: String {
        switch llmProvider {
        case .openai: return openaiAPIKey
        case .gemini: return geminiAPIKey
        case .groq: return groqAPIKey
        case .foundation: return ""
        }
    }

    private var isFoundationModelsAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    var body: some View {
        Form {
            Section("LLM翻訳") {
                Toggle("LLM翻訳を有効化", isOn: $llmTranslationEnabled)

                if llmTranslationEnabled {
                    Picker("プロバイダー", selection: $llmProviderString) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider.rawValue)
                        }
                    }
                    .onChange(of: llmProviderString) { _, newValue in
                        connectionTestResult = nil
                        if let provider = LLMProvider(rawValue: newValue),
                           let firstModel = provider.availableModels.first {
                            llmModel = firstModel
                        }
                    }

                    Picker("モデル", selection: $llmModel) {
                        ForEach(llmProvider.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }

                    if llmProvider == .foundation && !isFoundationModelsAvailable {
                        Text("このデバイスではApple Intelligenceが利用できません")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            if llmTranslationEnabled && llmProvider.requiresAPIKey {
                Section("APIキー") {
                    HStack {
                        switch llmProvider {
                        case .openai:
                            SecureField("OpenAI API Key", text: $openaiAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: openaiAPIKey) { _, _ in connectionTestResult = nil }
                        case .gemini:
                            SecureField("Gemini API Key", text: $geminiAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: geminiAPIKey) { _, _ in connectionTestResult = nil }
                        case .groq:
                            SecureField("Groq API Key", text: $groqAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: groqAPIKey) { _, _ in connectionTestResult = nil }
                        case .foundation:
                            EmptyView()
                        }

                        Button(action: testConnection) {
                            if isTestingConnection {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("確認")
                            }
                        }
                        .disabled(currentAPIKey.isEmpty || isTestingConnection)
                    }

                    if let result = connectionTestResult {
                        HStack {
                            switch result {
                            case .success:
                                Label("接続成功", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            case .failure(let message):
                                Label(message, systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .font(.caption)
                    }
                }
            }

            AppleTranslationSettingsView()
        }
        .padding()
        .frame(width: 400, height: 380)
    }

    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil

        Task {
            let result = await LLMTranslationService.testConnection(
                provider: llmProvider,
                model: llmModel,
                apiKey: currentAPIKey
            )

            await MainActor.run {
                isTestingConnection = false
                switch result {
                case .success:
                    connectionTestResult = .success
                case .failure(let error):
                    connectionTestResult = .failure(error.localizedDescription)
                }
            }
        }
    }
}

enum ConnectionTestResult {
    case success
    case failure(String)
}

struct AppleTranslationSettingsView: View {
    @State private var downloadConfiguration: TranslationSession.Configuration?
    @State private var status: LanguageAvailability.Status?
    @State private var errorMessage: String?

    private let targetLanguage = Locale.Language(identifier: "ja")

    var body: some View {
        Section("オフラインモデル (日本語翻訳)") {
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

#Preview {
    SettingsView()
}
