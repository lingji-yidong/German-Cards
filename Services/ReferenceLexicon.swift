import Foundation

enum ReferenceLexicon {
    static let sourceSummary = "Your dictionary starts empty and grows from cards you generate or save. No bundled third-party dictionary is shipped."

    static func lookup(_ rawWord: String) -> GermanWordData? {
        nil
    }

    static var samples: [GermanWordData] {
        []
    }

    static var dictionaryStatus: String {
        sourceSummary
    }
}
