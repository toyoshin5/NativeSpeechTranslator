import Foundation
import FoundationModels

actor SummaryLLMService {
    static let shared = SummaryLLMService()

    private init() {}

    func summarize(transcripts: [String]) async throws -> String {
        let providerString = UserDefaults.standard.string(forKey: "llmProvider") ?? "foundation"
        let provider = LLMProvider(rawValue: providerString) ?? .foundation

        let userMessage = SummaryPrompt.userPrompt(transcripts: transcripts)

        switch provider {
        case .openai:
            let model =
                UserDefaults.standard.string(forKey: "llmModel")
                ?? provider.availableModels.first ?? ""
            return try await OpenAICompatibleService().chatCompletion(
                systemPrompt: SummaryPrompt.systemPrompt,
                userMessage: userMessage,
                model: model,
                apiKey: UserDefaults.standard.string(forKey: "openaiAPIKey") ?? "",
                baseURL: "https://api.openai.com/v1/chat/completions"
            )
        case .groq:
            let model =
                UserDefaults.standard.string(forKey: "llmModel")
                ?? provider.availableModels.first ?? ""
            return try await OpenAICompatibleService().chatCompletion(
                systemPrompt: SummaryPrompt.systemPrompt,
                userMessage: userMessage,
                model: model,
                apiKey: UserDefaults.standard.string(forKey: "groqAPIKey") ?? "",
                baseURL: "https://api.groq.com/openai/v1/chat/completions"
            )
        case .custom:
            let customModel = UserDefaults.standard.string(forKey: "customModel") ?? ""
            let customBaseURL = UserDefaults.standard.string(forKey: "customBaseURL") ?? ""
            return try await OpenAICompatibleService().chatCompletion(
                systemPrompt: SummaryPrompt.systemPrompt,
                userMessage: userMessage,
                model: customModel,
                apiKey: UserDefaults.standard.string(forKey: "customAPIKey") ?? "",
                baseURL: customBaseURL
            )
        case .foundation:
            let session = LanguageModelSession(instructions: SummaryPrompt.systemPrompt)
            let response = try await session.respond(to: userMessage)
            return response.content
        }
    }
}
