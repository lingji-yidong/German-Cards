import SwiftUI

struct SettingsView: View {
    @AppStorage("llm_provider") private var providerRaw = LLMProvider.openAICompatible.rawValue
    @AppStorage("llm_base_url") private var baseURL = LLMProvider.openAICompatible.defaultBaseURL
    @AppStorage("llm_model") private var model = LLMProvider.openAICompatible.defaultModel
    @AppStorage("llm_api_key") private var apiKey = ""
    @State private var saved = false
    @AppStorage("app_appearance") private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage("grammar_language") private var grammarLanguageRaw = GrammarLanguage.traditionalChinese.rawValue

    private var appearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    private var grammarLanguage: Binding<GrammarLanguage> {
        Binding(
            get: { GrammarLanguage(rawValue: grammarLanguageRaw) ?? .traditionalChinese },
            set: { grammarLanguageRaw = $0.rawValue }
        )
    }

    private var provider: Binding<LLMProvider> {
        Binding(
            get: { LLMProvider(rawValue: providerRaw) ?? .openAICompatible },
            set: { newValue in
                providerRaw = newValue.rawValue
                if baseURL.isEmpty || baseURL == LLMProvider.openAICompatible.defaultBaseURL || baseURL == LLMProvider.gemini.defaultBaseURL {
                    baseURL = newValue.defaultBaseURL
                }
                if model.isEmpty || model == LLMProvider.openAICompatible.defaultModel || model == LLMProvider.gemini.defaultModel {
                    model = newValue.defaultModel
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    Picker("Grammar Language", selection: grammarLanguage) {
                        ForEach(GrammarLanguage.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } header: {
                    Text("Display")
                } footer: {
                    Text("Appearance follows the system by default. Grammar copy can be switched independently from the device language.")
                }

                Section {
                    Picker("Provider", selection: provider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    TextField("Base URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Model", text: $model)
                        .textInputAutocapitalization(.never)
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                    Button {
                        saved = true
                    } label: {
                        Label(saved ? "Saved" : "Save Configuration", systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                    }
                } header: {
                    Text("LLM Provider")
                } footer: {
                    Text("OpenAI-compatible 和 Custom 會呼叫 {Base URL}/chat/completions。Gemini 會呼叫 {Base URL}/models/{model}:generateContent。")
                }

                Section {
                    Label("User dictionary", systemImage: "icloud.and.arrow.up")
                    Text("Generated cards are saved as your personal dictionary. When iCloud Drive is available for this app, the dictionary is mirrored to iCloud documents as GermanCardsDictionary.json.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("No bundled third-party dictionary is shipped. Your word list starts from zero and grows only from cards you create.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Dictionary")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
