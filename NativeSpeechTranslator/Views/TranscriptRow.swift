import SwiftUI

struct TranscriptRow: View {

    /// 原文
    let original: String

    /// 翻訳文
    let translation: String?

    let isTranslating: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 原文（左側）
            Text(original)
                .textSelection(.enabled)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 翻訳（右側）
            VStack(alignment: .leading) {
                if let translation = translation {
                    Text(translation)
                        .textSelection(.enabled)
                        .font(.body)
                        .foregroundColor(.secondary)
                } else if isTranslating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}
