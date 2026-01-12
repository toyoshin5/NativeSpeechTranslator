import Foundation

enum GeminiClient {
    struct Request: Encodable {
        let contents: [Content]
        let generationConfig: GenerationConfig

        struct Content: Encodable {
            let parts: [Part]
        }

        struct Part: Encodable {
            let text: String
        }

        struct GenerationConfig: Encodable {
            let temperature: Double
        }
    }

    struct Response: Decodable {
        let candidates: [Candidate]

        struct Candidate: Decodable {
            let content: Content
        }

        struct Content: Decodable {
            let parts: [Part]
        }

        struct Part: Decodable {
            let text: String
        }
    }

    struct ErrorResponse: Decodable {
        let error: ErrorDetail

        struct ErrorDetail: Decodable {
            let message: String
        }
    }

    static func translate(original: String, direct: String, model: String, apiKey: String) async -> String {
        guard !apiKey.isEmpty else { return direct }

        let prompt = """
            \(TranslationPrompt.systemPrompt)
            
            \(TranslationPrompt.userPrompt(original: original, direct: direct))
            """

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            return direct
        }

        let request = Request(
            contents: [Request.Content(parts: [Request.Part(text: prompt)])],
            generationConfig: Request.GenerationConfig(temperature: 0.3)
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            let response = try JSONDecoder().decode(Response.self, from: data)
            let result = response.candidates.first?.content.parts.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? direct
            print("[LLM] Gemini: '\(original.prefix(30))...' -> '\(result.prefix(30))...'")
            return result
        } catch {
            print("[LLM] Gemini API error: \(error)")
            return direct
        }
    }

    static func testConnection(model: String, apiKey: String) async -> Result<Void, Error> {
        guard !apiKey.isEmpty else { return .failure(LLMError.emptyAPIKey) }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            return .failure(LLMError.invalidURL)
        }

        let request = Request(
            contents: [Request.Content(parts: [Request.Part(text: TranslationPrompt.testMessage)])],
            generationConfig: Request.GenerationConfig(temperature: 0.3)
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    return .failure(LLMError.apiError(statusCode: httpResponse.statusCode, message: errorResponse.error.message))
                }
                return .failure(LLMError.apiError(statusCode: httpResponse.statusCode, message: "Unknown error"))
            }

            _ = try JSONDecoder().decode(Response.self, from: data)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
