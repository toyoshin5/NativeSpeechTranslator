import Dependencies
import Foundation

actor TranslationLLMService {
    static let shared = TranslationLLMService()

    private var currentTask: Task<String, Never>?

    private init() {}

    func translate(original: String, direct: String, sourceLanguage: String, targetLanguage: String)
        async -> String
    {
        let providerString = UserDefaults.standard.string(forKey: "llmProvider") ?? "foundation"
        let provider = LLMProvider(rawValue: providerString) ?? .foundation
        let model =
            UserDefaults.standard.string(forKey: "llmModel") ?? provider.availableModels.first ?? ""

        let task = Task<String, Never> {
            switch provider {
            case .openai:
                return await OpenAICompatibleService.translate(
                    original: original,
                    direct: direct,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    model: model,
                    apiKey: UserDefaults.standard.string(forKey: "openaiAPIKey") ?? "",
                    baseURL: "https://api.openai.com/v1/chat/completions"
                )
            case .groq:
                return await OpenAICompatibleService.translate(
                    original: original,
                    direct: direct,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    model: model,
                    apiKey: UserDefaults.standard.string(forKey: "groqAPIKey") ?? "",
                    baseURL: "https://api.groq.com/openai/v1/chat/completions"
                )
            case .cerebras:
                return await OpenAICompatibleService.translate(
                    original: original,
                    direct: direct,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    model: model,
                    apiKey: UserDefaults.standard.string(forKey: "cerebrasAPIKey") ?? "",
                    baseURL: "https://api.cerebras.ai/v1/chat/completions"
                )
            case .foundation:
                return await FoundationModelService.shared.refine(
                    original: original,
                    direct: direct,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage
                )
            }
        }

        currentTask = task
        return await task.value
    }

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        Task { await FoundationModelService.shared.reset() }
    }

    static func testConnection(provider: LLMProvider, model: String, apiKey: String) async
        -> Result<Void, Error>
    {
        switch provider {
        case .openai:
            return await OpenAICompatibleService.testConnection(
                model: model,
                apiKey: apiKey,
                baseURL: "https://api.openai.com/v1/chat/completions"
            )
        case .groq:
            return await OpenAICompatibleService.testConnection(
                model: model,
                apiKey: apiKey,
                baseURL: "https://api.groq.com/openai/v1/chat/completions"
            )
        case .cerebras:
            return await OpenAICompatibleService.testConnection(
                model: model,
                apiKey: apiKey,
                baseURL: "https://api.cerebras.ai/v1/chat/completions"
            )
        case .foundation:
            return .success(())
        }
    }
}
