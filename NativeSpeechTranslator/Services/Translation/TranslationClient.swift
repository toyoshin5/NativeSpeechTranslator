import Dependencies
import Foundation

struct TranslationClient {
    var translate: @Sendable (String) async -> String
    var translateWithLLM: @Sendable (String, String, String, String) async -> String
    var refreshLanguages: @Sendable () async -> Void
    var reset: @Sendable () async -> Void
    var isTranslationModelInstalled: @Sendable (Locale.Language, Locale.Language) async -> Bool
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
        translateWithLLM: { original, direct, sourceLanguage, targetLanguage in
            await TranslationLLMService.shared.translate(
                original: original,
                direct: direct,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
        },
        refreshLanguages: {
            await TranslationService.shared.reset()
        },
        reset: {
            await TranslationService.shared.reset()
            await FoundationModelService.shared.reset()
        },
        isTranslationModelInstalled: { source, target in
            await TranslationService.shared.isTranslationModelInstalled(source: source, target: target)
        }
    )

    static let testValue = TranslationClient(
        translate: { _ in "Test Translation" },
        translateWithLLM: { _, direct, _, _ in direct },
        refreshLanguages: {},
        reset: {},
        isTranslationModelInstalled: { _, _ in true }
    )

    static let previewValue = TranslationClient(
        translate: { _ in "Preview Translation" },
        translateWithLLM: { _, _, _, _ in "Preview LLM Translation" },
        refreshLanguages: {},
        reset: {},
        isTranslationModelInstalled: { _, _ in true }
    )
}
