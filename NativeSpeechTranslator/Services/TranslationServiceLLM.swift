import Foundation
import FoundationModels

actor TranslationServiceLLM {

    static let shared = TranslationServiceLLM()

    private var session: LanguageModelSession?
    private var requestsQueue: [(text: String, continuation: CheckedContinuation<String, Never>)] =
        []
    private var isProcessing = false

    private init() {}

    func translate(_ text: String) async -> String {
        await withCheckedContinuation { continuation in
            requestsQueue.append((text: text, continuation: continuation))
            if !isProcessing {
                Task { await processQueue() }
            }
        }
    }
    
    func reset() {
        for request in requestsQueue {
            request.continuation.resume(returning: "Translation Cancelled")
        }
        
        requestsQueue.removeAll()
        session = nil
        isProcessing = false
    }

    private func processQueue() async {
        isProcessing = true
        // キューが空になるまで
        while !requestsQueue.isEmpty {
            let request = requestsQueue.removeFirst()
            let result = await performTranslation(request.text)
            request.continuation.resume(returning: result)
        }

        isProcessing = false
    }

    private func performTranslation(_ text: String) async -> String {
        if session == nil {
            session = LanguageModelSession()
        }

        guard let session = session else { return "モデル準備中..." }

        let systemPrompt =
            "You are a professional interpreter. Translate the following text into natural Japanese immediately."
        let prompt = "\(systemPrompt)\n\n\(text)"

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("Translation error: \(error)")
            self.session = nil
            return "翻訳エラー"
        }
    }
}
