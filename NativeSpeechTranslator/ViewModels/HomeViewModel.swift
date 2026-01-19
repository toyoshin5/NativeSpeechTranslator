import AVFoundation
import Combine
import Dependencies
import Foundation

@MainActor
class HomeViewModel: ObservableObject {

    struct TranscriptItem: Identifiable {
        let id = UUID()
        var original: String
        var translation: String?
        var isFinal: Bool = false
    }

    @Published var transcripts: [TranscriptItem] = []

    @Published var isRecording: Bool = false

    @Published var inputDevices: [AudioDevice] = []

    @Published var audioLevel: Float = 0.0

    @Published var selectedDeviceID: String? = nil {
        didSet {
            guard oldValue != selectedDeviceID else { return }
            applyDeviceChange()
        }
    }
    
    @Published var isTranslationModelInstalled: Bool = false

    private var sourceLanguageIdentifier: String {
        UserDefaults.standard.string(forKey: "sourceLanguage") ?? "en-US"
    }
    
    private var targetLanguageIdentifier: String {
        UserDefaults.standard.string(forKey: "targetLanguage") ?? "ja-JP"
    }

    private var sourceLocale: Locale {
        Locale(identifier: sourceLanguageIdentifier)
    }

    private var targetLocale: Locale {
        Locale(identifier: targetLanguageIdentifier)
    }

    @Dependency(\.audioCaptureClient) var audioCaptureClient
    @Dependency(\.speechRecognitionClient) var speechRecognitionClient
    @Dependency(\.translationClient) var translationClient

    private var levelMonitoringTask: Task<Void, Never>?

    init() {
        self.inputDevices = audioCaptureClient.getAvailableDevices()
        if let defaultDevice = inputDevices.first {
            self.selectedDeviceID = defaultDevice.id
        }
        startStandaloneLevelMonitoring()
        Task { await checkTranslationModelStatus() }
    }

    private func applyDeviceChange() {
        Task {
            await applyDeviceChangeTask()
        }
    }
    
    func applyDeviceChangeTask() async {
        await audioCaptureClient.setInputDevice(selectedDeviceID)

        if isRecording {
            restartRecording()
        } else {
            restartStandaloneLevelMonitoring()
        }
    }


    private func startStandaloneLevelMonitoring() {
        levelMonitoringTask?.cancel()
        levelMonitoringTask = Task {
            let levelStream = await audioCaptureClient.startLevelMonitoringOnly()
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
            await audioCaptureClient.stopLevelMonitoringOnly()
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
        Task {
            await startRecordingTask()
        }
    }

    func startRecordingTask() async {
        guard !isRecording else { return }
        isRecording = true
        
        stopStandaloneLevelMonitoring()

        do {
            let audioStream = try await audioCaptureClient.startStream()

            let transcriptionStream = await speechRecognitionClient.startRecognition(
                audioStream,
                sourceLocale
            )

            let levelStream = await audioCaptureClient.startLevelMonitoring()

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

    func stopRecording() {
        Task {
            await stopRecordingTask()
        }
    }
    
    func stopRecordingTask() async {
        guard isRecording else { return }
        await audioCaptureClient.stopStream()
        await speechRecognitionClient.stopRecognition()
        isRecording = false
        startStandaloneLevelMonitoring()
    }

    func clearTranscripts() {
        Task {
            await clearTranscriptsTask()
        }
    }

    func clearTranscriptsTask() async {
        transcripts.removeAll()
        await translationClient.reset()
    }

    func handleSourceLanguageChange() {
        Task {
            await handleSourceLanguageChangeTask()
        }
    }
    
    func handleSourceLanguageChangeTask() async {
        await checkTranslationModelStatus()
        if isRecording {
            await restartRecordingTask()
        }
    }
    
    func handleTargetLanguageChange() {
        Task {
            await handleTargetLanguageChangeTask()
        }
    }

    func handleTargetLanguageChangeTask() async {
        await checkTranslationModelStatus()
    }
    
    func checkTranslationModelStatus() async {
        isTranslationModelInstalled = await translationClient.isTranslationModelInstalled(sourceLocale.language, targetLocale.language)
        
        if !isTranslationModelInstalled && isRecording {
            stopRecording()
        }
    }
    
    func getDisplayLanguageName(for identifier: String) -> String {
        if let lang = SupportedLanguage(rawValue: identifier){
            return lang.displayName
        }
        return identifier
    }
        

    private func restartRecording() {
        Task {
            await restartRecordingTask()
        }
    }
    
    // Made internal for testing if needed, or simply used by other tasks
    func restartRecordingTask() async {
        await audioCaptureClient.stopStream()
        await speechRecognitionClient.stopRecognition()

        try? await Task.sleep(nanoseconds: 300_000_000)

        do {
            let audioStream = try await audioCaptureClient.startStream()

            let transcriptionStream = await speechRecognitionClient.startRecognition(
                audioStream,
                sourceLocale
            )

            let levelStream = await audioCaptureClient.startLevelMonitoring()

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

    private func handleRecognitionResult(_ result: TranscriptionResult) {

        var targetIndex: Int?

        if let lastIndex = transcripts.indices.last, !transcripts[lastIndex].isFinal {
            targetIndex = lastIndex
            transcripts[lastIndex].original = result.text

            if result.isFinal {
                transcripts[lastIndex].isFinal = true
            }
        } else {
            let newItem = TranscriptItem(
                original: result.text,
                translation: nil,
                isFinal: result.isFinal
            )
            transcripts.append(newItem)
            targetIndex = transcripts.indices.last
        }

        if let index = targetIndex {
            translate(text: result.text, at: index, isFinal: result.isFinal)
        }
    }

    private func translate(text: String, at index: Int, isFinal: Bool) {
        Task {
            let translation = await translationClient.translate(text)

            if index < transcripts.count {
                transcripts[index].translation = translation

                if isFinal {
                    let llmEnabled = UserDefaults.standard.bool(forKey: "llmTranslationEnabled")
                    if llmEnabled {
                        let sourceName = Locale(identifier: "en").localizedString(forIdentifier: sourceLanguageIdentifier) ?? sourceLanguageIdentifier
                        let targetName = Locale(identifier: "en").localizedString(forIdentifier: targetLanguageIdentifier) ?? targetLanguageIdentifier
                        
                        let refined = await translationClient.translateWithLLM(text, translation, sourceName, targetName)
                        if index < transcripts.count {
                            transcripts[index].translation = refined
                        }
                    }
                }
            }
        }
    }
}
