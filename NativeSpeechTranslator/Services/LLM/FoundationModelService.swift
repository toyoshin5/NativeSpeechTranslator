import Foundation
import FoundationModels

actor FoundationModelService {
    static let shared = FoundationModelService()

    private var session: LanguageModelSession?
    private var requestsQueue: [(original: String, direct: String, continuation: CheckedContinuation<String, Never>)] = []
    private var isProcessing = false
    private var processingTask: Task<Void, Never>?

    private init() {}

    func refine(original: String, direct: String) async -> String {
        await withCheckedContinuation { continuation in
            requestsQueue.append((original: original, direct: direct, continuation: continuation))
            if !isProcessing {
                processingTask = Task { await processQueue() }
            }
        }
    }

    func reset() {
        processingTask?.cancel()
        processingTask = nil

        for request in requestsQueue {
            request.continuation.resume(returning: request.direct)
        }
        requestsQueue.removeAll()
        session = nil
        isProcessing = false
    }

    private func processQueue() async {
        isProcessing = true
        while !requestsQueue.isEmpty {
            guard !Task.isCancelled else { break }

            let request = requestsQueue.removeFirst()
            let result = await performRefinement(original: request.original, direct: request.direct)
            request.continuation.resume(returning: result)
        }
        isProcessing = false
    }

    private func performRefinement(original: String, direct: String) async -> String {
        guard !Task.isCancelled else { return direct }

        if session == nil {
            session = LanguageModelSession(instructions: TranslationPrompt.systemPrompt)
        }

        guard let session = session else { return direct }

        do {
            let response = try await session.respond(to: TranslationPrompt.userPrompt(original: original, direct: direct))
            print("[LLM] Foundation: '\(original.prefix(30))...' -> '\(response.content.prefix(30))...'")
            return response.content
        } catch {
            print("[LLM] Foundation Models error: \(error)")
            self.session = nil
            return direct
        }
    }
}
