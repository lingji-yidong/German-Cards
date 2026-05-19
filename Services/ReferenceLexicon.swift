import Foundation

enum ReferenceLexicon {
    static let sourceSummary = "Bundled reference: curated common nouns cross-checked against Wiktionary-style article/plural data; recommended external datasets for expansion: FreeDict TEI (GPL) and Wiktionary dumps (CC BY-SA)."

    private static let entries: [String: GermanWordData] = Dictionary(uniqueKeysWithValues: [
        noun("Apfel", "苹果", .masculine, "Äpfel", "der Apfel", "den Apfel", "dem Apfel", "des Apfels", "den Äpfeln", "Ich esse einen roten Apfel.", "我吃一个红苹果。", ["Plural changes vowel: Apfel -> Äpfel."]),
        noun("Haus", "房子；家", .neuter, "Häuser", "das Haus", "das Haus", "dem Haus", "des Hauses", "den Häusern", "Das Haus steht am Fluss.", "这栋房子在河边。", ["Plural takes Umlaut and -er: Haus -> Häuser."]),
        noun("Zeit", "时间", .feminine, "Zeiten", "die Zeit", "die Zeit", "der Zeit", "der Zeit", "den Zeiten", "Die Zeit vergeht schnell.", "时间过得很快。", ["Abstract nouns ending in -heit/-keit/-ung are usually feminine; Zeit is a core feminine noun."]),
        noun("Buch", "书", .neuter, "Bücher", "das Buch", "das Buch", "dem Buch", "des Buches", "den Büchern", "Ich lese ein deutsches Buch.", "我读一本德语书。", ["Plural takes Umlaut and -er: Buch -> Bücher."]),
        noun("Tisch", "桌子", .masculine, "Tische", "der Tisch", "den Tisch", "dem Tisch", "des Tisches", "den Tischen", "Der Tisch ist aus Holz.", "这张桌子是木制的。", ["Regular masculine noun with plural -e."]),
        noun("Sprache", "语言", .feminine, "Sprachen", "die Sprache", "die Sprache", "der Sprache", "der Sprache", "den Sprachen", "Deutsch ist eine schöne Sprache.", "德语是一门美丽的语言。", ["Many nouns ending in -e are feminine."]),
        noun("Arbeit", "工作；劳动", .feminine, "Arbeiten", "die Arbeit", "die Arbeit", "der Arbeit", "der Arbeit", "den Arbeiten", "Die Arbeit beginnt um neun Uhr.", "工作九点开始。", ["Nouns ending in -eit are usually feminine."]),
        noun("Wasser", "水", .neuter, "Wasser", "das Wasser", "das Wasser", "dem Wasser", "des Wassers", "den Wassern", "Ich trinke ein Glas Wasser.", "我喝一杯水。", ["Mass noun; plural is uncommon and context-dependent."]),
        noun("Mensch", "人；人类", .masculine, "Menschen", "der Mensch", "den Menschen", "dem Menschen", "des Menschen", "den Menschen", "Der Mensch lernt jeden Tag.", "人每天都在学习。", ["Weak masculine noun: der Mensch, den/dem/des Menschen."]),
        noun("Frage", "问题", .feminine, "Fragen", "die Frage", "die Frage", "der Frage", "der Frage", "den Fragen", "Die Frage ist wichtig.", "这个问题很重要。", ["Nouns ending in -e are often feminine and commonly form plural with -n."]),
        noun("Kind", "孩子", .neuter, "Kinder", "das Kind", "das Kind", "dem Kind", "des Kindes", "den Kindern", "Das Kind spielt im Garten.", "孩子在花园里玩。", ["Neuter noun with plural -er."]),
        noun("Tag", "天；日子", .masculine, "Tage", "der Tag", "den Tag", "dem Tag", "des Tages", "den Tagen", "Der Tag ist lang.", "这一天很长。", ["Common masculine noun with plural -e."])
    ])

    static func lookup(_ rawWord: String) -> GermanWordData? {
        let key = normalize(rawWord)
        return entries[key]
    }

    static var samples: [GermanWordData] {
        entries.values.sorted { $0.word < $1.word }
    }

    private static func normalize(_ word: String) -> String {
        word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func noun(_ word: String, _ meaning: String, _ gender: GrammaticalGender, _ plural: String, _ nominative: String, _ accusative: String, _ dative: String, _ genitive: String, _ dativePlural: String, _ example: String, _ translation: String, _ notes: [String]) -> (String, GermanWordData) {
        let data = GermanWordData(
            word: word,
            meaning: meaning,
            partOfSpeech: "Noun",
            gender: gender,
            pluralForm: plural,
            declensionTable: [
                DeclensionRow(caseName: "Nominativ", singular: nominative, plural: "die \(plural)"),
                DeclensionRow(caseName: "Akkusativ", singular: accusative, plural: "die \(plural)"),
                DeclensionRow(caseName: "Dativ", singular: dative, plural: dativePlural),
                DeclensionRow(caseName: "Genitiv", singular: genitive, plural: "der \(plural)")
            ],
            exampleSentence: example,
            exampleTranslation: translation,
            referenceSource: "Local reference lexicon",
            notes: notes,
            timestamp: Date().timeIntervalSince1970
        )
        return (normalize(word), data)
    }

}
