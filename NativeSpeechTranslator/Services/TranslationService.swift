import Foundation
import FoundationModels

/// `FoundationModels` を使用してテキスト翻訳を行うアクター。
@available(macOS 26, *)
actor TranslationService {
    
    /// シングルトンインスタンス
    static let shared = TranslationService()
    
    /// 言語モデルセッション
    private var session: LanguageModelSession?
    
    /// 初期化
    private init() {}
    
    /// テキストを日本語に翻訳します。
    ///
    /// - Parameter text: 翻訳対象の英語テキスト。
    /// - Returns: 翻訳された日本語テキスト。
    func translate(_ text: String) async -> String {
        // セッションの遅延初期化
        if session == nil {
            session = LanguageModelSession()
        }
        
        guard let session = session else { return "モデル準備中..." }
        
        let systemPrompt = "You are a professional interpreter. Translate the following text into natural Japanese immediately."
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
