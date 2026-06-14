import Foundation

struct LLMMessage {
    let role: String
    let content: String
}

protocol LLMClient {
    func complete(
        _ messages: [LLMMessage],
        model: String,
        temperature: Double,
        completion: @escaping (Result<String, Error>) -> Void
    )
    func cancel()
}

final class OpenAICompatibleClient: LLMClient {
    private let baseURL: String
    private let apiKey: String
    private var currentTask: URLSessionDataTask?

    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    func complete(
        _ messages: [LLMMessage],
        model: String,
        temperature: Double,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let normalizedBaseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        guard let url = URL(string: "\(normalizedBaseURL)/chat/completions") else {
            DispatchQueue.main.async { completion(.failure(ClientError.invalidURL)) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        let payloadMessages = messages.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "model": model,
            "messages": payloadMessages,
            "temperature": temperature,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        logToFile("LLM request: \(url.absoluteString) model=\(model)")

        currentTask = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                logToFile("LLM network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data else {
                DispatchQueue.main.async { completion(.failure(ClientError.invalidResponse)) }
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                logToFile("LLM response: \(raw)")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                DispatchQueue.main.async { completion(.failure(ClientError.invalidResponse)) }
                return
            }

            DispatchQueue.main.async {
                completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        currentTask?.resume()
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    enum ClientError: LocalizedError {
        case invalidURL
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API base URL"
            case .invalidResponse:
                return "Invalid response from API"
            }
        }
    }
}
