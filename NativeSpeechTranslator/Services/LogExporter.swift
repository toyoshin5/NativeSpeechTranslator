import Foundation

struct LogExporter {

    struct ExportResult {
        let url: URL
        let success: Bool
    }

    static func export(transcripts: [HomeViewModel.TranscriptItem]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())

        var content = """
            ================================================================================
            Native Speech Translator - Translation Log
            Exported: \(timestamp)
            ================================================================================

            """

        let finalTranscripts = transcripts.filter { $0.isFinal }

        content += """
            --- Original Text ---

            """

        for (index, item) in finalTranscripts.enumerated() {
            content += "\(index + 1). \(item.original)\n"
        }

        content += """

            --- Translation ---

            """

        for (index, item) in finalTranscripts.enumerated() {
            let translation = item.translation ?? "(翻訳なし)"
            content += "\(index + 1). \(translation)\n"
        }

        content += """

            ================================================================================
            End of Log
            ================================================================================
            """

        return content
    }

    static func saveToFile(transcripts: [HomeViewModel.TranscriptItem], directory: URL) throws -> URL
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "NativeSpeechTranslator_\(timestamp).txt"

        let fileURL = directory.appendingPathComponent(filename)
        let content = export(transcripts: transcripts)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }
}
