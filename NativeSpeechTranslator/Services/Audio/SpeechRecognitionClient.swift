import Dependencies
import AVFoundation
import Foundation

struct SpeechRecognitionClient {
    var startRecognition: @Sendable (AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>, Locale) async -> AsyncStream<TranscriptionResult>
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
            await SpeechRecognitionService.shared.startRecognition(audioStream: audioStream, locale: locale)
        },
        stopRecognition: {
            await SpeechRecognitionService.shared.stopRecognition()
        }
    )

    static let testValue = SpeechRecognitionClient(
        startRecognition: { _, _ in
            AsyncStream { continuation in
                continuation.yield(TranscriptionResult(text: "Test Transcription", isFinal: true))
                continuation.finish()
            }
        },
        stopRecognition: {}
    )

    static let previewValue = SpeechRecognitionClient(
        startRecognition: { _, _ in
            AsyncStream { continuation in
                continuation.yield(TranscriptionResult(text: "Preview Transcription", isFinal: false))
                continuation.finish()
            }
        },
        stopRecognition: {}
    )
}
