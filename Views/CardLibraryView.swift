import SwiftUI

struct CardLibraryView: View {
    @ObservedObject var store: WordStore
    @Environment(\.dismiss) private var dismiss
    @State private var editingCard: GermanWordData?
    @State private var sortOrder = CardSortOrder.ascending

    private var sortedCards: [GermanWordData] {
        store.history.sorted { lhs, rhs in
            let left = lhs.word.localizedStandardCompare(rhs.word)
            switch sortOrder {
            case .ascending:
                return left == .orderedAscending
            case .descending:
                return left == .orderedDescending
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(CardSortOrder.allCases) { order in
                            Text(order.title).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                ForEach(sortedCards) { card in
                    Button {
                        editingCard = card
                    } label: {
                        CardLibraryRow(card: card)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.delete(card)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteSortedCards)
            }
            .overlay {
                if store.history.isEmpty {
                    ContentUnavailableView("No cards", systemImage: "rectangle.stack", description: Text("Generated cards will appear here."))
                }
            }
            .navigationTitle("Manage Cards")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $editingCard) { card in
                CardEditView(store: store, card: card)
            }
        }
    }

    private func deleteSortedCards(at offsets: IndexSet) {
        for index in offsets where sortedCards.indices.contains(index) {
            store.delete(sortedCards[index])
        }
    }
}

private enum CardSortOrder: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ascending:
            return "A-Z"
        case .descending:
            return "Z-A"
        }
    }
}

private struct CardLibraryRow: View {
    let card: GermanWordData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(card.word)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text(card.partOfSpeech)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(card.gender.tint)
            }
            Text(card.meaning)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
            if let english = card.englishMeaning, !english.isEmpty {
                Text(english)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CardEditView: View {
    @ObservedObject var store: WordStore
    @Environment(\.dismiss) private var dismiss
    let card: GermanWordData

    @State private var word: String
    @State private var meaning: String
    @State private var englishMeaning: String
    @State private var partOfSpeech: String
    @State private var gender: GrammaticalGender
    @State private var pluralForm: String
    @State private var exampleSentence: String
    @State private var exampleTranslation: String
    @State private var referenceSource: String
    @State private var notesText: String

    init(store: WordStore, card: GermanWordData) {
        self.store = store
        self.card = card
        _word = State(initialValue: card.word)
        _meaning = State(initialValue: card.meaning)
        _englishMeaning = State(initialValue: card.englishMeaning ?? "")
        _partOfSpeech = State(initialValue: card.partOfSpeech)
        _gender = State(initialValue: card.gender)
        _pluralForm = State(initialValue: card.pluralForm)
        _exampleSentence = State(initialValue: card.exampleSentence)
        _exampleTranslation = State(initialValue: card.exampleTranslation)
        _referenceSource = State(initialValue: card.referenceSource)
        _notesText = State(initialValue: card.notes.joined(separator: "\n"))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("German", text: $word)
                        .textInputAutocapitalization(.words)
                    TextField("Meaning", text: $meaning, axis: .vertical)
                    TextField("English", text: $englishMeaning)
                    TextField("Part of speech", text: $partOfSpeech)
                    Picker("Gender", selection: $gender) {
                        ForEach(GrammaticalGender.allCases, id: \.self) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    TextField("Plural", text: $pluralForm)
                }

                Section("Example") {
                    TextField("German sentence", text: $exampleSentence, axis: .vertical)
                    TextField("Translation", text: $exampleTranslation, axis: .vertical)
                }

                Section("Notes") {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 120)
                    TextField("Source", text: $referenceSource)
                }
            }
            .navigationTitle("Edit Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let updated = GermanWordData(
            word: word.trimmingCharacters(in: .whitespacesAndNewlines),
            meaning: meaning.trimmingCharacters(in: .whitespacesAndNewlines),
            englishMeaning: englishMeaning.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            partOfSpeech: partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines),
            gender: gender,
            pluralForm: pluralForm.trimmingCharacters(in: .whitespacesAndNewlines),
            declensionTable: card.declensionTable,
            verbConjugation: card.verbConjugation,
            exampleSentence: exampleSentence.trimmingCharacters(in: .whitespacesAndNewlines),
            exampleTranslation: exampleTranslation.trimmingCharacters(in: .whitespacesAndNewlines),
            referenceSource: referenceSource.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notesText
                .split(separator: "\n")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            isValidGermanWord: card.isValidGermanWord,
            suggestedWord: card.suggestedWord,
            confidence: card.confidence,
            timestamp: Date().timeIntervalSince1970
        )
        store.replace(original: card, with: updated)
        dismiss()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
