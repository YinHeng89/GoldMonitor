import Foundation

protocol HTTPFetching: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

enum HTTPClientError: LocalizedError {
    case badStatus(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "HTTP \(code)"
        case .invalidResponse: return "无效的网络响应"
        }
    }
}

final class URLSessionHTTPClient: HTTPFetching, @unchecked Sendable {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 20
        if let proxy = Self.environmentProxy() {
            config.connectionProxyDictionary = proxy
        }
        self.session = URLSession(configuration: config)
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HTTPClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw HTTPClientError.badStatus(http.statusCode) }
        return (data, http)
    }

    /// 尊重命令行/IDE 环境中约定的 HTTP(S)_PROXY，普通桌面环境未设置时自动忽略。
    static func environmentProxy() -> [String: Any]? {
        let env = ProcessInfo.processInfo.environment
        guard let raw = env["HTTPS_PROXY"] ?? env["https_proxy"] ?? env["HTTP_PROXY"] ?? env["http_proxy"],
              let url = URL(string: raw),
              let host = url.host,
              let port = url.port
        else { return nil }
        return [
            "HTTPProxy": host,
            "HTTPPort": port,
            "HTTPSProxy": host,
            "HTTPSPort": port
        ]
    }
}
