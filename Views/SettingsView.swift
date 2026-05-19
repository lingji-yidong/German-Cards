import SwiftUI

struct SettingsView: View {
    @AppStorage("llm_provider") private var providerRaw = LLMProvider.openAICompatible.rawValue
    @AppStorage("llm_base_url") private var baseURL = LLMProvider.openAICompatible.defaultBaseURL
    @AppStorage("llm_model") private var model = LLMProvider.openAICompatible.defaultModel
    @AppStorage("llm_api_key") private var apiKey = ""
    @State private var saved = false

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
                Section("LLM Provider") {
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
                } footer: {
                    Text("OpenAI-compatible 和 Custom 會呼叫 {Base URL}/chat/completions。Gemini 會呼叫 {Base URL}/models/{model}:generateContent。")
                }

                Section("Dictionary Reference") {
                    Label("Local reference first", systemImage: "books.vertical")
                    Text(ReferenceLexicon.sourceSummary)
                        .font(.footnote)
                    Text("後續可把 FreeDict TEI 或 Wiktionary dump 轉成 bundled JSON，查詞時先本地命中，再 fallback 到 LLM。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
