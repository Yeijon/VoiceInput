import Foundation

struct TranslationLanguage {
    let title: String
    let appValue: String
    let llmValue: String
    let deepLValue: String
    let googleValue: String
    let youdaoValue: String
}

enum TranslationLanguages {
    static let supported: [TranslationLanguage] = [
        TranslationLanguage(title: "English", appValue: "en", llmValue: "English", deepLValue: "EN", googleValue: "en", youdaoValue: "en"),
        TranslationLanguage(title: "中文 (简体)", appValue: "zh-CN", llmValue: "Simplified Chinese", deepLValue: "ZH-HANS", googleValue: "zh-CN", youdaoValue: "zh-CHS"),
        TranslationLanguage(title: "中文 (繁體)", appValue: "zh-TW", llmValue: "Traditional Chinese", deepLValue: "ZH-HANT", googleValue: "zh-TW", youdaoValue: "zh-CHT"),
        TranslationLanguage(title: "日本語", appValue: "ja", llmValue: "Japanese", deepLValue: "JA", googleValue: "ja", youdaoValue: "ja"),
        TranslationLanguage(title: "한국어", appValue: "ko", llmValue: "Korean", deepLValue: "KO", googleValue: "ko", youdaoValue: "ko"),
        TranslationLanguage(title: "Deutsch", appValue: "de", llmValue: "German", deepLValue: "DE", googleValue: "de", youdaoValue: "de"),
        TranslationLanguage(title: "Français", appValue: "fr", llmValue: "French", deepLValue: "FR", googleValue: "fr", youdaoValue: "fr"),
    ]

    static func title(for code: String) -> String {
        supported.first(where: { $0.appValue == code })?.title ?? code
    }

    static func deepLCode(for localeCode: String) -> String {
        if let match = supported.first(where: { $0.appValue == localeCode }) {
            return match.deepLValue
        }
        return localeCode.split(separator: "-").first.map { String($0).uppercased() } ?? localeCode.uppercased()
    }

    static func llmName(for localeCode: String) -> String {
        if let match = supported.first(where: { $0.appValue == localeCode }) {
            return match.llmValue
        }
        return localeCode
    }

    static func appCode(for sourceLocaleCode: String) -> String {
        if supported.contains(where: { $0.appValue == sourceLocaleCode }) {
            return sourceLocaleCode
        }
        let languageCode = Locale(identifier: sourceLocaleCode).language.languageCode?.identifier
        return languageCode ?? sourceLocaleCode
    }

    static func googleCode(for localeCode: String) -> String {
        if let match = supported.first(where: { $0.appValue == localeCode }) {
            return match.googleValue
        }
        return appCode(for: localeCode)
    }

    static func youdaoCode(for localeCode: String) -> String {
        if let match = supported.first(where: { $0.appValue == localeCode }) {
            return match.youdaoValue
        }
        return appCode(for: localeCode)
    }
}
