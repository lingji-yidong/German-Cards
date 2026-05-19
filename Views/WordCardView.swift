import SwiftUI

struct WordCardView: View {
    let data: GermanWordData

    var body: some View {
        VStack(spacing: 0) {
            header
            declension
            example
            notes
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(data.gender.tint.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: data.gender.tint.opacity(0.16), radius: 22, x: 0, y: 12)
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Label(data.partOfSpeech, systemImage: "tag")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(data.gender.softTint)
                    .foregroundStyle(data.gender.tint)
                    .clipShape(Capsule())
                Spacer()
                Text(data.referenceSource)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if !data.displayArticle.isEmpty {
                        Text(data.displayArticle)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(data.gender.tint)
                    }
                    Text(data.word)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.10, green: 0.12, blue: 0.16))
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                }

                if data.pluralForm != "-" {
                    Text("Plural: \(data.pluralForm)")
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            Text(data.meaning)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(red: 0.19, green: 0.22, blue: 0.27))
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [data.gender.softTint, Color(red: 0.98, green: 0.98, blue: 0.97)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var declension: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Kasus / Declension", systemImage: "tablecells")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                tableRow("Case", "Singular", "Plural", isHeader: true)
                ForEach(data.declensionTable) { row in
                    Divider()
                    tableRow(row.caseName, row.singular, row.plural)
                }
            }
            .background(Color(red: 0.98, green: 0.98, blue: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .padding(18)
    }

    private func tableRow(_ first: String, _ second: String, _ third: String, isHeader: Bool = false) -> some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 0) {
            GridRow {
                Text(first)
                    .font(isHeader ? .caption.weight(.bold) : .caption.weight(.semibold))
                    .foregroundStyle(isHeader ? .secondary : data.gender.tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(second)
                    .font(isHeader ? .caption.weight(.bold) : .subheadline.weight(.medium))
                    .foregroundStyle(isHeader ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(third)
                    .font(isHeader ? .caption.weight(.bold) : .subheadline.weight(.medium))
                    .foregroundStyle(isHeader ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isHeader ? 10 : 12)
    }

    private var example: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Beispiel", systemImage: "quote.opening")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(data.exampleSentence)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            Text(data.exampleTranslation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(red: 0.99, green: 0.99, blue: 0.985))
    }

    @ViewBuilder
    private var notes: some View {
        if !data.notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Notes", systemImage: "checkmark.seal")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                ForEach(data.notes, id: \.self) { note in
                    Text("• \(note)")
                        .font(.footnote)
                        .foregroundStyle(Color(red: 0.28, green: 0.30, blue: 0.34))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}
