import Dependencies
import Foundation

struct TranslationLLMClient {
    var translate: @Sendable (String, String) async -> String
    var reset: @Sendable () async -> Void
}

extension DependencyValues {
    var translationLLMClient: TranslationLLMClient {
        get { self[TranslationLLMClient.self] }
        set { self[TranslationLLMClient.self] = newValue }
    }
}

extension TranslationLLMClient: DependencyKey {
    static let liveValue = TranslationLLMClient(
        translate: { originalText, directTranslation in
            await LLMTranslationService.shared.translate(original: originalText, direct: directTranslation)
        },
        reset: {
            await LLMTranslationService.shared.reset()
        }
    )

    static let testValue = TranslationLLMClient(
        translate: { _, direct in direct },
        reset: {}
    )

    static let previewValue = TranslationLLMClient(
        translate: { _, _ in "Preview LLM Translation" },
        reset: {}
    )
}
