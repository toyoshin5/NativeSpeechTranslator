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
