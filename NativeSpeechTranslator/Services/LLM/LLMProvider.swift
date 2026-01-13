import Foundation

enum LLMProvider: String, CaseIterable, Identifiable {
    case openai
    case groq
    case foundation

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .groq: return "Groq"
        case .foundation: return "Foundation Models"
        }
    }

    var availableModels: [String] {
        switch self {
        case .openai: return ["gpt-5-mini","gpt-5-nano"]
        case .groq: return ["llama-3.3-70b-versatile", "openai/gpt-oss-120b"]
        case .foundation: return ["default"]
        }
    }

    var requiresAPIKey: Bool {
        self != .foundation
    }
}

enum TranslationPrompt {
    static let systemPrompt = """
        You are a professional English-to-Japanese translator.
        You will receive English text that originates from speech recognition and may contain errors (e.g., phonetic mix-ups, missing punctuation, homophones).
        Your task is to infer the speaker's intended meaning, correcting any transcription errors based on context, and translate it into natural, fluent Japanese.
        Output only the refined Japanese translation without any explanation.
        """

    static func userPrompt(original: String, direct: String) -> String {
        """
        Original English: \(original)
        Direct Translation: \(direct)
        """
    }

    static let testMessage = "Hello, this is a test."
}
