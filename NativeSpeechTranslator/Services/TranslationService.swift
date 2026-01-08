import Combine
import SwiftUI
import Translation

@MainActor
class TranslationService: ObservableObject {
    static let shared = TranslationService()

    @Published var configuration: TranslationSession.Configuration?

    struct Request {
        let text: String
        let continuation: CheckedContinuation<String, Error>
    }

    private var requestContinuation: AsyncStream<Request>.Continuation?
    private var requestStream: AsyncStream<Request>?

    private init() {
        let (stream, continuation) = AsyncStream<Request>.makeStream()
        self.requestStream = stream
        self.requestContinuation = continuation
    }

    func translate(_ text: String) async throws -> String {
        let source = Locale.Language(identifier: "en")
        let target = Locale.Language(identifier: "ja")

        if configuration == nil {
            configuration = TranslationSession.Configuration(source: source, target: target)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = Request(text: text, continuation: continuation)
            self.requestContinuation?.yield(request)
        }
    }

    func reset() {

        requestContinuation?.finish()
        requestContinuation = nil
        requestStream = nil

        configuration = nil

        let (stream, continuation) = AsyncStream<Request>.makeStream()
        self.requestStream = stream
        self.requestContinuation = continuation
    }

    func handleSession(_ session: TranslationSession) async {
        guard let stream = requestStream else { return }

        // Process requests one by one using the same session
        for await request in stream {
            do {
                let response = try await session.translate(request.text)
                request.continuation.resume(returning: response.targetText)
            } catch {
                print("Translation session error: \(error)")
                request.continuation.resume(throwing: error)
            }
        }
    }
}

struct TranslationHostView: View {
    @ObservedObject var service = TranslationService.shared

    var body: some View {
        Color.clear
            .translationTask(service.configuration) { session in
                await service.handleSession(session)
            }
    }
}
