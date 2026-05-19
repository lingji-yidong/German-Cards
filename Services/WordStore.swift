import Foundation
import Combine

@MainActor
final class WordStore: ObservableObject {
    @Published private(set) var history: [GermanWordData] = []

    private let storageKey = "german_cards_history_v1"

    init() {
        load()
    }

    func findCached(_ word: String) -> GermanWordData? {
        let normalized = normalize(word)
        return history.first { normalize($0.word) == normalized }
    }

    func save(_ data: GermanWordData) {
        history.removeAll { normalize($0.word) == normalize(data.word) }
        history.insert(data, at: 0)
        if history.count > 80 {
            history = Array(history.prefix(80))
        }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        history = (try? JSONDecoder().decode([GermanWordData].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func normalize(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
