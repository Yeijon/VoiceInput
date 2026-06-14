import Foundation

struct TranslationRequest {
    let text: String
    let sourceLanguage: String
    let targetLanguage: String
}

struct TranslationResult {
    let text: String
    let providerID: String
    let model: String?
    let cached: Bool
}

protocol TranslationProvider {
    var id: String { get }
    var displayName: String { get }
    var isConfigured: Bool { get }
    func translate(_ request: TranslationRequest, completion: @escaping (Result<TranslationResult, Error>) -> Void)
    func cancel()
}
