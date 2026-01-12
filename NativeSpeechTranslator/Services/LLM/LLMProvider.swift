import Foundation

enum LLMProvider: String, CaseIterable, Identifiable {
    case openai
    case gemini
    case groq
    case foundation

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .gemini: return "Gemini"
        case .groq: return "Groq"
        case .foundation: return "Foundation Models"
        }
    }

    var availableModels: [String] {
        switch self {
        case .openai: return ["gpt-4o-mini"]
        case .gemini: return ["gemini-2.0-flash"]
        case .groq: return ["llama-3.3-70b-versatile", "llama-3.1-8b-instant"]
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
        You will receive the original English text and its direct translation.
        Refine the translation to make it more natural and fluent in Japanese.
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
