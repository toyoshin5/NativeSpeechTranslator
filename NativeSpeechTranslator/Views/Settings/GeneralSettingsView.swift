import SwiftUI
import Translation
import FoundationModels
import Dependencies

struct GeneralSettingsView: View {
    @AppStorage("sourceLanguage") private var sourceLanguage: String = "en-US"
    @AppStorage("targetLanguage") private var targetLanguage: String = "ja-JP"
    
    @AppStorage("llmTranslationEnabled") private var llmTranslationEnabled: Bool = false
    @AppStorage("llmProvider") private var llmProviderString: String = "foundation"
    @AppStorage("llmModel") private var llmModel: String = "default"
    @AppStorage("openaiAPIKey") private var openaiAPIKey: String = ""
    @AppStorage("groqAPIKey") private var groqAPIKey: String = ""
    @AppStorage("cerebrasAPIKey") private var cerebrasAPIKey: String = ""

    @State private var connectionTestResult: ConnectionTestResult?
    @State private var isTestingConnection = false

    private var llmProvider: LLMProvider {
        LLMProvider(rawValue: llmProviderString) ?? .foundation
    }

    private var currentAPIKey: String {
        switch llmProvider {
        case .openai: return openaiAPIKey
        case .groq: return groqAPIKey
        case .cerebras: return cerebrasAPIKey
        case .foundation: return ""
        }
    }

    private var providerBinding: Binding<String> {
        Binding(
            get: { llmProviderString },
            set: { newValue in
                llmProviderString = newValue
                connectionTestResult = nil
                if let provider = LLMProvider(rawValue: newValue),
                   let firstModel = provider.availableModels.first {
                    llmModel = firstModel
                }
            }
        )
    }

    private var isFoundationModelsAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }
    
    @Dependency(\.translationClient) var translationClient

    var body: some View {
        Form {
            Section("言語設定") {
                Picker("入力言語 (Source)", selection: $sourceLanguage) {
                    ForEach(SupportedLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .onChange(of: sourceLanguage) { _, newValue in
                    if newValue == targetLanguage {
                        // If source becomes same as target, try to switch target to something else (e.g. English or Japanese)
                        if newValue == "en-US" { targetLanguage = "ja-JP" }
                        else { targetLanguage = "en-US" }
                    }
                    
                    Task {
                        await translationClient.updateLanguages(
                            Locale(identifier: sourceLanguage),
                            Locale(identifier: targetLanguage)
                        )
                    }
                }

                Picker("出力言語 (Target)", selection: $targetLanguage) {
                    ForEach(SupportedLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .onChange(of: targetLanguage) { _, newValue in
                    if newValue == sourceLanguage {
                        if newValue == "en-US" { sourceLanguage = "ja-JP" }
                        else { sourceLanguage = "en-US" }
                    }
                    
                    Task {
                        await translationClient.updateLanguages(
                            Locale(identifier: sourceLanguage),
                            Locale(identifier: targetLanguage)
                        )
                    }
                }
            }

            AppleTranslationSettingsView()
            
            Section("LLM翻訳") {
                Toggle("LLM翻訳を有効化", isOn: $llmTranslationEnabled)

                if llmTranslationEnabled {
                    LabeledContent("プロバイダー") {
                        Picker("", selection: providerBinding) {
                            ForEach(LLMProvider.allCases) { provider in
                                Text(provider.displayName).tag(provider.rawValue)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                    }

                    LabeledContent("モデル") {
                        Picker("", selection: $llmModel) {
                            ForEach(llmProvider.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
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
                        case .groq:
                            SecureField("Groq API Key", text: $groqAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: groqAPIKey) { _, _ in connectionTestResult = nil }
                        case .cerebras:
                            SecureField("Cerebras API Key", text: $cerebrasAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: cerebrasAPIKey) { _, _ in connectionTestResult = nil }
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
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil

        Task {         
            let result = await TranslationLLMService.testConnection(
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

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en-US"
    case spanish = "es-ES"
    case french = "fr-FR"
    case german = "de-DE"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    case chinese = "zh-CN"
    case italian = "it-IT"
    case portuguese = "pt-PT"

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .chinese: return "Chinese"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        }
    }
}

#Preview {
    GeneralSettingsView()
}
