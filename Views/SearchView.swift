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
    @State private var deckIndex = 0

    private let client = LLMWordClient()

    private var deck: [GermanWordData] {
        var seen = Set<String>()
        return (store.history + ReferenceLexicon.samples).filter { item in
            let key = item.word.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

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
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.separator))
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
            CardDeckView(
                deck: [selectedWord],
                index: .constant(0),
                onClearSelection: { self.selectedWord = nil }
            )
        } else if !deck.isEmpty {
            CardDeckView(
                deck: deck,
                index: $deckIndex,
                onClearSelection: nil
            )
        } else {
            historyAndReferences
        }
    }

    private var historyAndReferences: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Local Reference Samples")
            FlowButtons(words: ReferenceLexicon.samples.map(\.word)) { word in
                loadReference(word)
            }

            Text(ReferenceLexicon.freeDictStatus)
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .padding(14)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundStyle(AppTheme.primaryText)
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

private struct CardDeckView: View {
    let deck: [GermanWordData]
    @Binding var index: Int
    let onClearSelection: (() -> Void)?
    @State private var dragOffset: CGSize = .zero

    private var current: GermanWordData? {
        guard !deck.isEmpty else { return nil }
        return deck[min(max(index, 0), deck.count - 1)]
    }

    var body: some View {
        VStack(spacing: 12) {
            if let current {
                ZStack {
                    if deck.count > 1, index + 1 < deck.count {
                        WordCardView(data: deck[index + 1])
                            .scaleEffect(0.96)
                            .opacity(0.55)
                            .offset(y: 16)
                    }
                    WordCardView(data: current)
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
                        .gesture(
                            DragGesture()
                                .onChanged { dragOffset = $0.translation }
                                .onEnded { value in handleSwipe(value.translation) }
                        )
                        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: dragOffset)
                }
                controls
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { previous() } label: {
                Label("Previous", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .disabled(deck.count < 2)

            Text(deck.count > 1 ? "\(index + 1) / \(deck.count)" : "Swipe card")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)

            Button { next() } label: {
                Label("Next", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .disabled(deck.count < 2)

            if let onClearSelection {
                Button { onClearSelection() } label: {
                    Label("Deck", systemImage: "rectangle.stack")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func handleSwipe(_ translation: CGSize) {
        if translation.width < -90 || translation.height < -120 {
            next()
        } else if translation.width > 90 || translation.height > 120 {
            previous()
        } else {
            dragOffset = .zero
        }
    }

    private func next() {
        guard !deck.isEmpty else { return }
        index = (index + 1) % deck.count
        dragOffset = .zero
    }

    private func previous() {
        guard !deck.isEmpty else { return }
        index = (index - 1 + deck.count) % deck.count
        dragOffset = .zero
    }
}

private struct FlowButtons: View {
    let words: [String]
    let action: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], alignment: .leading, spacing: 10) {
            ForEach(words, id: \.self) { word in
                Button(word) { action(word) }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.bordered)
                    .tint(.secondary)
            }
        }
    }
}
