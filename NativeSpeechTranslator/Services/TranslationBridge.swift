import SwiftUI
import Translation
import Combine

@available(macOS 15.0, *)
@MainActor
class TranslationBridge: ObservableObject {
    static let shared = TranslationBridge()
    
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
        // Ensure configuration is set to start the session if not already
        if configuration == nil {
            configuration = TranslationSession.Configuration(target: Locale.Language(identifier: "ja"))
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = Request(text: text, continuation: continuation)
            self.requestContinuation?.yield(request)
        }
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
                // If the session is invalid, we might want to break? 
                // But for transient errors, we continue.
            }
        }
    }
}

enum TranslationError: Error {
    case busy
    case unknown
}

@available(macOS 15.0, *)
struct TranslationHostView: View {
    @ObservedObject var bridge = TranslationBridge.shared
    
    var body: some View {
        Color.clear
            .translationTask(bridge.configuration) { session in
                await bridge.handleSession(session)
            }
    }
}
