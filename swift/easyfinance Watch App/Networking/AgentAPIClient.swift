import Foundation

actor AgentAPIClient {
    private let configuration: AppConfiguration
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        configuration: AppConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func logExpense(_ query: String) async throws -> String {
        let body = AgentRequest(userID: configuration.userID, query: query)
        let response: AgentResponse = try await post(endpoint: "log", body: body)
        return response.response
    }

    func chat(_ query: String) async throws -> String {
        let body = AgentRequest(userID: configuration.userID, query: query)
        let response: AgentResponse = try await post(endpoint: "chat", body: body)
        return response.response
    }

    func fetchSpendings(limit: Int = 100) async throws -> [Spending] {
        let body = SpendingsRequest(userID: configuration.userID, limit: limit)
        let response: SpendingsResponse = try await post(endpoint: "spendings", body: body)
        return response.spendings
    }

    private func post<Body: Encodable & Sendable, Response: Decodable>(
        endpoint: String,
        body: Body
    ) async throws -> Response {
        try configuration.validate()

        var urlRequest = URLRequest(url: configuration.endpointURL(for: endpoint))
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 90
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(configuration.apiKey, forHTTPHeaderField: "X-Api-Key")
        urlRequest.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AgentAPIError.invalidResponse
            }

            guard 200 ..< 300 ~= httpResponse.statusCode else {
                let detail = try? decoder.decode(APIErrorBody.self, from: data).detail
                throw AgentAPIError.http(statusCode: httpResponse.statusCode, detail: detail)
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw AgentAPIError.invalidPayload
            }
        } catch let error as AgentAPIError {
            throw error
        } catch let error as AppConfigurationError {
            throw error
        } catch {
            throw AgentAPIError.transport(error.localizedDescription)
        }
    }
}

private nonisolated struct APIErrorBody: Decodable, Sendable {
    let detail: String?
}

enum AgentAPIError: LocalizedError, Sendable {
    case invalidResponse
    case invalidPayload
    case http(statusCode: Int, detail: String?)
    case transport(String)

    /// True only for failures caused by lack of connectivity or a dropped
    /// connection — the same request would likely succeed once online again.
    /// HTTP and payload errors are not retryable: sending the same request
    /// again would fail the same way.
    var isRetryable: Bool {
        switch self {
        case .transport:
            true
        case .invalidResponse, .invalidPayload, .http:
            false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "El agente devolvió una respuesta inválida."
        case .invalidPayload:
            "No se pudo interpretar la respuesta del agente."
        case let .http(statusCode, detail):
            if statusCode == 401 {
                "La API key no es válida."
            } else if let detail, !detail.isEmpty {
                "Error \(statusCode): \(detail)"
            } else {
                "El agente respondió con error \(statusCode)."
            }
        case let .transport(message):
            "No se pudo conectar: \(message)"
        }
    }
}
