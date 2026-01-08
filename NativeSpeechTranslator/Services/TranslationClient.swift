import Dependencies
import Foundation

struct TranslationClient {
    var translate: @Sendable (String) async -> String
    var reset: @Sendable () async -> Void
}

extension DependencyValues {
    var translationClient: TranslationClient {
        get { self[TranslationClient.self] }
        set { self[TranslationClient.self] = newValue }
    }
}

extension TranslationClient: DependencyKey {
    static let liveValue = TranslationClient(
        translate: { text in
            let provider =
                UserDefaults.standard.string(forKey: "translationProvider") ?? "foundation"

            if provider == "translation" {
                do {
                    return try await TranslationService.shared.translate(text)
                } catch {
                    return "Translation Error: \(error.localizedDescription)"
                }
            }
            return await TranslationServiceLLM.shared.translate(text)
        },
        reset: {
            await TranslationService.shared.reset()
            await TranslationServiceLLM.shared.reset()
        }
    )

    static let testValue = TranslationClient(
        translate: { _ in "Test Translation" },
        reset: {}
    )

    static let previewValue = TranslationClient(
        translate: { _ in "Preview Translation" },
        reset: {}
    )
}
