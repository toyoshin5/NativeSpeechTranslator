import Foundation

enum TranslationPrompt {
    static func systemPrompt(sourceLanguage: String, targetLanguage: String) -> String {
        """
        You are a professional \(sourceLanguage)-to-\(targetLanguage) translator.
        You will receive \(sourceLanguage) text that originates from speech recognition and may contain errors (e.g., phonetic mix-ups, missing punctuation, homophones).
        Your task is to infer the speaker's intended meaning, correcting any transcription errors based on context, and translate it into natural, fluent \(targetLanguage).
        Output only the refined \(targetLanguage) translation without any explanation.
        """
    }

    static func userPrompt(original: String, direct: String) -> String {
        """
        Original Text: \(original)
        Direct Translation: \(direct)
        """
    }

    static let testMessage = "Hello, this is a test."
}
