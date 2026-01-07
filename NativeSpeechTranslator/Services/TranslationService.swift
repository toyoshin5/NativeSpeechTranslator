import Foundation
import FoundationModels

/// `FoundationModels` を使用してテキスト翻訳を行うアクター。
@available(macOS 26, *)
actor TranslationService {
    
    /// シングルトンインスタンス
    static let shared = TranslationService()
    
    /// 言語モデルセッション
    private var session: LanguageModelSession?
    
    /// 翻訳中フラグ
    private var isTranslating = false
    
    /// 初期化
    private init() {}
    
    /// テキストを日本語に翻訳します。
    ///
    /// - Parameter text: 翻訳対象の英語テキスト。
    /// - Returns: 翻訳された日本語テキスト。
    func translate(_ text: String) async -> String {
        // 簡易的な排他制御: 実行中ならスキップしてエラーを返す（あるいは待機させる）
        // リアルタイム翻訳なので、古いリクエストが詰まるよりはスキップするか、最新のみ処理するのが良い
        // ここでは単純に「前の処理が終わるまで待つ」のではなく「混雑時は拒否または無視」する
        // ただし、ユーザー体験的には「翻訳中...」などで待たせるのが良いが、
        // ログのエラーは "attempted to call respond ... before first call complete" なので、
        // Actor内でのawait中に次のメソッド呼び出しが入っている。
        
        // 排他ロック
        guard !isTranslating else {
            return "..." // 処理中のためスキップ
        }
        
        isTranslating = true
        defer { isTranslating = false }
        
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
