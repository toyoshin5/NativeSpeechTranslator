import Foundation

enum SummaryPrompt {
    static let systemPrompt = """
        あなたはプロフェッショナルな会議要約アシスタントです。
        音声認識で取得された会議や会話のトランスクリプトを受け取ります。
        以下の内容を含めて、簡潔かつ明確に日本語で要約してください：
        - 議論された主要トピック
        - 議論の内容(時系列順)
        説明やメタコメントは加えず、要約のみを出力してください。
        """

    static func userPrompt(transcripts: [String]) -> String {
        transcripts.joined(separator: "\n")
    }
}
