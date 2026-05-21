import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: WordStore
    @AppStorage("llm_provider") private var providerRaw = LLMProvider.openAICompatible.rawValue
    @AppStorage("llm_base_url") private var baseURL = LLMProvider.openAICompatible.defaultBaseURL
    @AppStorage("llm_model") private var model = LLMProvider.openAICompatible.defaultModel
    @AppStorage("llm_api_key") private var apiKey = ""
    @State private var draftBaseURL = ""
    @State private var draftModel = ""
    @State private var draftAPIKey = ""
    @State private var configurationStatus: String?
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
                if draftBaseURL.isEmpty || draftBaseURL == LLMProvider.openAICompatible.defaultBaseURL || draftBaseURL == LLMProvider.gemini.defaultBaseURL {
                    draftBaseURL = newValue.defaultBaseURL
                }
                if draftModel.isEmpty || draftModel == LLMProvider.openAICompatible.defaultModel || draftModel == LLMProvider.gemini.defaultModel {
                    draftModel = newValue.defaultModel
                }
                configurationStatus = nil
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SettingsSection(
                        title: "Display",
                        footer: "Appearance follows the system by default. Grammar copy can be switched independently from the device language."
                    ) {
                        SettingsRow("Appearance") {
                            Picker("Appearance", selection: appearance) {
                                ForEach(AppAppearance.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .labelsHidden()
                        }
                        SettingsDivider()
                        SettingsRow("Grammar Language") {
                            Picker("Grammar Language", selection: grammarLanguage) {
                                ForEach(GrammarLanguage.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    SettingsSection(
                        title: "LLM Provider",
                        footer: "OpenAI-compatible 和 Custom 會呼叫 {Base URL}/chat/completions。Gemini 會呼叫 {Base URL}/models/{model}:generateContent。"
                    ) {
                        SettingsRow("Provider") {
                            Picker("Provider", selection: provider) {
                                ForEach(LLMProvider.allCases) { provider in
                                    Text(provider.rawValue).tag(provider)
                                }
                            }
                            .labelsHidden()
                        }
                        SettingsDivider()
                        SettingsRow("Base URL") {
                            TextField("Base URL", text: $draftBaseURL)
                                .germanCardsAutocapitalization(.never)
                                .germanCardsURLKeyboard()
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: draftBaseURL) { _, _ in configurationStatus = nil }
                        }
                        SettingsDivider()
                        SettingsRow("Model") {
                            TextField("Model", text: $draftModel)
                                .germanCardsAutocapitalization(.never)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: draftModel) { _, _ in configurationStatus = nil }
                        }
                        SettingsDivider()
                        SettingsRow("API Key") {
                            SecureField("API Key", text: $draftAPIKey)
                                .germanCardsAutocapitalization(.never)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: draftAPIKey) { _, _ in configurationStatus = nil }
                        }
                        SettingsDivider()
                        SettingsActionRow {
                            Button {
                                saveConfiguration()
                            } label: {
                                Label("Save Configuration", systemImage: "square.and.arrow.down")
                            }
                        }
                        if let configurationStatus {
                            SettingsStatusText(configurationStatus)
                        }
                    }

                    SettingsSection(title: "Dictionary") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("User dictionary", systemImage: "folder")
                                .font(.subheadline.weight(.semibold))
                            Text("Generated cards are saved locally. Use Export and Import to sync through Files, AirDrop, Git, or your own cloud storage.")
                            Text("No bundled third-party dictionary is shipped. Your word list starts from zero and grows only from cards you create.")
                        }
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        SettingsDivider()
                        SettingsActionRow {
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
                        }
                        if let dictionaryTransferStatus {
                            SettingsStatusText(dictionaryTransferStatus)
                        }
                        SettingsDivider()
                        SettingsActionRow {
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
                        }
                        SettingsStatusText("需要補資料的卡片：\(cardsNeedingRenewal.count) / \(store.count)")
                        if let renewStatus {
                            SettingsStatusText(renewStatus)
                        }
                    }

                    SettingsSection(
                        title: "CEFR Vocabulary Goals",
                        footer: "Vocabulary targets vary by course and exam. Use these as rough planning numbers for your own dictionary."
                    ) {
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
                    }
                }
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(AppTheme.background)
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
            .onAppear(perform: loadConfigurationDrafts)
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


    private func loadConfigurationDrafts() {
        draftBaseURL = baseURL
        draftModel = model
        draftAPIKey = apiKey
    }

    private func saveConfiguration() {
        let provider = LLMProvider(rawValue: providerRaw) ?? .openAICompatible
        let normalizedBaseURL = LLMConfiguration.normalizedBaseURL(draftBaseURL, provider: provider)
        baseURL = normalizedBaseURL
        model = draftModel.trimmingCharacters(in: .whitespacesAndNewlines)
        apiKey = draftAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        draftBaseURL = baseURL
        draftModel = model
        draftAPIKey = apiKey
        configurationStatus = "Configuration saved: \(baseURL)"
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


private struct SettingsSection<Content: View>: View {
    let title: String
    let footer: String?
    let content: Content

    init(title: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.separator))
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 2)
            }
        }
    }
}

private struct SettingsRow<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 8) {
                label
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 18) {
                label
                    .frame(width: 150, alignment: .leading)
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var label: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.primaryText)
    }
}

private struct SettingsActionRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                content
            }
            VStack(alignment: .leading, spacing: 10) {
                content
            }
        }
        .buttonStyle(.bordered)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(AppTheme.separator)
    }
}

private struct SettingsStatusText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(AppTheme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
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
