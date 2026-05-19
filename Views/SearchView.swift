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

    private var deck: [GermanWordData] { store.history }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    searchBar
                    dictionaryProgress
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
            TextField("Generate a German word card", text: $query)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit { Task { await search() } }
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

    private var dictionaryProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your Dictionary")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("\(store.count) cards")
                    .font(.title3.weight(.black).monospacedDigit())
                    .foregroundStyle(AppTheme.brand)
            }

            Text(store.storageDescription)
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)

            VStack(alignment: .leading, spacing: 8) {
                CEFRRow(level: "A1", target: 600, current: store.count)
                CEFRRow(level: "A2", target: 1300, current: store.count)
                CEFRRow(level: "B1", target: 2500, current: store.count)
                CEFRRow(level: "B2", target: 5000, current: store.count)
                CEFRRow(level: "C1", target: 8000, current: store.count)
            }

            Text("CEFR vocabulary counts vary by course and exam. Treat these as practical planning targets, not strict requirements.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(16)
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
            CardDeckView(deck: deck, index: $deckIndex, onClearSelection: nil)
        } else {
            emptyDictionary
        }
    }

    private var emptyDictionary: some View {
        ContentUnavailableView(
            "Start your own dictionary",
            systemImage: "rectangle.stack.badge.plus",
            description: Text("Generate your first card above. Saved cards become your personal dictionary and can be mirrored to iCloud Drive when iCloud is available for the app.")
        )
        .padding(.top, 24)
    }

    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }

        errorMessage = nil
        if let cached = store.findCached(term) {
            selectedWord = cached
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
            deckIndex = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CEFRRow: View {
    let level: String
    let target: Int
    let current: Int

    private var progress: Double {
        min(Double(current) / Double(target), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(level)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(width: 28, alignment: .leading)
                ProgressView(value: progress)
                    .tint(AppTheme.brand)
                Text("\(target)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 48, alignment: .trailing)
            }
        }
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
                            .scaleEffect(0.96)
                            .opacity(0.46)
                            .offset(y: 14)
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
