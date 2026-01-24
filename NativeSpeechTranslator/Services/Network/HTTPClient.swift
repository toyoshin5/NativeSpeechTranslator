import Dependencies
import Foundation

public protocol HTTPClient {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {}

private enum HTTPClientKey: DependencyKey {
    static let liveValue: any HTTPClient = URLSession.shared
    static let testValue: any HTTPClient = MockHTTPClient()
}

extension DependencyValues {
    public var httpClient: any HTTPClient {
        get { self[HTTPClientKey.self] }
        set { self[HTTPClientKey.self] = newValue }
    }
}

public struct MockHTTPClient: HTTPClient {
    public var callback: (URLRequest) async throws -> (Data, URLResponse)

    public init(callback: @escaping (URLRequest) async throws -> (Data, URLResponse) = { _ in (Data(), URLResponse()) }) {
        self.callback = callback
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await callback(request)
    }
}
