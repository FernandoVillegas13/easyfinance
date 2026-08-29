import Foundation

/// Immutable, Sendable value type — no actor isolation needed.
nonisolated struct AppConfiguration: Sendable {
    static let fallbackBaseURL = URL(
        string: "https://licm3mgb2sak63hkui7jldwkeu0laxjz.lambda-url.us-east-1.on.aws/"
    )!

    let baseURL: URL
    let apiKey: String
    let userID: String
    let apiVersion: String

    static func live(bundle: Bundle = .main) -> AppConfiguration {
        let baseURL = bundle.configuredURL(forKey: "EasyFinanceAPIBaseURL") ?? fallbackBaseURL
        let apiKey = bundle.configuredString(forKey: "EasyFinanceAPIKey") ?? ""
        let userID = bundle.configuredString(forKey: "EasyFinanceUserID") ?? "easyfinance-watch"

        return AppConfiguration(
            baseURL: baseURL,
            apiKey: apiKey,
            userID: userID,
            apiVersion: "v1"
        )
    }

    func endpointURL(for endpoint: String) -> URL {
        baseURL
            .appendingPathComponent("api")
            .appendingPathComponent(apiVersion)
            .appendingPathComponent(endpoint)
    }

    func validate() throws {
        guard baseURL.scheme == "https" else {
            throw AppConfigurationError.insecureBaseURL
        }
        guard !apiKey.isEmpty else {
            throw AppConfigurationError.missingAPIKey
        }
        guard !userID.isEmpty else {
            throw AppConfigurationError.missingUserID
        }
    }
}

enum AppConfigurationError: LocalizedError, Sendable {
    case insecureBaseURL
    case missingAPIKey
    case missingUserID

    var errorDescription: String? {
        switch self {
        case .insecureBaseURL:
            "La URL del agente debe usar HTTPS."
        case .missingAPIKey:
            "Falta configurar EASYFINANCE_API_KEY."
        case .missingUserID:
            "Falta configurar EASYFINANCE_USER_ID."
        }
    }
}

private nonisolated extension Bundle {
    func configuredString(forKey key: String) -> String? {
        guard let rawValue = object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$(") else {
            return nil
        }
        return value
    }

    func configuredURL(forKey key: String) -> URL? {
        guard let value = configuredString(forKey: key) else {
            return nil
        }
        return URL(string: value)
    }
}
