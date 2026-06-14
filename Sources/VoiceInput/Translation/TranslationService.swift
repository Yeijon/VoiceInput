import Foundation

final class TranslationService {
    static let shared = TranslationService()

    private let settings = AppSettings.shared
    private let cache = TranslationCache.shared
    private lazy var llmProvider = LLMTranslationProvider(settings: settings)

    func translate(_ rawText: String, sourceLocaleCode: String, completion: @escaping (Result<TranslationResult, Error>) -> Void) {
        let normalizedText = normalize(rawText)
        let sourceLanguage = TranslationLanguages.appCode(for: sourceLocaleCode)
        let targetLanguage = settings.targetLocaleCode
        let request = TranslationRequest(text: normalizedText, sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)

        let provider = llmProvider
        guard provider.isConfigured else {
            DispatchQueue.main.async {
                completion(.failure(ServiceError.providerNotConfigured(provider.displayName)))
            }
            return
        }

        let cacheKey = makeCacheKey(request: request, providerID: provider.id, model: settings.llmConfiguration.model)
        if let cached = cache.cachedResult(forKey: cacheKey) {
            let cleanedCached = sanitizeIfNeeded(cached)
            DispatchQueue.main.async { completion(.success(cleanedCached)) }
            return
        }

        provider.translate(request) { [weak self] result in
            switch result {
            case .success(let translated):
                let cleaned = self?.sanitizeIfNeeded(translated) ?? translated
                self?.cache.save(result: cleaned, forKey: cacheKey, request: request)
                completion(.success(cleaned))
            case .failure:
                completion(result)
            }
        }
    }

    func cancel() {
        llmProvider.cancel()
    }

    func historyFileURL() -> URL {
        cache.historyFileURL()
    }

    func testActiveProvider(sampleText: String, completion: @escaping (Result<String, Error>) -> Void) {
        let sourceLanguage = settings.selectedLocaleCode
        translate(sampleText, sourceLocaleCode: sourceLanguage) { result in
            switch result {
            case .success(let translation):
                completion(.success(translation.text))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func makeCacheKey(request: TranslationRequest, providerID: String, model: String?) -> String {
        let parts = [request.text, request.sourceLanguage, request.targetLanguage, providerID, model ?? ""]
        return parts.joined(separator: "\u{001F}")
    }

    private func sanitizeIfNeeded(_ result: TranslationResult) -> TranslationResult {
        guard result.providerID == "llm" else { return result }
        let cleaned = LLMTranslationProvider.cleanTranslationOutput(result.text)
        guard cleaned != result.text else { return result }
        return TranslationResult(
            text: cleaned,
            providerID: result.providerID,
            model: result.model,
            cached: result.cached
        )
    }

    enum ServiceError: LocalizedError {
        case providerNotConfigured(String)

        var errorDescription: String? {
            switch self {
            case .providerNotConfigured(let providerName):
                return "\(providerName) is not configured"
            }
        }
    }
}
