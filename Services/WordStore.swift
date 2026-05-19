import Foundation
import Combine

@MainActor
final class WordStore: ObservableObject {
    @Published private(set) var history: [GermanWordData] = []
    @Published private(set) var storageDescription = "Local dictionary"

    private let storageKey = "german_cards_history_v1"

    init() {
        load()
    }

    var count: Int { history.count }

    func findCached(_ word: String) -> GermanWordData? {
        let normalized = normalize(word)
        return history.first { card in
            normalize(card.word) == normalized ||
            normalize(card.pluralForm) == normalized ||
            card.declensionTable.contains { row in
                normalize(row.singular) == normalized || normalize(row.plural) == normalized
            } ||
            card.displayedVerbConjugation.contains { row in
                normalize(row.form) == normalized
            }
        }
    }

    func save(_ data: GermanWordData) {
        history.removeAll { normalize($0.word) == normalize(data.word) }
        history.insert(data, at: 0)
        persist()
    }

    func replace(original: GermanWordData, with updated: GermanWordData) {
        history.removeAll { item in
            normalize(item.word) == normalize(original.word) || normalize(item.word) == normalize(updated.word)
        }
        history.insert(updated, at: 0)
        persist()
    }

    func delete(_ data: GermanWordData) {
        history.removeAll { normalize($0.word) == normalize(data.word) }
        persist()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where history.indices.contains(index) {
            history.remove(at: index)
        }
        persist()
    }

    func reload() {
        load()
    }

    func exportData() throws -> Data {
        let archive = DictionaryArchive(cards: history)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    @discardableResult
    func importData(_ data: Data) throws -> Int {
        let cards = try decodeImportedCards(from: data)
        for card in cards {
            history.removeAll { normalize($0.word) == normalize(card.word) }
            history.append(card)
        }
        history.sort { $0.timestamp > $1.timestamp }
        persist()
        return cards.count
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            history = []
            storageDescription = "Local dictionary"
            return
        }
        history = ((try? JSONDecoder().decode([GermanWordData].self, from: data)) ?? [])
            .sorted { $0.timestamp > $1.timestamp }
        storageDescription = "Local dictionary"
    }

    private func persist() {
        // UserDefaults is the local store; export/import handles user-controlled sync.
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        storageDescription = "Local dictionary"
    }

    private func decodeImportedCards(from data: Data) throws -> [GermanWordData] {
        let decoder = JSONDecoder()
        if let archive = try? decoder.decode(DictionaryArchive.self, from: data) {
            return archive.cards
        }
        return try decoder.decode([GermanWordData].self, from: data)
    }

    private func normalize(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}


private struct DictionaryArchive: Codable {
    let archiveVersion: Int
    let exportedAt: TimeInterval
    let cards: [GermanWordData]

    init(cards: [GermanWordData]) {
        self.archiveVersion = 1
        self.exportedAt = Date().timeIntervalSince1970
        self.cards = cards
    }
}
