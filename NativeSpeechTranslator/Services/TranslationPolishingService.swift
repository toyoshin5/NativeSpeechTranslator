import Foundation
import FoundationModels

@Generable
struct PolishedTranslation {
    @Guide(description: "The refined Japanese translation that is more fluent and natural")
    var refinedTranslation: String
}

actor TranslationPolishingService {

    static let shared = TranslationPolishingService()

    private var session: LanguageModelSession?
    private var requestsQueue: [(originalText: String, translatedText: String, continuation: CheckedContinuation<String, Never>)] = []
    private var isProcessing = false

    private let instructions = """
        You are a professional Japanese translation editor.
        Your task is to refine English-to-Japanese translations to make them more fluent and natural.
        Consider the context of previous translations in the conversation.
        Maintain the original meaning while improving readability and naturalness.
        Output only the refined Japanese translation without any explanation or additional text.
        """

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
            session = LanguageModelSession(instructions: instructions)
        }
        print("O:\(originalText)")
        print("AT:\(translatedText)")

        guard let session = session else { return translatedText }

        let prompt = """
            Original English: \(originalText)
            Current Japanese translation: \(translatedText)
            
            Please refine the Japanese translation.
            """

        do {
            let response = try await session.respond(to: prompt, generating: PolishedTranslation.self)
            print("BT:\(response.content.refinedTranslation)")
            return response.content.refinedTranslation
        } catch {
            print("Polishing error: \(error)")
            self.session = nil
            return translatedText
        }
    }
}
