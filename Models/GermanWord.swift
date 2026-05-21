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

struct VerbConjugationRow: Codable, Hashable, Identifiable {
    var id: String { "\(tense)-\(pronoun)" }
    let tense: String
    let pronoun: String
    let form: String
}

struct AdjectiveComparison: Codable, Hashable {
    let positive: String
    let comparative: String
    let superlative: String
}

struct GermanWordData: Codable, Identifiable, Hashable {
    // Bump this when generated card content changes enough to justify smart renewal.
    static let currentSchemaVersion = 3

    var id: String { word.lowercased() }
    let word: String
    let meaning: String
    let englishMeaning: String?
    let partOfSpeech: String
    let gender: GrammaticalGender
    let pluralForm: String
    let declensionTable: [DeclensionRow]
    let verbConjugation: [VerbConjugationRow]?
    let adjectiveComparison: AdjectiveComparison?
    let exampleSentence: String
    let exampleTranslation: String
    let referenceSource: String
    let notes: [String]
    let isValidGermanWord: Bool?
    let suggestedWord: String?
    let confidence: Double?
    let schemaVersion: Int?
    let timestamp: TimeInterval

    var displayArticle: String {
        gender == .none ? "" : gender.rawValue
    }

    var isProbablyValid: Bool {
        isValidGermanWord ?? true
    }

    var displayedVerbConjugation: [VerbConjugationRow] {
        verbConjugation ?? []
    }

    var displayedAdjectiveComparison: AdjectiveComparison? {
        adjectiveComparison
    }

    var effectiveSchemaVersion: Int {
        // Older saved JSON has no schemaVersion; treat it as the original schema.
        schemaVersion ?? 1
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

    var normalizedBaseURL: String {
        Self.normalizedBaseURL(baseURL, provider: provider)
    }

    var isUsable: Bool {
        !normalizedBaseURL.isEmpty &&
        !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func normalizedBaseURL(_ rawValue: String, provider: LLMProvider) -> String {
        var value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }
        if !value.contains("://") {
            value = "https://\(value)"
        }
        while value.hasSuffix("/") {
            value.removeLast()
        }

        guard var components = URLComponents(string: value), components.scheme != nil, components.host != nil else {
            return value
        }
        let cleanedPath = components.path
            .split(separator: "/")
            .joined(separator: "/")
        components.path = cleanedPath.isEmpty ? "" : "/\(cleanedPath)"

        switch provider {
        case .openAICompatible, .custom:
            if components.path.hasSuffix("/chat/completions") {
                components.path.removeLast("/chat/completions".count)
            }
            if !components.path.hasSuffix("/v1") {
                components.path += "/v1"
            }
        case .gemini:
            break
        }

        guard var normalized = components.url?.absoluteString else { return value }
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }
}
