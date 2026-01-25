import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct TranslationClient: Sendable {
    @DependencyEndpoint
    var translate: @Sendable (_ text: String) async -> String = { _ in "" }
    @DependencyEndpoint
    var translateWithLLM:
        @Sendable (
            _ original: String, _ direct: String, _ sourceLanguage: String, _ targetLanguage: String
        ) async -> String = { _, _, _, _ in "" }
    @DependencyEndpoint
    var refreshLanguages: @Sendable () async -> Void
    @DependencyEndpoint
    var reset: @Sendable () async -> Void
    @DependencyEndpoint
    var isTranslationModelInstalled:
        @Sendable (_ source: Locale.Language, _ target: Locale.Language) async -> Bool = { _, _ in
            false
        }
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
            await TranslationService.shared.isTranslationModelInstalled(
                source: source, target: target)
        }
    )
}
