import AVFoundation
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct SpeechRecognitionClient: Sendable {
    @DependencyEndpoint
    var startRecognition:
        @Sendable (_ audioStream: AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>, _ locale: Locale)
            async -> AsyncStream<TranscriptionResult> = { _, _ in AsyncStream { $0.finish() } }
    @DependencyEndpoint
    var stopRecognition: @Sendable () async -> Void
}

extension DependencyValues {
    var speechRecognitionClient: SpeechRecognitionClient {
        get { self[SpeechRecognitionClient.self] }
        set { self[SpeechRecognitionClient.self] = newValue }
    }
}

extension SpeechRecognitionClient: DependencyKey {
    static let liveValue = SpeechRecognitionClient(
        startRecognition: { audioStream, locale in
            await SpeechRecognitionService.shared.startRecognition(
                audioStream: audioStream, locale: locale)
        },
        stopRecognition: {
            await SpeechRecognitionService.shared.stopRecognition()
        }
    )
}
