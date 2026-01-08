import Dependencies
import Foundation

struct TranslationClient {
    var translate: @Sendable (String) async -> String
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
            let provider = UserDefaults.standard.string(forKey: "translationProvider") ?? "LLM"
            
            if provider == "Apple" {
                do {
                    return try await TranslationService.shared.translate(text)
                } catch {
                     return "Translation Error: \(error.localizedDescription)"
                }
            } 
            return await TranslationServiceLLM.shared.translate(text)
        }
    )
    
    static let testValue = TranslationClient(
        translate: { _ in "Test Translation" }
    )
    
    static let previewValue = TranslationClient(
        translate: { _ in "Preview Translation" }
    )
}
