import Combine
import SwiftUI
import Translation

@MainActor
class TranslationService: ObservableObject {
    static let shared = TranslationService()

    @Published var configuration: TranslationSession.Configuration?
    @Published private(set) var sessionId: Int = 0 // .translationTask()を再生成するため

    struct Request {
        let text: String
        let continuation: CheckedContinuation<String, Error>
    }

    private var requestContinuation: AsyncStream<Request>.Continuation?
    private var requestStream: AsyncStream<Request>?

    private var source: Locale.Language
    private var target: Locale.Language

    private init() {
        let sourceID = UserDefaults.standard.string(forKey: "sourceLanguage") ?? "en-US"
        let targetID = UserDefaults.standard.string(forKey: "targetLanguage") ?? "ja-JP"
        self.source = Locale.Language(identifier: sourceID)
        self.target = Locale.Language(identifier: targetID)
        
        let (stream, continuation) = AsyncStream<Request>.makeStream()
        self.requestStream = stream
        self.requestContinuation = continuation
        // Initialization without configuration to allow delayed setup or default
        self.configuration = TranslationSession.Configuration(source: source, target: target)
    }


    func translate(_ text: String) async throws -> String {
        if configuration == nil {
             configuration = TranslationSession.Configuration(source: source, target: target)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = Request(text: text, continuation: continuation)
            self.requestContinuation?.yield(request)
        }
    }

    func reset() {
        self.requestContinuation?.finish()
        self.requestStream?.map { stream in
            Task {
                for await request in stream {
                    request.continuation.resume(throwing: CancellationError())
                }
            }
        }

        requestContinuation = nil
        requestStream = nil
        configuration = nil

        let (stream, continuation) = AsyncStream<Request>.makeStream()
        self.requestStream = stream
        self.requestContinuation = continuation

        let sourceID = UserDefaults.standard.string(forKey: "sourceLanguage") ?? "en-US"
        let targetID = UserDefaults.standard.string(forKey: "targetLanguage") ?? "ja-JP"
        self.source = Locale.Language(identifier: sourceID)
        self.target = Locale.Language(identifier: targetID)

        sessionId += 1

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            configuration = TranslationSession.Configuration(source: source, target: target)
        }
    }

    func handleSession(_ session: TranslationSession) async {
        guard let stream = requestStream else { return }

        for await request in stream {
            do {
                let response = try await session.translate(request.text)
                request.continuation.resume(returning: response.targetText)
            } catch {
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
            .id(service.sessionId)
    }
}
