import Foundation

enum LLMProvider: String, CaseIterable, Identifiable {
    case openai
    case groq
    case custom
    case foundation

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .groq: return "Groq"
        case .custom: return "Custom (OpenAI Compatible)"
        case .foundation: return "Foundation Models"
        }
    }

    var availableModels: [String] {
        switch self {
        case .openai: return ["gpt-5-mini", "gpt-5-nano"]
        case .groq: return ["llama-3.3-70b-versatile", "openai/gpt-oss-120b"]
        case .custom: return []
        case .foundation: return []
        }
    }

    var requiresAPIKey: Bool {
        self != .foundation
    }

    var requiresBaseURL: Bool {
        self == .custom
    }

    var requiresCustomModel: Bool {
        self == .custom
    }
}

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
