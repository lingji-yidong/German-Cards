import Foundation
import Combine

@MainActor
final class WordStore: ObservableObject {
    @Published private(set) var history: [GermanWordData] = []
    @Published private(set) var storageDescription = "Local dictionary"

    private let storageKey = "german_cards_history_v1"
    private let fileName = "GermanCardsDictionary.json"

    init() {
        load()
    }

    var count: Int { history.count }

    func findCached(_ word: String) -> GermanWordData? {
        let normalized = normalize(word)
        return history.first { normalize($0.word) == normalized }
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

    private func load() {
        if let fileURL = dictionaryFileURL(),
           let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([GermanWordData].self, from: data) {
            history = decoded.sorted { $0.timestamp > $1.timestamp }
            storageDescription = "iCloud Drive dictionary"
            mirrorToUserDefaults()
            return
        }

        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            history = []
            storageDescription = iCloudDocumentsDirectory() == nil ? "Local dictionary" : "iCloud ready"
            return
        }
        history = ((try? JSONDecoder().decode([GermanWordData].self, from: data)) ?? [])
            .sorted { $0.timestamp > $1.timestamp }
        storageDescription = iCloudDocumentsDirectory() == nil ? "Local dictionary" : "Local dictionary, iCloud file will be created after next save"
    }

    private func persist() {
        mirrorToUserDefaults()
        guard let data = try? JSONEncoder().encode(history) else { return }
        if let fileURL = dictionaryFileURL(createDirectory: true) {
            do {
                try data.write(to: fileURL, options: [.atomic])
                storageDescription = "iCloud Drive dictionary"
            } catch {
                storageDescription = "Local dictionary, iCloud write failed"
            }
        } else {
            storageDescription = "Local dictionary"
        }
    }

    private func mirrorToUserDefaults() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func dictionaryFileURL(createDirectory: Bool = false) -> URL? {
        guard let directory = iCloudDocumentsDirectory() else { return nil }
        if createDirectory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent(fileName)
    }

    private func iCloudDocumentsDirectory() -> URL? {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        return container.appendingPathComponent("Documents", isDirectory: true)
    }

    private func normalize(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
