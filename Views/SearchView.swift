import SwiftUI

struct SearchView: View {
    @ObservedObject var store: WordStore
    @AppStorage("llm_provider") private var providerRaw = LLMProvider.openAICompatible.rawValue
    @AppStorage("llm_base_url") private var baseURL = LLMProvider.openAICompatible.defaultBaseURL
    @AppStorage("llm_model") private var model = LLMProvider.openAICompatible.defaultModel
    @AppStorage("llm_api_key") private var apiKey = ""

    @State private var query = ""
    @State private var selectedWord: GermanWordData?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private let client = LLMWordClient()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    searchBar
                    statusContent
                }
                .padding(18)
            }
            .background(AppTheme.background)
            .navigationTitle("Cards")
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("German word, e.g. Apfel", text: $query)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit { Task { await search() } }
            Button {
                Task { await search() }
            } label: {
                Image(systemName: isLoading ? "hourglass" : "arrow.right")
                    .font(.headline)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var statusContent: some View {
        if isLoading {
            ProgressView("Generating card...")
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else if let errorMessage {
            ContentUnavailableView("Lookup failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
        } else if let selectedWord {
            WordCardView(data: selectedWord)
        } else {
            historyAndReferences
        }
    }

    private var historyAndReferences: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !store.history.isEmpty {
                sectionTitle("Recently Viewed")
                FlowButtons(words: store.history.map(\.word)) { word in
                    if let cached = store.findCached(word) {
                        selectedWord = cached
                    }
                }
            }

            sectionTitle("Local Reference Samples")
            FlowButtons(words: ReferenceLexicon.samples.map(\.word)) { word in
                loadReference(word)
            }

            Text(ReferenceLexicon.sourceSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(14)
                .background(.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.22))
    }

    private func loadReference(_ word: String) {
        guard let result = ReferenceLexicon.lookup(word) else { return }
        query = result.word
        selectedWord = result
        errorMessage = nil
        store.save(result)
    }

    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }

        errorMessage = nil
        if let cached = store.findCached(term) {
            selectedWord = cached
            return
        }
        if let reference = ReferenceLexicon.lookup(term) {
            selectedWord = reference
            store.save(reference)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let provider = LLMProvider(rawValue: providerRaw) ?? .openAICompatible
            let config = LLMConfiguration(provider: provider, baseURL: baseURL, model: model, apiKey: apiKey)
            let result = try await client.fetchWordInfo(word: term, configuration: config)
            selectedWord = result
            store.save(result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FlowButtons: View {
    let words: [String]
    let action: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(words, id: \.self) { word in
                Button(word) {
                    action(word)
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
    }
}
