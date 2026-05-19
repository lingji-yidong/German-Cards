import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    ArticleTableCard()
                    AdjectiveEndingsCard()
                    PrepositionCard()
                    VerbPositionCard()
                    GenderPatternCard()
                }
                .padding(18)
            }
            .background(AppTheme.background)
            .navigationTitle("Grammar")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WortSchatz")
                .font(.system(size: 34, weight: .black, design: .rounded))
            Text("德語卡片與語法速查。名詞卡優先使用本地 reference，缺資料時再呼叫你設定的 LLM。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [Color.white, Color(red: 0.91, green: 0.96, blue: 0.94)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ArticleTableCard: View {
    private let rows = [
        ("Nom", "der", "die", "das", "die"),
        ("Akk", "den", "die", "das", "die"),
        ("Dat", "dem", "der", "dem", "den +n"),
        ("Gen", "des +s", "der", "des +s", "der")
    ]

    var body: some View {
        GrammarCard(title: "Definite Articles", icon: "text.book.closed", tint: .indigo) {
            VStack(spacing: 0) {
                row("Case", "Masc", "Fem", "Neut", "Pl", header: true)
                ForEach(rows, id: \.0) { item in
                    Divider()
                    row(item.0, item.1, item.2, item.3, item.4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06)))
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
        .background(header ? Color.black.opacity(0.035) : Color.white)
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
    var body: some View {
        GrammarCard(title: "Adjective Endings", icon: "paintbrush.pointed", tint: .orange) {
            VStack(alignment: .leading, spacing: 12) {
                MiniRule(title: "Weak: der gute Wein", detail: "定冠詞已標明格/性，多數形容詞用 -e 或 -en。")
                MiniRule(title: "Mixed: ein guter Wein", detail: "ein 類冠詞缺少部分標記，形容詞需補 -er/-es。")
                MiniRule(title: "Strong: guter Wein", detail: "無冠詞時，形容詞承擔主要標記：guter, gute, gutes。")
            }
        }
    }
}

private struct PrepositionCard: View {
    var body: some View {
        GrammarCard(title: "Prepositions", icon: "arrow.triangle.branch", tint: .teal) {
            VStack(alignment: .leading, spacing: 14) {
                ChipGroup(title: "Akkusativ", tint: .red, words: ["durch", "für", "gegen", "ohne", "um", "bis"])
                ChipGroup(title: "Dativ", tint: .blue, words: ["aus", "bei", "mit", "nach", "seit", "von", "zu", "gegenüber"])
                ChipGroup(title: "Wechsel", tint: .purple, words: ["an", "auf", "hinter", "in", "neben", "über", "unter", "vor", "zwischen"])
                MiniRule(title: "Wo? vs. Wohin?", detail: "位置 Wo? 用 Dativ；方向/移動 Wohin? 用 Akkusativ。")
            }
        }
    }
}

private struct VerbPositionCard: View {
    var body: some View {
        GrammarCard(title: "Verb Position", icon: "arrow.left.arrow.right", tint: .cyan) {
            VStack(alignment: .leading, spacing: 12) {
                MiniRule(title: "Main clause", detail: "變位動詞在第 2 位：Heute lerne ich Deutsch.")
                MiniRule(title: "Yes/No question", detail: "動詞在第 1 位：Lernst du Deutsch?")
                MiniRule(title: "Subordinate clause", detail: "weil/dass 從句中變位動詞到句末：..., weil ich Deutsch lerne.")
                MiniRule(title: "Modal verbs", detail: "情態動詞變位，實義動詞原形在句末：Ich kann heute lernen.")
            }
        }
    }
}

private struct GenderPatternCard: View {
    var body: some View {
        GrammarCard(title: "Gender Patterns", icon: "circle.hexagongrid", tint: .green) {
            VStack(alignment: .leading, spacing: 12) {
                MiniRule(title: "Usually feminine", detail: "-ung, -heit, -keit, -schaft, -ei, -ion, -tät")
                MiniRule(title: "Usually neuter", detail: "-chen, -lein, infinitives used as nouns, many metals and letters")
                MiniRule(title: "Often masculine", detail: "days/months/seasons, many -er agent nouns, weather directions")
                MiniRule(title: "Always verify", detail: "複合詞性別取最後一個詞：das Wörterbuch follows das Buch.")
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06)))
    }
}

private struct MiniRule: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.bold))
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ChipGroup: View {
    let title: String
    let tint: Color
    let words: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            FlowLayout(items: words) { word in
                Text(word)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(tint.opacity(0.12))
                    .foregroundStyle(tint)
                    .clipShape(Capsule())
            }
        }
    }
}

private struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
            }
        }
    }
}

enum AppTheme {
    static let background = Color(red: 0.955, green: 0.96, blue: 0.95)
}
