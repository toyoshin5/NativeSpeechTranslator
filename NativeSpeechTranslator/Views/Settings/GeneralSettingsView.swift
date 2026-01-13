import SwiftUI
import Translation
import FoundationModels

struct GeneralSettingsView: View {
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

    var body: some View {
        Form {
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
                        .font(.caption)
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

#Preview {
    GeneralSettingsView()
}
