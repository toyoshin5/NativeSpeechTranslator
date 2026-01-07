import Foundation
import FoundationModels

@available(macOS 26, *)
actor TranslationService {

    static let shared = TranslationService()

    private var session: LanguageModelSession?

    private var isTranslating = false

    private init() {}

    /// テキストを日本語に翻訳します。
    ///
    /// - Parameter text: 翻訳対象の英語テキスト。
    /// - Returns: 翻訳された日本語テキスト。
    func translate(_ text: String) async -> String {

        // 排他ロック
        guard !isTranslating else {
            return "..."
        }

        isTranslating = true
        defer { isTranslating = false }

        if session == nil {
            session = LanguageModelSession()
        }

        guard let session = session else { return "モデル準備中..." }

        let systemPrompt =
            "You are a professional interpreter. Translate the following text into natural Japanese immediately."
        let prompt = "\(systemPrompt)\n\n\(text)"

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("Translation error: \(error)")
            // エラーが発生した場合、セッションをリセットして次回の復帰を試みる
            self.session = nil
            return "翻訳エラー"
        }
    }
}
