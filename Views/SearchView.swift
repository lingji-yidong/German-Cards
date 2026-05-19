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
    @State private var showingLibrary = false
    @State private var normalizedLookupMessage: String?
    @State private var suggestion: WordSuggestion?
    @FocusState private var isSearchFocused: Bool

    private let client = LLMWordClient()

    private var deck: [GermanWordData] { store.history }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    searchBar
                    dictionarySummary
                    normalizedLookupBanner
                    statusContent
                }
                .padding(18)
            }
            .background(AppTheme.background)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { isSearchFocused = false }
            .navigationTitle("Cards")
            .sheet(isPresented: $showingLibrary) {
                CardLibraryView(store: store)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Generate a German word card", text: $query)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit { Task { await search() } }
            if !query.isEmpty {
                Button {
                    query = ""
                    suggestion = nil
                    errorMessage = nil
                    selectedWord = nil
                    normalizedLookupMessage = nil
                    isSearchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button {
                Task { await search() }
            } label: {
                Image(systemName: isLoading ? "hourglass" : "sparkles")
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

    private var dictionarySummary: some View {
        HStack(spacing: 12) {
            Label("\(store.count) cards", systemImage: "rectangle.stack")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
            Text(store.storageDescription)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
            Button {
                showingLibrary = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.bordered)
            .disabled(store.history.isEmpty)
            .accessibilityLabel("管理卡片")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.separator))
    }

    @ViewBuilder
    private var normalizedLookupBanner: some View {
        if let normalizedLookupMessage {
            Label(normalizedLookupMessage, systemImage: "arrow.triangle.branch")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.separator))
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        if isLoading {
            ProgressView("Generating card...")
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else if let suggestion {
            suggestionView(suggestion)
        } else if let errorMessage {
            ContentUnavailableView("Lookup failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
        } else if let selectedWord {
            CardDeckView(
                deck: [selectedWord],
                index: .constant(0),
                onClearSelection: { self.selectedWord = nil }
            )
        } else if !deck.isEmpty {
            CardDeckView(deck: deck, index: $deckIndex, onClearSelection: nil)
        } else {
            emptyDictionary
        }
    }

    private func suggestionView(_ suggestion: WordSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("檢查拼寫", systemImage: "text.magnifyingglass")
                .font(.headline.weight(.bold))
                .foregroundStyle(.orange)
            Text(suggestion.message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.primaryText)
            HStack(spacing: 10) {
                if let suggestedWord = suggestion.suggestedWord, !suggestedWord.isEmpty {
                    Button {
                        query = suggestedWord
                        self.suggestion = nil
                        Task { await search() }
                    } label: {
                        Label("使用 \(suggestedWord)", systemImage: "arrow.turn.down.right")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button {
                    self.suggestion = nil
                    isSearchFocused = true
                } label: {
                    Text("修改")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.separator))
    }

    private var emptyDictionary: some View {
        ContentUnavailableView(
            "Start your own dictionary",
            systemImage: "rectangle.stack.badge.plus",
            description: Text("Generate your first card above. Saved cards become your personal dictionary and can be exported from Settings.")
        )
        .padding(.top, 24)
    }

    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }

        isSearchFocused = false
        errorMessage = nil
        suggestion = nil
        normalizedLookupMessage = nil
        if let cached = store.findCached(term) {
            selectedWord = cached
            updateNormalizedLookupMessage(input: term, result: cached)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let provider = LLMProvider(rawValue: providerRaw) ?? .openAICompatible
            let config = LLMConfiguration(provider: provider, baseURL: baseURL, model: model, apiKey: apiKey)
            let result = try await client.fetchWordInfo(word: term, configuration: config)
            guard result.isProbablyValid else {
                suggestion = WordSuggestion(originalWord: term, suggestedWord: result.suggestedWord, confidence: result.confidence)
                selectedWord = nil
                return
            }
            selectedWord = result
            updateNormalizedLookupMessage(input: term, result: result)
            store.save(result)
            deckIndex = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateNormalizedLookupMessage(input: String, result: GermanWordData) {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedWord = result.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !normalizedInput.isEmpty, normalizedInput != normalizedWord {
            normalizedLookupMessage = "已將 ‘\(input)’ 對應到原型 ‘\(result.word)’"
        } else {
            normalizedLookupMessage = nil
        }
    }
}


private struct WordSuggestion: Equatable {
    let originalWord: String
    let suggestedWord: String?
    let confidence: Double?

    var message: String {
        if let suggestedWord, !suggestedWord.isEmpty {
            return "‘\(originalWord)’ 看起來不像穩定的德語詞。你是不是想查 ‘\(suggestedWord)’？"
        }
        return "‘\(originalWord)’ 看起來不像穩定的德語詞。請檢查拼寫後再生成卡片。"
    }
}

private struct CardDeckView: View {
    let deck: [GermanWordData]
    @Binding var index: Int
    let onClearSelection: (() -> Void)?
    @State private var dragOffset: CGSize = .zero
    @State private var isHorizontalDrag = false

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
                            .scaleEffect(0.94)
                            .opacity(0.18)
                            .saturation(0.65)
                            .blur(radius: 0.8)
                            .offset(y: 12)
                            .allowsHitTesting(false)
                    }
                    WordCardView(data: current)
                        .frame(maxWidth: 430)
                        .offset(x: dragOffset.width, y: dragOffset.height * 0.18)
                        .rotationEffect(.degrees(Double(dragOffset.width / 28)))
                        .simultaneousGesture(cardSwipeGesture)
                        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: dragOffset)
                }
                .frame(maxWidth: .infinity)
                controls
            }
        }
    }

    private var cardSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .onChanged { value in
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)
                if !isHorizontalDrag {
                    isHorizontalDrag = horizontal > 28 && horizontal > vertical * 1.45
                }
                guard isHorizontalDrag else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                defer {
                    isHorizontalDrag = false
                    dragOffset = .zero
                }
                let horizontal = value.translation.width
                let vertical = abs(value.translation.height)
                guard abs(horizontal) > 155, abs(horizontal) > vertical * 1.6 else { return }
                if horizontal < 0 { next() } else { previous() }
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

            Text(deck.count > 1 ? "\(index + 1) / \(deck.count)" : "Swipe firmly sideways")
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

    private func next() {
        guard !deck.isEmpty else { return }
        index = (index + 1) % deck.count
    }

    private func previous() {
        guard !deck.isEmpty else { return }
        index = (index - 1 + deck.count) % deck.count
    }
}
