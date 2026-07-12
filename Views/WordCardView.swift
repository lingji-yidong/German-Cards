import SwiftUI
import AVFoundation

struct WordCardView: View {
    let data: GermanWordData
    private static let speechSynthesizer = AVSpeechSynthesizer()
    private static let disclosureAnimation = Animation.easeInOut(duration: 0.32)
    @State private var isDeclensionExpanded = false
    @State private var isConjugationExpanded = false
    @State private var isAdjectiveComparisonExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            header
            declension
            conjugation
            adjectiveComparison
            example
            notes
        }
        .background(AppTheme.elevatedSurface)
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
                Label(data.partOfSpeech.label, systemImage: "tag")
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
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .layoutPriority(2)
                    }
                    Text(data.word)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .layoutPriority(1)
                        .textSelection(.enabled)
                    Button {
                        speak(data.word)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.title3.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(data.gender.tint)
                    .fixedSize()
                    .accessibilityLabel("朗讀德語詞")
                }

                if let englishMeaning = data.englishMeaning, !englishMeaning.isEmpty {
                    Text("English: \(englishMeaning)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
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
                .foregroundStyle(AppTheme.primaryText)
                .textSelection(.enabled)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [data.gender.softTint, AppTheme.softSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var declension: some View {
        VStack(alignment: .leading, spacing: 12) {
            disclosureHeader(
                title: "Kasus / Declension",
                summary: "\(data.declensionTable.count) cases · singular & plural",
                systemImage: "tablecells",
                isExpanded: $isDeclensionExpanded
            )

            if isDeclensionExpanded {
                VStack(spacing: 0) {
                    tableRow("Case", "Singular", "Plural", isHeader: true)
                    ForEach(data.declensionTable) { row in
                        Divider()
                        tableRow(row.caseName, row.singular, row.plural)
                    }
                }
                .background(AppTheme.softSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
                .transition(.opacity)
            }
        }
        .padding(18)
    }

    private func disclosureHeader(
        title: String,
        summary: String,
        systemImage: String,
        isExpanded: Binding<Bool>
    ) -> some View {
        Button {
            withAnimation(Self.disclosureAnimation) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(data.gender.tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(data.gender.tint)
                        .textCase(.uppercase)
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(data.gender.tint)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
                    .frame(width: 32, height: 32)
            }
            .contentShape(Rectangle())
            .padding(14)
            .background(data.gender.tint.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(data.gender.tint.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded.wrappedValue ? "Expanded" : "Collapsed")
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

    @ViewBuilder
    private var conjugation: some View {
        let rows = data.displayedVerbConjugation
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                disclosureHeader(
                    title: "Verb Conjugation",
                    summary: "\(rows.count) forms",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    isExpanded: $isConjugationExpanded
                )

                if isConjugationExpanded {
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(row.tense)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(data.gender.tint)
                                    .frame(width: 74, alignment: .leading)
                                Text(row.pronoun)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .leading)
                                Text(row.form)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .textSelection(.enabled)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            if row.id != rows.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(AppTheme.softSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.separator))
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private var adjectiveComparison: some View {
        if let comparison = data.displayedAdjectiveComparison {
            VStack(alignment: .leading, spacing: 12) {
                disclosureHeader(
                    title: "Adjective Comparison",
                    summary: "positive · comparative · superlative",
                    systemImage: "arrow.up.forward",
                    isExpanded: $isAdjectiveComparisonExpanded
                )

                if isAdjectiveComparisonExpanded {
                    VStack(spacing: 0) {
                        comparisonRow("Positive", comparison.positive)
                        Divider()
                        comparisonRow("Comparative", comparison.comparative)
                        Divider()
                        comparisonRow("Superlative", comparison.superlative)
                    }
                    .background(AppTheme.softSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.separator))
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
    }

    private func comparisonRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(data.gender.tint)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var example: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Beispiel", systemImage: "quote.opening")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    speak(data.exampleSentence)
                } label: {
                    Image(systemName: "waveform")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(data.gender.tint)
                .accessibilityLabel("朗讀德語例句")
            }
            Text(data.exampleSentence)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .textSelection(.enabled)
            Text(data.exampleTranslation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.softSurface)
    }

    private func speak(_ text: String) {
        if Self.speechSynthesizer.isSpeaking {
            Self.speechSynthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        Self.speechSynthesizer.speak(utterance)
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
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}
