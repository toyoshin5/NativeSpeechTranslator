import Dependencies
import Foundation
import Testing

@testable import NativeSpeechTranslator

@Suite("OpenAICompatibleService Tests")
@MainActor
struct OpenAICompatibleServiceTests {

    @Test("正常系: 翻訳リクエストが正しく送信され、結果が返る")
    func testTranslationSuccess() async throws {
        // Given
        let expectedResponse = """
            {
                "choices": [
                    {
                        "message": {
                            "content": "Hello world"
                        }
                    }
                ]
            }
            """
        let mockData = expectedResponse.data(using: .utf8)!

        let service = withDependencies {
            $0.httpClient.data = { request in
                // Verify Request
                #expect(request.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
                #expect(request.httpMethod == "POST")
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
                #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

                // Verify Body
                let body = try JSONDecoder().decode(OpenAICompatibleService.Request.self, from: request.httpBody!)
                #expect(body.model == "gpt-4")
                #expect(body.messages.count == 2)
                #expect(body.messages[0].role == "system")
                #expect(body.messages[1].role == "user")

                return (mockData, URLResponse())
            }
        } operation: {
            OpenAICompatibleService()
        }

        // When
        let result = await service.translate(
            original: "こんにちは",
            direct: "Hello",
            sourceLanguage: "Japanese",
            targetLanguage: "English",
            model: "gpt-4",
            apiKey: "sk-test",
            baseURL: "https://api.openai.com/v1/chat/completions"
        )

        // Then
        #expect(result == "Hello world")
    }

    @Test("異常系: APIキーが空の場合は直訳を返す")
    func testEmptyAPIKeyReturnsDirectTranslation() async {
        // Given
        let service = withDependencies {
            $0.httpClient.data = { _ in
                // Should not actually be called
                (Data(), URLResponse())
            }
        } operation: {
            OpenAICompatibleService()
        }

        // When
        let result = await service.translate(
            original: "こんにちは",
            direct: "Hello",
            sourceLanguage: "Japanese",
            targetLanguage: "English",
            model: "gpt-4",
            apiKey: "",
            baseURL: "https://api.openai.com/v1/chat/completions"
        )

        // Then
        #expect(result == "Hello")
    }

    @Test("異常系: ネットワークエラー時は直訳を返す")
    func testNetworkErrorReturnsDirectTranslation() async {
        // Given
        let service = withDependencies {
            $0.httpClient.data = { _ in
                throw URLError(.notConnectedToInternet)
            }
        } operation: {
            OpenAICompatibleService()
        }

        // When
        let result = await service.translate(
            original: "こんにちは",
            direct: "Hello",
            sourceLanguage: "Japanese",
            targetLanguage: "English",
            model: "gpt-4",
            apiKey: "sk-test",
            baseURL: "https://api.openai.com/v1/chat/completions"
        )

        // Then
        #expect(result == "Hello")
    }
    
    @Test("接続テスト: 成功時")
    func testConnectionSuccess() async throws {
         // Given
        let expectedResponse = """
            {
                "choices": [
                    {
                        "message": {
                            "content": "Hello"
                        }
                    }
                ]
            }
            """
        let mockData = expectedResponse.data(using: .utf8)!
        
        let service = withDependencies {
            $0.httpClient.data = { request in
                return (
                    mockData,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                )
            }
        } operation: {
            OpenAICompatibleService()
        }
        
        // When
        let result = await service.testConnection(
            model: "gpt-4", 
            apiKey: "sk-test", 
            baseURL: "https://api.openai.com/v1/chat/completions"
        )
        
        // Then
        #expect(try result.get() == ())
    }
    
    @Test("接続テスト: APIエラー時")
    func testConnectionAPIError() async throws {
         // Given
        let errorResponse = "Unauthorized"
        let mockData = errorResponse.data(using: .utf8)!
        
        let service = withDependencies {
            $0.httpClient.data = { request in
                return (
                    mockData,
                    HTTPURLResponse(
                        url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                )
            }
        } operation: {
            OpenAICompatibleService()
        }
        
        // When
        let result = await service.testConnection(
            model: "gpt-4", 
            apiKey: "sk-test", 
            baseURL: "https://api.openai.com/v1/chat/completions"
        )
        
        // Then
        switch result {
        case .success:
            #expect(Bool(false), "Should have failed")
        case .failure(let error):
            if let llmError = error as? LLMError, case .apiError(let statusCode, let message) = llmError {
                #expect(statusCode == 401)
                #expect(message == "Unauthorized")
            } else {
                #expect(Bool(false), "Unexpected error type")
            }
        }
    }
}

