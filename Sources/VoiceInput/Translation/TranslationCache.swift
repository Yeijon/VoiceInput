import Foundation

private struct CachedTranslationEntry: Codable {
    let key: String
    let text: String
    let providerID: String
    let model: String?
    let updatedAt: Date
}

private struct TranslationHistoryEntry: Codable {
    let createdAt: Date
    let sourceText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let providerID: String
    let model: String?
}

final class TranslationCache {
    static let shared = TranslationCache()

    private let cacheURL: URL
    private let historyURL: URL
    private let queue = DispatchQueue(label: "com.yetone.VoiceInput.translation-cache")
    private var entries: [String: CachedTranslationEntry] = [:]

    init(fileManager: FileManager = .default) {
        let base = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/VoiceInput", isDirectory: true)
        try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        cacheURL = base.appendingPathComponent("translation-cache.json")
        historyURL = base.appendingPathComponent("translation-history.jsonl")
        loadCache()
    }

    func cachedResult(forKey key: String) -> TranslationResult? {
        queue.sync {
            guard let entry = entries[key] else { return nil }
            return TranslationResult(text: entry.text, providerID: entry.providerID, model: entry.model, cached: true)
        }
    }

    func save(result: TranslationResult, forKey key: String, request: TranslationRequest) {
        queue.async {
            self.entries[key] = CachedTranslationEntry(
                key: key,
                text: result.text,
                providerID: result.providerID,
                model: result.model,
                updatedAt: Date()
            )
            self.persistCache()
            self.appendHistory(
                TranslationHistoryEntry(
                    createdAt: Date(),
                    sourceText: request.text,
                    translatedText: result.text,
                    sourceLanguage: request.sourceLanguage,
                    targetLanguage: request.targetLanguage,
                    providerID: result.providerID,
                    model: result.model
                )
            )
        }
    }

    func historyFileURL() -> URL {
        historyURL
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let decoded = try? JSONDecoder().decode([String: CachedTranslationEntry].self, from: data) else {
            return
        }
        entries = decoded
    }

    private func persistCache() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    private func appendHistory(_ entry: TranslationHistoryEntry) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entry) else { return }
        var line = data
        line.append(0x0A)
        if let handle = try? FileHandle(forWritingTo: historyURL) {
            handle.seekToEndOfFile()
            try? handle.write(contentsOf: line)
            try? handle.close()
        } else {
            try? line.write(to: historyURL, options: .atomic)
        }
    }
}
