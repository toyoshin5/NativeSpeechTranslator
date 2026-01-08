import Foundation
import FoundationModels

actor TranslationPolishingService {

    static let shared = TranslationPolishingService()

    private var session: LanguageModelSession?
    private var requestsQueue: [(originalText: String, translatedText: String, continuation: CheckedContinuation<String, Never>)] = []
    private var isProcessing = false

    private init() {}

    func polish(originalText: String, translatedText: String) async -> String {
        await withCheckedContinuation { continuation in
            requestsQueue.append((originalText: originalText, translatedText: translatedText, continuation: continuation))
            if !isProcessing {
                Task { await processQueue() }
            }
        }
    }

    func reset() {
        for request in requestsQueue {
            request.continuation.resume(returning: request.translatedText)
        }

        requestsQueue.removeAll()
        session = nil
        isProcessing = false
    }

    private func processQueue() async {
        isProcessing = true

        while !requestsQueue.isEmpty {
            let request = requestsQueue.removeFirst()
            let result = await performPolishing(originalText: request.originalText, translatedText: request.translatedText)
            request.continuation.resume(returning: result)
        }

        isProcessing = false
    }

    private func performPolishing(originalText: String, translatedText: String) async -> String {
        if session == nil {
            session = LanguageModelSession()
        }

        guard let session = session else { return translatedText }

        let prompt = """
            I translated "\(originalText)" into "\(translatedText)".
            Please refine this translation to make it more fluent and natural, considering the previous context of our conversation.
            Return only the refined translation, nothing else.
            """

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("Polishing error: \(error)")
            self.session = nil
            return translatedText
        }
    }
}
