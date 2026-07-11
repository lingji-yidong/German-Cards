import Foundation

enum WordLookupError: LocalizedError {
    case missingConfiguration
    case invalidURL
    case emptyResponse
    case decodingFailed
    case invalidWordSuggestion(String?)

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
        case .invalidWordSuggestion(let suggestion):
            if let suggestion, !suggestion.isEmpty {
                return "這看起來不像有效德語詞。你是不是想查：\(suggestion)？"
            }
            return "這看起來不像有效德語詞，請檢查拼寫。"
        }
    }
}

final class LLMWordClient {
    func fetchWordInfo(word: String, configuration: LLMConfiguration) async throws -> GermanWordData {
        guard configuration.isUsable else { throw WordLookupError.missingConfiguration }

        let result: GermanWordData
        switch configuration.provider {
        case .gemini:
            result = try await fetchFromGemini(word: word, configuration: configuration)
        case .openAICompatible, .custom:
            result = try await fetchFromChatCompletions(word: word, configuration: configuration)
        }
        return applySource("LLM · \(configuration.model)", to: result)
    }

    private func fetchFromChatCompletions(word: String, configuration: LLMConfiguration) async throws -> GermanWordData {
        let endpoint = try endpointURL(baseURL: configuration.normalizedBaseURL, path: "chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatCompletionRequest(
            model: configuration.model,
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: "Resolve this vocabulary query to the best German dictionary headword and build a card: \(word)")
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
        let endpoint = try endpointURL(baseURL: configuration.normalizedBaseURL, path: "models/\(configuration.model):generateContent")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw WordLookupError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "key", value: configuration.apiKey)]
        guard let url = components.url else { throw WordLookupError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: [
            GeminiContent(parts: [GeminiPart(text: "\(systemPrompt)\n\nResolve this vocabulary query to the best German dictionary headword and build a card: \(word)")])
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
                englishMeaning: decoded.englishMeaning,
                partOfSpeech: decoded.partOfSpeech,
                gender: decoded.gender,
                pluralForm: decoded.pluralForm,
                declensionTable: decoded.declensionTable,
                verbConjugation: decoded.verbConjugation,
                adjectiveComparison: decoded.adjectiveComparison,
                exampleSentence: decoded.exampleSentence,
                exampleTranslation: decoded.exampleTranslation,
                referenceSource: decoded.referenceSource,
                notes: decoded.notes,
                isValidGermanWord: decoded.isValidGermanWord,
                suggestedWord: decoded.suggestedWord,
                confidence: decoded.confidence,
                schemaVersion: GermanWordData.currentSchemaVersion,
                timestamp: decoded.timestamp
            )
        }
        return decoded
    }


    private func applySource(_ source: String, to data: GermanWordData) -> GermanWordData {
        GermanWordData(
            word: data.word,
            meaning: data.meaning,
            englishMeaning: data.englishMeaning,
            partOfSpeech: data.partOfSpeech,
            gender: data.gender,
            pluralForm: data.pluralForm,
            declensionTable: data.declensionTable,
            verbConjugation: data.verbConjugation,
            adjectiveComparison: data.adjectiveComparison,
            exampleSentence: data.exampleSentence,
            exampleTranslation: data.exampleTranslation,
            referenceSource: source,
            notes: data.notes,
            isValidGermanWord: data.isValidGermanWord,
            suggestedWord: data.suggestedWord,
            confidence: data.confidence,
            schemaVersion: GermanWordData.currentSchemaVersion,
            timestamp: data.timestamp
        )
    }

    private var systemPrompt: String {
        """
        Return only strict JSON for a German vocabulary card. The user may enter a German word or inflected form, a misspelled German word, an English word/phrase, or a Traditional/Simplified Chinese word/phrase. Resolve the input to the best German dictionary headword before building the card.

        Fields:
        word, meaning, englishMeaning, partOfSpeech, gender ("der", "die", "das", "none"), pluralForm,
        declensionTable [{caseName, singular, plural}],
        verbConjugation [{tense, pronoun, form}],
        adjectiveComparison {positive, comparative, superlative},
        exampleSentence, exampleTranslation, referenceSource, notes [string],
        isValidGermanWord, suggestedWord, confidence.

        For German input, first validate the user's exact input. If the input is already a valid dictionary headword, return that headword and do not redirect it to another lemma merely because the same spelling can also be an inflected form. German nouns may be typed lowercase; for example input "sonne" should be treated as the noun "Sonne" (die Sonne) unless the user explicitly asks for the verb "sonnen".
        Inflected German forms are valid: plural nouns, declined nouns/adjectives, and conjugated verbs must set isValidGermanWord=true and return the dictionary lemma in word only when the input is not itself a more common headword. For example, input "Augen" should return word "Auge", gender "das", and pluralForm "Augen".

        For English or Chinese input, treat the input as a meaning lookup. Choose one common, useful German headword that best matches the query, set isValidGermanWord=true, put the German headword in word, and build the full card for that headword. For example, input "try", "attempt", "嘗試", or "尝试" may resolve to "versuchen". Use suggestedWord only when the query is too ambiguous to choose one German word confidently.

        Only set isValidGermanWord=false when the input is misspelled German with no confident correction, is not a vocabulary lookup, or is too ambiguous to map to one useful German headword. In that case put the most likely German lemma in suggestedWord when possible, set confidence 0..1, and do not invent a full card.
        Use Traditional Chinese consistently for meaning, exampleTranslation, and notes. Put an English gloss in englishMeaning.
        Use concise, conservative notes in Traditional Chinese. Do not mix languages except when citing German forms or source-language words. Include only notes that are relevant to understanding or remembering the headword, using the following rules:
        - Compound words: always include one decomposition in the form "複合詞拆解：German component（繁體中文意思）+ German component（繁體中文意思）". Include every meaningful component in order, explain linking elements such as -s- when present, and state briefly how the components produce the full meaning. This is required even when the compound was generated from an English or Chinese query. For example, Warpgeschwindigkeit must explain Warp + Geschwindigkeit rather than only defining the complete word. Do not invent a decomposition for a word that is not a compound.
        - Loanwords: when reliably known, identify the source language and source word, give its original meaning, and briefly explain how it entered or changed in German.
        - Historical etymology: when reliably known and useful, summarize development from stages such as Old High German, Middle High German, Latin, or Ancient Greek. Give only a broad period unless a more precise date is well established; never invent a year or an intermediate form.
        - Semantic development: mention a notable change from the older meaning to the modern German meaning when it helps explain present usage.
        - Fun fact: optionally include at most one short, memorable fact only when it is linguistically relevant and reasonably reliable. Prefer usage, word-family, or cultural-language facts over unrelated trivia.
        Omit etymology or fun facts when confidence is low. State uncertainty explicitly instead of presenting a disputed origin as fact. Do not add filler notes merely to satisfy every category.
        For nouns, include Nominativ, Akkusativ, Dativ, Genitiv rows with articles.
        For verbs, include common conjugations in verbConjugation: Präsens ich/du/er-sie-es/wir/ihr/sie-Sie, plus Präteritum and Perfekt summary rows when useful. Use [] for non-verbs.
        For adjectives, include adjectiveComparison with positive, comparative, and superlative forms, for example {"positive":"schnell","comparative":"schneller","superlative":"am schnellsten"}. Use null for non-adjectives.
        Mention uncertainty plainly in Traditional Chinese when a form should be verified in an authoritative dictionary.
        """
    }
}

