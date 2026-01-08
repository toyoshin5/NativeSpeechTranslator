@available(macOS 15.0, *)
actor TranslationService {
    static let shared = TranslationService()
    
    private init() {}
    
    func translate(_ text: String) async -> String {
        do {
            return try await executeOnMainActor(text)
        } catch {
            return "Translation Error: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func executeOnMainActor(_ text: String) async throws -> String {
        return try await TranslationBridge.shared.translate(text)
    }
}
