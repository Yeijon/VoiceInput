import Foundation

final class LLMTranslationProvider: TranslationProvider {
    let id = "llm"
    let displayName = "OpenAI-compatible LLM"

    private let settings: AppSettings
    private var client: OpenAICompatibleClient?

    init(settings: AppSettings) {
        self.settings = settings
    }

    var isConfigured: Bool {
        !settings.llmConfiguration.apiKey.isEmpty
    }

    func translate(_ request: TranslationRequest, completion: @escaping (Result<TranslationResult, Error>) -> Void) {
        let config = settings.llmConfiguration
        let client = OpenAICompatibleClient(baseURL: config.baseURL, apiKey: config.apiKey)
        self.client = client

        let systemPrompt = """
        You are a translation engine.

        Task:
        Translate the user text from \(TranslationLanguages.llmName(for: request.sourceLanguage)) to \(TranslationLanguages.llmName(for: request.targetLanguage)).

        Rules:
        - Return only the translation result.
        - Do not output explanations, reasoning, analysis, comments, or notes.
        - Do not output chain-of-thought or hidden reasoning.
        - Do not output XML/HTML-style tags such as <think>.
        - Do not output markdown code fences or formatting wrappers.
        - Do not prepend labels such as "Translation:", "Translated text:", or similar prefixes.
        - Preserve the original meaning, tone, and register.
        - Keep the text concise and natural in the target language.
        - Preserve line breaks only when required by the source text.
        - If the input is already in the target language, return it unchanged.

        Output:
        Return exactly one plain-text translation and nothing else.
        """

        let messages = [
            LLMMessage(role: "system", content: systemPrompt),
            LLMMessage(role: "user", content: request.text),
        ]

        client.complete(messages, model: config.model, temperature: 0.2) { result in
            switch result {
            case .success(let text):
                let cleaned = Self.cleanTranslationOutput(text)
                completion(.success(TranslationResult(
                    text: cleaned,
                    providerID: self.id,
                    model: config.model,
                    cached: false
                )))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func cancel() {
        client?.cancel()
    }

    static func cleanTranslationOutput(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(
            of: "<think>[\\s\\S]*?</think>",
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "```[\\s\\S]*?```",
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: "^(translation|translated text|final translation)\\s*[:：]\\s*",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        let blocks = cleaned
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if let candidate = blocks.last, blocks.count > 1 {
            if !candidate.isEmpty {
                cleaned = candidate
            }
        }

        return cleaned.isEmpty ? text.trimmingCharacters(in: .whitespacesAndNewlines) : cleaned
    }
}
