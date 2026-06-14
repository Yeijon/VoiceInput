import Foundation

struct LLMProviderConfiguration {
    var baseURL: String
    var model: String
    var apiKey: String
}

final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let selectedLocaleCode = "selectedLocaleCode"
        static let targetLocaleCode = "targetLocaleCode"
        static let llmBaseURL = "translation.llm.baseURL"
        static let llmModel = "translation.llm.model"
    }

    private let defaults = UserDefaults.standard
    private let keychain = KeychainStore(service: "com.yetone.VoiceInput")

    var selectedLocaleCode: String {
        get { defaults.string(forKey: Keys.selectedLocaleCode) ?? "zh-CN" }
        set { defaults.set(newValue, forKey: Keys.selectedLocaleCode) }
    }

    var targetLocaleCode: String {
        get { defaults.string(forKey: Keys.targetLocaleCode) ?? "en" }
        set { defaults.set(newValue, forKey: Keys.targetLocaleCode) }
    }

    var llmConfiguration: LLMProviderConfiguration {
        get {
            LLMProviderConfiguration(
                baseURL: defaults.string(forKey: Keys.llmBaseURL) ?? "https://api.openai.com/v1",
                model: defaults.string(forKey: Keys.llmModel) ?? "gpt-4o-mini",
                apiKey: keychain.string(for: "translation.llm.apiKey") ?? ""
            )
        }
        set {
            defaults.set(newValue.baseURL, forKey: Keys.llmBaseURL)
            defaults.set(newValue.model, forKey: Keys.llmModel)
            keychain.set(newValue.apiKey, for: "translation.llm.apiKey")
        }
    }

    private init() {
        migrateLegacySecretsIfNeeded()
    }

    private func migrateLegacySecretsIfNeeded() {
        if let legacyKey = defaults.string(forKey: "llmAPIKey"), !legacyKey.isEmpty,
           (keychain.string(for: "translation.llm.apiKey") ?? "").isEmpty {
            keychain.set(legacyKey, for: "translation.llm.apiKey")
            defaults.removeObject(forKey: "llmAPIKey")
        }

        if defaults.object(forKey: Keys.llmBaseURL) == nil,
           let legacyBaseURL = defaults.string(forKey: "llmAPIBaseURL"),
           !legacyBaseURL.isEmpty {
            defaults.set(legacyBaseURL, forKey: Keys.llmBaseURL)
            defaults.removeObject(forKey: "llmAPIBaseURL")
        }

        if defaults.object(forKey: Keys.llmModel) == nil,
           let legacyModel = defaults.string(forKey: "llmModel"),
           !legacyModel.isEmpty {
            defaults.set(legacyModel, forKey: Keys.llmModel)
            defaults.removeObject(forKey: "llmModel")
        }

        defaults.removeObject(forKey: "llmEnabled")
    }
}
