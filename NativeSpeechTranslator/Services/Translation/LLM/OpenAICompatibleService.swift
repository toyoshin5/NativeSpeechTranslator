import Dependencies
import Foundation

struct OpenAICompatibleService {
    @Dependency(\.httpClient) var httpClient: any HTTPClient
    
    init() {}
    
    struct Request: Codable {
        let model: String
        let messages: [Message]

        struct Message: Codable {
            let role: String
            let content: String
        }
    }

    struct Response: Decodable {
        let choices: [Choice]

        struct Choice: Decodable {
            let message: Message
        }

        struct Message: Decodable {
            let content: String
        }
    }

    func translate(
        original: String, direct: String, sourceLanguage: String, targetLanguage: String,
        model: String, apiKey: String, baseURL: String
    ) async -> String {
        guard !apiKey.isEmpty else { return direct }
        guard let url = URL(string: baseURL) else { return direct }

        let request = Request(
            model: model,
            messages: [
                Request.Message(
                    role: "system",
                    content: TranslationPrompt.systemPrompt(
                        sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)),
                Request.Message(
                    role: "user",
                    content: TranslationPrompt.userPrompt(original: original, direct: direct)),
            ],
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            // Use injected httpClient
            let (data, _) = try await httpClient.data(for: urlRequest)
            let response = try JSONDecoder().decode(Response.self, from: data)
            let result =
                response.choices.first?.message.content.trimmingCharacters(
                    in: .whitespacesAndNewlines) ?? direct
            print(
                "[LLM] OpenAI Compatible: '\(original.prefix(30))...' -> '\(result.prefix(30))...'")
            return result
        } catch {
            print("[LLM] OpenAI Compatible API error: \(error)")
            return direct
        }
    }

    func testConnection(model: String, apiKey: String, baseURL: String) async -> Result<
        Void, Error
    > {
        guard !apiKey.isEmpty else { return .failure(LLMError.emptyAPIKey) }
        guard let url = URL(string: baseURL) else { return .failure(LLMError.invalidURL) }

        let request = Request(
            model: model,
            messages: [Request.Message(role: "user", content: TranslationPrompt.testMessage)],
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            // Use injected httpClient
            let (data, response) = try await httpClient.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                return .failure(
                    LLMError.apiError(statusCode: httpResponse.statusCode, message: errorMessage))
            }

            _ = try JSONDecoder().decode(Response.self, from: data)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

enum LLMError: LocalizedError {
    case emptyAPIKey
    case invalidURL
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .emptyAPIKey: return "APIキーが空です"
        case .invalidURL: return "無効なURLです"
        case .apiError(let statusCode, let message): return "APIエラー (\(statusCode)): \(message)"
        }
    }
}
