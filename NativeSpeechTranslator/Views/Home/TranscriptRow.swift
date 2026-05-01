import SwiftUI

struct TranscriptRow: View {

    /// 原文
    let original: String

    /// 翻訳文
    let translation: String?

    let fontSize: CGFloat

    /// LLM翻訳が有効で、まだ翻訳が完了していない場合はtrue
    var isWaitingForLLM: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 原文（左側）
            Text(original)
                .textSelection(.enabled)
                .font(.system(size: fontSize))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 翻訳（右側）
            VStack(alignment: .leading) {
                if let translation = translation {
                    Text(translation)
                        .textSelection(.enabled)
                        .font(.system(size: fontSize))
                        .foregroundColor(isWaitingForLLM ? .secondary : .primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}
