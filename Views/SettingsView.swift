import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: WordStore
    @AppStorage("llm_provider") private var providerRaw = LLMProvider.openAICompatible.rawValue
    @AppStorage("llm_base_url") private var baseURL = LLMProvider.openAICompatible.defaultBaseURL
    @AppStorage("llm_model") private var model = LLMProvider.openAICompatible.defaultModel
    @AppStorage("llm_api_key") private var apiKey = ""
    @State private var saved = false
    @State private var isRenewing = false
    @State private var renewStatus: String?
    @State private var showingForceRenewConfirmation = false
    @State private var isExportingDictionary = false
    @State private var isImportingDictionary = false
    @State private var dictionaryDocument = DictionaryExportDocument()
    @State private var dictionaryTransferStatus: String?
    @AppStorage("app_appearance") private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage("grammar_language") private var grammarLanguageRaw = GrammarLanguage.traditionalChinese.rawValue

    private let client = LLMWordClient()

    private var cardsNeedingRenewal: [GermanWordData] {
        store.history.filter(needsRenewal)
    }

    private var appearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    private var grammarLanguage: Binding<GrammarLanguage> {
        Binding(
            get: { GrammarLanguage(rawValue: grammarLanguageRaw) ?? .traditionalChinese },
            set: { grammarLanguageRaw = $0.rawValue }
        )
    }

    private var provider: Binding<LLMProvider> {
        Binding(
            get: { LLMProvider(rawValue: providerRaw) ?? .openAICompatible },
            set: { newValue in
                providerRaw = newValue.rawValue
                if baseURL.isEmpty || baseURL == LLMProvider.openAICompatible.defaultBaseURL || baseURL == LLMProvider.gemini.defaultBaseURL {
                    baseURL = newValue.defaultBaseURL
                }
                if model.isEmpty || model == LLMProvider.openAICompatible.defaultModel || model == LLMProvider.gemini.defaultModel {
                    model = newValue.defaultModel
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Picker("Grammar Language", selection: grammarLanguage) {
                        ForEach(GrammarLanguage.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } header: {
                    Text("Display")
                } footer: {
                    Text("Appearance follows the system by default. Grammar copy can be switched independently from the device language.")
                }

                Section {
                    Picker("Provider", selection: provider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    TextField("Base URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Model", text: $model)
                        .textInputAutocapitalization(.never)
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                    Button {
                        saved = true
                    } label: {
                        Label(saved ? "Saved" : "Save Configuration", systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                    }
                } header: {
                    Text("LLM Provider")
                } footer: {
                    Text("OpenAI-compatible 和 Custom 會呼叫 {Base URL}/chat/completions。Gemini 會呼叫 {Base URL}/models/{model}:generateContent。")
                }

                Section {
                    Label("User dictionary", systemImage: "folder")
                    Text("Generated cards are saved locally. Use Export and Import to sync through Files, AirDrop, Git, or your own cloud storage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("No bundled third-party dictionary is shipped. Your word list starts from zero and grows only from cards you create.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        exportDictionary()
                    } label: {
                        Label("Export Dictionary", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.history.isEmpty)
                    Button {
                        isImportingDictionary = true
                    } label: {
                        Label("Import Dictionary", systemImage: "square.and.arrow.down")
                    }
                    if let dictionaryTransferStatus {
                        Text(dictionaryTransferStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        Task { await renewExistingCards(forceAll: false) }
                    } label: {
                        Label(isRenewing ? "Renewing Cards" : "Renew Missing Fields", systemImage: "arrow.clockwise")
                    }
                    .disabled(isRenewing || cardsNeedingRenewal.isEmpty)
                    Button(role: .destructive) {
                        showingForceRenewConfirmation = true
                    } label: {
                        Label("Force Renew All", systemImage: "exclamationmark.arrow.triangle.2.circlepath")
                    }
                    .disabled(isRenewing || store.history.isEmpty)
                    Text("需要補資料的卡片：\(cardsNeedingRenewal.count) / \(store.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let renewStatus {
                        Text(renewStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Dictionary")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Generated Cards")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(store.count)")
                                .font(.title3.weight(.black).monospacedDigit())
                                .foregroundStyle(AppTheme.brand)
                        }
                        CEFRProgressRow(level: "A1", target: 600, current: store.count)
                        CEFRProgressRow(level: "A2", target: 1300, current: store.count)
                        CEFRProgressRow(level: "B1", target: 2500, current: store.count)
                        CEFRProgressRow(level: "B2", target: 5000, current: store.count)
                        CEFRProgressRow(level: "C1", target: 8000, current: store.count)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("CEFR Vocabulary Goals")
                } footer: {
                    Text("Vocabulary targets vary by course and exam. Use these as rough planning numbers for your own dictionary.")
                }
            }
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $isExportingDictionary,
                document: dictionaryDocument,
                contentType: .json,
                defaultFilename: "GermanCardsDictionary"
            ) { result in
                switch result {
                case .success:
                    dictionaryTransferStatus = "Dictionary exported."
                case .failure(let error):
                    dictionaryTransferStatus = "Export failed: \(error.localizedDescription)"
                }
            }
            .fileImporter(isPresented: $isImportingDictionary, allowedContentTypes: [.json]) { result in
                importDictionary(result)
            }
            .confirmationDialog(
                "Force renew all cards?",
                isPresented: $showingForceRenewConfirmation,
                titleVisibility: .visible
            ) {
                Button("Renew All Cards", role: .destructive) {
                    Task { await renewExistingCards(forceAll: true) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will call the LLM once for every saved card, even cards that already have the current fields.")
            }
        }
    }

    private func exportDictionary() {
        do {
            dictionaryDocument = DictionaryExportDocument(data: try store.exportData())
            isExportingDictionary = true
        } catch {
            dictionaryTransferStatus = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importDictionary(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }
            let importedCount = try store.importData(Data(contentsOf: url))
            dictionaryTransferStatus = "Imported \(importedCount) cards."
        } catch {
            dictionaryTransferStatus = "Import failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func renewExistingCards(forceAll: Bool) async {
        let provider = LLMProvider(rawValue: providerRaw) ?? .openAICompatible
        let config = LLMConfiguration(provider: provider, baseURL: baseURL, model: model, apiKey: apiKey)
        guard config.isUsable else {
            renewStatus = "請先填好 LLM provider URL、model 和 API key。"
            return
        }

        let cards = forceAll ? store.history : cardsNeedingRenewal
        guard !cards.isEmpty else {
            renewStatus = "目前沒有需要補資料的卡片。"
            return
        }

        isRenewing = true
        renewStatus = "正在更新 0 / \(cards.count)"
        var updatedCount = 0
        var skippedCount = 0

        for (index, card) in cards.enumerated() {
            do {
                let refreshed = try await client.fetchWordInfo(word: card.word, configuration: config)
                if refreshed.isProbablyValid {
                    store.replace(original: card, with: refreshed)
                    updatedCount += 1
                } else {
                    skippedCount += 1
                }
            } catch {
                skippedCount += 1
            }
            renewStatus = "正在更新 \(index + 1) / \(cards.count)"
        }

        isRenewing = false
        renewStatus = "已更新 \(updatedCount) 張卡片，跳過 \(skippedCount) 張。"
    }

    private func needsRenewal(_ card: GermanWordData) -> Bool {
        // Keep the default renewal path token-conscious; only call the LLM for stale or incomplete cards.
        if card.effectiveSchemaVersion < 2 {
            return true
        }
        if card.englishMeaning?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            return true
        }
        if card.isValidGermanWord == nil {
            return true
        }
        if !card.referenceSource.hasPrefix("LLM · ") {
            return true
        }
        if isVerb(card), card.displayedVerbConjugation.isEmpty {
            return true
        }
        if isAdjective(card), card.displayedAdjectiveComparison == nil {
            return true
        }
        return false
    }

    private func isVerb(_ card: GermanWordData) -> Bool {
        let value = card.partOfSpeech.lowercased()
        return value.contains("verb") || value.contains("動詞") || value.contains("verben")
    }

    private func isAdjective(_ card: GermanWordData) -> Bool {
        let value = card.partOfSpeech.lowercased()
        return value.contains("adjective") || value.contains("adj") || value.contains("形容詞") || value.contains("adjektiv")
    }
}


private struct CEFRProgressRow: View {
    let level: String
    let target: Int
    let current: Int

    private var progress: Double {
        min(Double(current) / Double(target), 1)
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(level)
                .font(.caption.weight(.bold))
                .frame(width: 28, alignment: .leading)
            ProgressView(value: progress)
                .tint(AppTheme.brand)
            Text("\(target)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
        }
    }
}