private struct LLMWordPayload: Decodable {
    let word: String?
    let meaning: String?
    let englishMeaning: String?
    let partOfSpeech: String?
    let gender: String?
    let pluralForm: String?
    let declensionTable: [DeclensionRow]?
    let verbConjugation: [VerbConjugationRow]?
    let adjectiveComparison: AdjectiveComparison?
    let exampleSentence: String?
    let exampleTranslation: String?
    let referenceSource: String?
    let notes: [String]?
    let isValidGermanWord: Bool?
    let suggestedWord: String?
    let confidence: Double?

    func toGermanWordData() -> GermanWordData {
        GermanWordData(
            word: word ?? "",
            meaning: meaning ?? "-",
            englishMeaning: englishMeaning,
            partOfSpeech: partOfSpeech ?? "-",
            gender: GrammaticalGender(rawValue: gender ?? "none") ?? .none,
            pluralForm: pluralForm ?? "-",
            declensionTable: declensionTable ?? [],
            verbConjugation: verbConjugation,
            adjectiveComparison: adjectiveComparison,
            exampleSentence: exampleSentence ?? "-",
            exampleTranslation: exampleTranslation ?? "-",
            referenceSource: referenceSource ?? "LLM generated",
            notes: notes ?? [],
            isValidGermanWord: isValidGermanWord,
            suggestedWord: suggestedWord,
            confidence: confidence,
            schemaVersion: GermanWordData.currentSchemaVersion,
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
