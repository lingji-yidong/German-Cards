import SwiftUI

struct HomeView: View {
    @AppStorage("grammar_language") private var languageRaw = GrammarLanguage.traditionalChinese.rawValue

    private var text: GrammarCopy {
        GrammarCopy(language: GrammarLanguage(rawValue: languageRaw) ?? .traditionalChinese)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ArticleTableCard(copy: text)
                    AdjectiveEndingsCard(copy: text)
                    PrepositionCard(copy: text)
                    VerbPositionCard(copy: text)
                    GenderPatternCard(copy: text)
                }
                .padding(18)
            }
            .background(AppTheme.background)
            .navigationTitle(text.navigationTitle)
        }
    }

}

private struct ArticleTableCard: View {
    let copy: GrammarCopy
    private let rows = [
        ("Nom", "der", "die", "das", "die"),
        ("Akk", "den", "die", "das", "die"),
        ("Dat", "dem", "der", "dem", "den +n"),
        ("Gen", "des +s", "der", "des +s", "der")
    ]

    var body: some View {
        GrammarCard(title: copy.articlesTitle, icon: "text.book.closed", tint: .indigo) {
            VStack(spacing: 0) {
                row(copy.caseLabel, copy.masc, copy.fem, copy.neut, copy.plural, header: true)
                ForEach(rows, id: \.0) { item in
                    Divider()
                    row(item.0, item.1, item.2, item.3, item.4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.separator))
        }
    }

    private func row(_ a: String, _ b: String, _ c: String, _ d: String, _ e: String, header: Bool = false) -> some View {
        Grid {
            GridRow {
                cell(a, .secondary, header)
                cell(b, .blue, header)
                cell(c, .red, header)
                cell(d, .green, header)
                cell(e, .primary, header)
            }
        }
        .padding(.vertical, 10)
        .background(header ? AppTheme.softSurface : AppTheme.elevatedSurface)
    }

    private func cell(_ text: String, _ color: Color, _ header: Bool) -> some View {
        Text(text)
            .font(header ? .caption.weight(.bold) : .subheadline.weight(.bold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .minimumScaleFactor(0.75)
    }
}

private struct AdjectiveEndingsCard: View {
    let copy: GrammarCopy

    var body: some View {
        GrammarCard(title: copy.adjectiveTitle, icon: "paintbrush.pointed", tint: .orange) {
            VStack(alignment: .leading, spacing: 12) {
                MiniRule(title: copy.weakTitle, detail: copy.weakDetail)
                MiniRule(title: copy.mixedTitle, detail: copy.mixedDetail)
                MiniRule(title: copy.strongTitle, detail: copy.strongDetail)
            }
        }
    }
}

private struct PrepositionCard: View {
    let copy: GrammarCopy

    var body: some View {
        GrammarCard(title: copy.prepositionTitle, icon: "arrow.triangle.branch", tint: .teal) {
            VStack(alignment: .leading, spacing: 18) {
                ChipGroup(title: "Akkusativ", tint: .red, words: ["durch", "für", "gegen", "ohne", "um", "bis"])
                ChipGroup(title: "Dativ", tint: .blue, words: ["aus", "bei", "mit", "nach", "seit", "von", "zu", "gegenüber"])
                ChipGroup(title: "Wechsel", tint: .purple, words: ["an", "auf", "hinter", "in", "neben", "über", "unter", "vor", "zwischen"])
                MiniRule(title: copy.whereTitle, detail: copy.whereDetail)
            }
        }
    }
}

private struct VerbPositionCard: View {
    let copy: GrammarCopy

    var body: some View {
        GrammarCard(title: copy.verbTitle, icon: "arrow.left.arrow.right", tint: .cyan) {
            VStack(alignment: .leading, spacing: 12) {
                MiniRule(title: copy.mainClauseTitle, detail: copy.mainClauseDetail)
                MiniRule(title: copy.questionTitle, detail: copy.questionDetail)
                MiniRule(title: copy.subordinateTitle, detail: copy.subordinateDetail)
                MiniRule(title: copy.modalTitle, detail: copy.modalDetail)
            }
        }
    }
}

private struct GenderPatternCard: View {
    let copy: GrammarCopy

    var body: some View {
        GrammarCard(title: copy.genderTitle, icon: "circle.hexagongrid", tint: .green) {
            VStack(alignment: .leading, spacing: 12) {
                MiniRule(title: copy.feminineTitle, detail: "-ung, -heit, -keit, -schaft, -ei, -ion, -tät")
                MiniRule(title: copy.neuterTitle, detail: "-chen, -lein, substantivierte Infinitive")
                MiniRule(title: copy.masculineTitle, detail: copy.masculineDetail)
                MiniRule(title: copy.verifyTitle, detail: copy.verifyDetail)
            }
        }
    }
}

private struct GrammarCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.separator))
    }
}

