import Foundation
import SwiftUI

enum GrammaticalGender: String, Codable, CaseIterable {
    case masculine = "der"
    case feminine = "die"
    case neuter = "das"
    case none = "none"

    var label: String {
        switch self {
        case .masculine:
            return "Maskulin"
        case .feminine:
            return "Feminin"
        case .neuter:
            return "Neutrum"
        case .none:
            return "Keine"
        }
    }

    var tint: Color {
        switch self {
        case .masculine:
            return Color(red: 0.12, green: 0.38, blue: 0.78)
        case .feminine:
            return Color(red: 0.78, green: 0.18, blue: 0.30)
        case .neuter:
            return Color(red: 0.05, green: 0.52, blue: 0.35)
        case .none:
            return Color(red: 0.34, green: 0.37, blue: 0.42)
        }
    }

    var softTint: Color {
        tint.opacity(0.14)
    }
}

struct DeclensionRow: Codable, Hashable, Identifiable {
    var id: String { caseName }
    let caseName: String
    let singular: String
    let plural: String
}

struct GermanWordData: Codable, Identifiable, Hashable {
    var id: String { word.lowercased() }
    let word: String
    let meaning: String
    let partOfSpeech: String
    let gender: GrammaticalGender
    let pluralForm: String
    let declensionTable: [DeclensionRow]
    let exampleSentence: String
    let exampleTranslation: String
    let referenceSource: String
    let notes: [String]
    let timestamp: TimeInterval

    var displayArticle: String {
        gender == .none ? "" : gender.rawValue
    }
}

enum LLMProvider: String, CaseIterable, Identifiable {
    case openAICompatible = "OpenAI-compatible"
    case gemini = "Gemini"
    case custom = "Custom"

    var id: String { rawValue }

    var defaultBaseURL: String {
        switch self {
        case .openAICompatible:
            return "https://api.openai.com/v1"
        case .gemini:
            return "https://generativelanguage.googleapis.com/v1beta"
        case .custom:
            return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .openAICompatible:
            return "gpt-4.1-mini"
        case .gemini:
            return "gemini-2.5-flash"
        case .custom:
            return ""
        }
    }
}

struct LLMConfiguration {
    let provider: LLMProvider
    let baseURL: String
    let model: String
    let apiKey: String

    var isUsable: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
