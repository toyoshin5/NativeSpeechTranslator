import AVFoundation
import Combine
import Foundation

@MainActor
@available(macOS 26, *)
class AppViewModel: ObservableObject {

    struct TranscriptItem: Identifiable {
        let id = UUID()
        var original: String
        var translation: String?
        var isTranslating: Bool = false
        var isFinal: Bool = false
    }

    @Published var transcripts: [TranscriptItem] = []

    @Published var isRecording: Bool = false

    @Published var inputDevices: [AVCaptureDevice] = []

    @Published var audioLevel: Float = 0.0

    @Published var selectedDeviceID: String? = nil {
        didSet {
            guard oldValue != selectedDeviceID else { return }
            applyDeviceChange()
        }
    }

    private let audioService = AudioCaptureService.shared
    private let recognitionService = SpeechRecognitionService.shared
    private let translationService = TranslationService.shared

    private var levelMonitoringTask: Task<Void, Never>?

    init() {
        self.inputDevices = audioService.getAvailableDevices()
        if let defaultDevice = inputDevices.first {
            self.selectedDeviceID = defaultDevice.uniqueID
        }
        startStandaloneLevelMonitoring()
    }

    private func applyDeviceChange() {
        Task {
            await audioService.setInputDevice(deviceID: selectedDeviceID)

            if isRecording {
                restartRecording()
            } else {
                restartStandaloneLevelMonitoring()
            }
        }
    }

    private func startStandaloneLevelMonitoring() {
        levelMonitoringTask?.cancel()
        levelMonitoringTask = Task {
            let levelStream = await audioService.startLevelMonitoringOnly()
            for await level in levelStream {
                guard !Task.isCancelled else { break }
                self.audioLevel = level
            }
        }
    }

    private func stopStandaloneLevelMonitoring() {
        levelMonitoringTask?.cancel()
        levelMonitoringTask = nil
        Task {
            await audioService.stopLevelMonitoringOnly()
        }
    }

    private func restartStandaloneLevelMonitoring() {
        stopStandaloneLevelMonitoring()
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            startStandaloneLevelMonitoring()
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        isRecording = true

        stopStandaloneLevelMonitoring()

        Task {
            do {
                let audioStream = try await audioService.startStream()

                let transcriptionStream = await recognitionService.startRecognition(
                    audioStream: audioStream)

                let levelStream = await audioService.startLevelMonitoring()

                Task {
                    for await result in transcriptionStream {
                        await handleRecognitionResult(result)
                    }
                }

                Task {
                    for await level in levelStream {
                        self.audioLevel = level
                    }
                }

            } catch {
                print("Error starting recording: \(error)")
                isRecording = false
                startStandaloneLevelMonitoring()
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        Task {
            await audioService.stopStream()
            await recognitionService.stopRecognition()
            isRecording = false
            startStandaloneLevelMonitoring()
        }
    }

    private func restartRecording() {
        Task {
            await audioService.stopStream()
            await recognitionService.stopRecognition()

            try? await Task.sleep(nanoseconds: 300_000_000)

            do {
                let audioStream = try await audioService.startStream()

                let transcriptionStream = await recognitionService.startRecognition(
                    audioStream: audioStream)

                let levelStream = await audioService.startLevelMonitoring()

                Task {
                    for await result in transcriptionStream {
                        await handleRecognitionResult(result)
                    }
                }

                Task {
                    for await level in levelStream {
                        self.audioLevel = level
                    }
                }

            } catch {
                print("Error restarting recording: \(error)")
                isRecording = false
                startStandaloneLevelMonitoring()
            }
        }
    }

    private func handleRecognitionResult(_ result: TranscriptionResult) {
        if result.isFinal {
            if let lastIndex = transcripts.indices.last, !transcripts[lastIndex].isFinal {
                transcripts[lastIndex].original = result.text
                transcripts[lastIndex].isFinal = true
                transcripts[lastIndex].isTranslating = true
                translate(text: result.text, at: lastIndex)
            } else {
                let item = TranscriptItem(
                    original: result.text,
                    translation: nil,
                    isTranslating: true,
                    isFinal: true
                )
                transcripts.append(item)
                translate(text: result.text, at: transcripts.count - 1)
            }
        } else {
            if let lastIndex = transcripts.indices.last, !transcripts[lastIndex].isFinal {
                transcripts[lastIndex].original = result.text
            } else {
                let item = TranscriptItem(
                    original: result.text,
                    translation: nil,
                    isTranslating: false,
                    isFinal: false
                )
                transcripts.append(item)
            }
        }
    }

    private func translate(text: String, at index: Int) {
        Task {
            let translation = await translationService.translate(text)

            if index < transcripts.count {
                transcripts[index].translation = translation
                transcripts[index].isTranslating = false
            }
        }
    }
}