private struct MiniRule: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ChipGroup: View {
    let title: String
    let tint: Color
    let words: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(words, id: \.self) { word in
                    Text(word)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .padding(.horizontal, 10)
                        .background(tint.opacity(0.14))
                        .foregroundStyle(tint)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

private struct GrammarCopy {
    let language: GrammarLanguage

    var navigationTitle: String { value("語法", "语法", "Grammar") }
    var articlesTitle: String { value("定冠詞 der / die / das", "定冠词 der / die / das", "Definite articles") }
    var caseLabel: String { value("格", "格", "Case") }
    var masc: String { value("陽性", "阳性", "Masc") }
    var fem: String { value("陰性", "阴性", "Fem") }
    var neut: String { value("中性", "中性", "Neut") }
    var plural: String { value("複數", "复数", "Plural") }
    var adjectiveTitle: String { value("形容詞詞尾", "形容词词尾", "Adjective endings") }
    var weakTitle: String { value("弱變化：der gute Wein", "弱变化：der gute Wein", "Weak: der gute Wein") }
    var weakDetail: String { value("定冠詞已經標明格和性，形容詞多用 -e 或 -en。", "定冠词已经标明格和性，形容词多用 -e 或 -en。", "The article already marks case and gender, so adjectives mostly take -e or -en.") }
    var mixedTitle: String { value("混合變化：ein guter Wein", "混合变化：ein guter Wein", "Mixed: ein guter Wein") }
    var mixedDetail: String { value("ein 類冠詞缺少部分標記，形容詞要補出 -er / -es。", "ein 类冠词缺少部分标记，形容词要补出 -er / -es。", "Ein-words miss some markers, so the adjective supplies -er or -es.") }
    var strongTitle: String { value("強變化：guter Wein", "强变化：guter Wein", "Strong: guter Wein") }
    var strongDetail: String { value("沒有冠詞時，形容詞承擔主要格/性標記。", "没有冠词时，形容词承担主要格/性标记。", "Without an article, the adjective carries the main case and gender marker.") }
    var prepositionTitle: String { value("介詞支配的格", "介词支配的格", "Preposition cases") }
    var whereTitle: String { value("Wo? / Wohin?", "Wo? / Wohin?", "Wo? / Wohin?") }
    var whereDetail: String { value("位置問 Wo? 用 Dativ；方向問 Wohin? 用 Akkusativ。", "位置问 Wo? 用 Dativ；方向问 Wohin? 用 Akkusativ。", "Location asks Wo? and takes dative; direction asks Wohin? and takes accusative.") }
    var verbTitle: String { value("動詞位置", "动词位置", "Verb position") }
    var mainClauseTitle: String { value("主句", "主句", "Main clause") }
    var mainClauseDetail: String { value("變位動詞在第 2 位：Heute lerne ich Deutsch.", "变位动词在第 2 位：Heute lerne ich Deutsch.", "The finite verb is second: Heute lerne ich Deutsch.") }
    var questionTitle: String { value("是/否問句", "是/否问句", "Yes/no question") }
    var questionDetail: String { value("變位動詞在第 1 位：Lernst du Deutsch?", "变位动词在第 1 位：Lernst du Deutsch?", "The finite verb is first: Lernst du Deutsch?") }
    var subordinateTitle: String { value("從句", "从句", "Subordinate clause") }
    var subordinateDetail: String { value("weil / dass 從句中，變位動詞到句末。", "weil / dass 从句中，变位动词到句末。", "With weil or dass, the finite verb moves to the end.") }
    var modalTitle: String { value("情態動詞", "情态动词", "Modal verbs") }
    var modalDetail: String { value("情態動詞變位，實義動詞原形放句末。", "情态动词变位，实义动词原形放句末。", "The modal is finite; the main verb stays infinitive at the end.") }
    var genderTitle: String { value("名詞性別規律", "名词性别规律", "Gender patterns") }
    var feminineTitle: String { value("常見陰性", "常见阴性", "Usually feminine") }
    var neuterTitle: String { value("常見中性", "常见中性", "Usually neuter") }
    var masculineTitle: String { value("常見陽性", "常见阳性", "Often masculine") }
    var masculineDetail: String { value("星期、月份、季節，以及很多 -er 表人名詞。", "星期、月份、季节，以及很多 -er 表人名词。", "Days, months, seasons, and many -er agent nouns.") }
    var verifyTitle: String { value("仍需核對", "仍需核对", "Always verify") }
    var verifyDetail: String { value("複合詞看最後一個詞：das Wörterbuch 跟 das Buch。", "复合词看最后一个词：das Wörterbuch 跟 das Buch。", "Compound nouns take the gender of the final noun: das Wörterbuch follows das Buch.") }

    private func value(_ traditional: String, _ simplified: String, _ english: String) -> String {
        switch language {
        case .traditionalChinese:
            return traditional
        case .simplifiedChinese:
            return simplified
        case .english:
            return english
        }
    }
}
