import Dependencies
import Foundation

struct TranslationClient {
    var translate: @Sendable (String) async -> String
    var translateWithLLM: @Sendable (String, String) async -> String
    var reset: @Sendable () async -> Void
}

extension DependencyValues {
    var translationClient: TranslationClient {
        get { self[TranslationClient.self] }
        set { self[TranslationClient.self] = newValue }
    }
}

extension TranslationClient: DependencyKey {
    @MainActor
    static let liveValue = TranslationClient(
        translate: { text in
            do {
                return try await TranslationService.shared.translate(text)
            } catch {
                return "Translation Error: \(error.localizedDescription)"
            }
        },
        translateWithLLM: { original, direct in
            @Dependency(\.translationLLMClient) var llmClient
            return await llmClient.translate(original, direct)
        },
        reset: {
            await TranslationService.shared.reset()
            await FoundationModelService.shared.reset()
        }
    )

    static let testValue = TranslationClient(
        translate: { _ in "Test Translation" },
        translateWithLLM: { _, direct in direct },
        reset: {}
    )

    static let previewValue = TranslationClient(
        translate: { _ in "Preview Translation" },
        translateWithLLM: { _, _ in "Preview LLM Translation" },
        reset: {}
    )
}
