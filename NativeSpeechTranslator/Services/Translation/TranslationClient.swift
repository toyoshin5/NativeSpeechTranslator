import Dependencies
import Foundation

struct TranslationClient {
    var translate: @Sendable (String) async -> String
    var translateWithLLM: @Sendable (String, String, String, String) async -> String
    var updateLanguages: @Sendable (Locale, Locale) async -> Void
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
        translateWithLLM: { original, direct, sourceLanguage, targetLanguage in
            await TranslationLLMService.shared.translate(
                original: original,
                direct: direct,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
        },
        updateLanguages: { source, target in
            await TranslationService.shared.setLanguages(source: source, target: target)
        },
        reset: {
            await TranslationService.shared.reset()
            await FoundationModelService.shared.reset()
        }
    )

    static let testValue = TranslationClient(
        translate: { _ in "Test Translation" },
        translateWithLLM: { _, direct, _, _ in direct },
        updateLanguages: { _, _ in },
        reset: {}
    )

    static let previewValue = TranslationClient(
        translate: { _ in "Preview Translation" },
        translateWithLLM: { _, _, _, _ in "Preview LLM Translation" },
        updateLanguages: { _, _ in },
        reset: {}
    )
}
