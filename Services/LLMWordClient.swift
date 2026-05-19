import Foundation

enum WordLookupError: LocalizedError {
    case missingConfiguration
    case invalidURL
    case emptyResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "請先在 Settings 填入 provider URL、model 和 API key。"
        case .invalidURL:
            return "Provider URL 無效。"
        case .emptyResponse:
            return "LLM 沒有返回內容。"
        case .decodingFailed:
            return "無法解析 LLM 返回的卡片 JSON。"
        }
    }
}

final class LLMWordClient {
    func fetchWordInfo(word: String, configuration: LLMConfiguration) async throws -> GermanWordData {
        guard configuration.isUsable else { throw WordLookupError.missingConfiguration }

        switch configuration.provider {
        case .gemini:
            return try await fetchFromGemini(word: word, configuration: configuration)
        case .openAICompatible, .custom:
            return try await fetchFromChatCompletions(word: word, configuration: configuration)
        }
    }

    private func fetchFromChatCompletions(word: String, configuration: LLMConfiguration) async throws -> GermanWordData {
        let endpoint = try endpointURL(baseURL: configuration.baseURL, path: "chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCompletionRequest(
            model: configuration.model,
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: "Analyze the German word: \(word)")
            ],
            temperature: 0.1,
            response_format: ResponseFormat(type: "json_object")
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let envelope = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let text = envelope.choices.first?.message.content, !text.isEmpty else {
            throw WordLookupError.emptyResponse
        }
        return try decodeWordData(from: text, fallbackWord: word)
    }

    private func fetchFromGemini(word: String, configuration: LLMConfiguration) async throws -> GermanWordData {
        let endpoint = try endpointURL(baseURL: configuration.baseURL, path: "models/\(configuration.model):generateContent")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw WordLookupError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "key", value: configuration.apiKey)]
        guard let url = components.url else { throw WordLookupError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: [
            GeminiContent(parts: [GeminiPart(text: "\(systemPrompt)\n\nAnalyze the German word: \(word)")])
        ]))

        let (data, _) = try await URLSession.shared.data(for: request)
        let envelope = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = envelope.candidates.first?.content.parts.first?.text, !text.isEmpty else {
            throw WordLookupError.emptyResponse
        }
        return try decodeWordData(from: text, fallbackWord: word)
    }

    private func endpointURL(baseURL raw: String, path: String) throws -> URL {
        let trimmedBase = raw.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmedBase.isEmpty, let url = URL(string: "\(trimmedBase)/\(path)") else {
            throw WordLookupError.invalidURL
        }
        return url
    }

    private func decodeWordData(from rawText: String, fallbackWord: String) throws -> GermanWordData {
        let cleaned = rawText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else { throw WordLookupError.decodingFailed }
        var decoded = try JSONDecoder().decode(LLMWordPayload.self, from: data).toGermanWordData()
        if decoded.word.isEmpty {
            decoded = GermanWordData(
                word: fallbackWord,
                meaning: decoded.meaning,
                partOfSpeech: decoded.partOfSpeech,
                gender: decoded.gender,
                pluralForm: decoded.pluralForm,
                declensionTable: decoded.declensionTable,
                exampleSentence: decoded.exampleSentence,
                exampleTranslation: decoded.exampleTranslation,
                referenceSource: decoded.referenceSource,
                notes: decoded.notes,
                timestamp: decoded.timestamp
            )
        }
        return decoded
    }

    private var systemPrompt: String {
        """
        Return only strict JSON for a German vocabulary card. Fields:
        word, meaning, partOfSpeech, gender ("der", "die", "das", "none"), pluralForm,
        declensionTable [{caseName, singular, plural}],
        exampleSentence, exampleTranslation, referenceSource, notes [string].
        Use Simplified Chinese for meaning and exampleTranslation. Prefer conservative grammar.
        For nouns, include Nominativ, Akkusativ, Dativ, Genitiv rows with articles.
        Mention if the answer should be checked against Wiktionary/FreeDict when uncertain.
        """
    }
}

private struct LLMWordPayload: Decodable {
    let word: String?
    let meaning: String?
    let partOfSpeech: String?
    let gender: String?
    let pluralForm: String?
    let declensionTable: [DeclensionRow]?
    let exampleSentence: String?
    let exampleTranslation: String?
    let referenceSource: String?
    let notes: [String]?

    func toGermanWordData() -> GermanWordData {
        GermanWordData(
            word: word ?? "",
            meaning: meaning ?? "-",
            partOfSpeech: partOfSpeech ?? "-",
            gender: GrammaticalGender(rawValue: gender ?? "none") ?? .none,
            pluralForm: pluralForm ?? "-",
            declensionTable: declensionTable ?? [],
            exampleSentence: exampleSentence ?? "-",
            exampleTranslation: exampleTranslation ?? "-",
            referenceSource: referenceSource ?? "LLM generated",
            notes: notes ?? [],
            timestamp: Date().timeIntervalSince1970
        )
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let response_format: ResponseFormat
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ResponseFormat: Encodable {
    let type: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ChatMessage
    }
}

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]

    struct Candidate: Decodable {
        let content: GeminiContent
    }
}
