import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct HTTPClient: Sendable {
    @DependencyEndpoint
    public var data: @Sendable (_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension HTTPClient: DependencyKey {
    public static let liveValue = HTTPClient(
        data: { request in
            try await URLSession.shared.data(for: request)
        }
    )
}

extension DependencyValues {
    public var httpClient: HTTPClient {
        get { self[HTTPClient.self] }
        set { self[HTTPClient.self] = newValue }
    }
}

