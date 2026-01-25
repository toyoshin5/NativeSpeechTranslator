import Dependencies
import Foundation
import Testing

@testable import NativeSpeechTranslator

private actor CallLogger {
    var log: [String] = []
    func append(_ value: String) { log.append(value) }
}

@Suite("HomeViewModel Tests")
@MainActor
struct HomeViewModelTests {

    @Test("初期状態の確認")
    func testInitialState() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        // Then
        #expect(!model.isRecording)
        #expect(model.transcripts.isEmpty)
        #expect(model.inputDevices.isEmpty)
    }

    @Test("録音開始と停止が正しく機能する")
    func testRecordingStartStop() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startStream = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopStream = {}
            $0.audioCaptureClient.startLevelMonitoring = { AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.startRecognition = { _, _ in AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.stopRecognition = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        // When
        await model.startRecordingTask()

        // Then
        #expect(model.isRecording)

        // When
        await model.stopRecordingTask()

        // Then
        #expect(!model.isRecording)
    }

    @Test("音声認識結果が正しく反映される")
    func testSpeechRecognitionResultReflected() async {
        // Given
        let transcriptionText = "こんにちは"
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startStream = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopStream = {}
            $0.audioCaptureClient.startLevelMonitoring = { AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.startRecognition = { _, _ in
                AsyncStream { continuation in
                    continuation.yield(TranscriptionResult(text: transcriptionText, isFinal: true))
                    continuation.finish()
                }
            }
            $0.speechRecognitionClient.stopRecognition = {}
            $0.translationClient.translate = { _ in "Hello" }
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        // When
        await model.startRecordingTask()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        #expect(model.transcripts.count == 1)
        #expect(model.transcripts.first?.original == transcriptionText)
        #expect(model.transcripts.first?.translation == "Hello")

        await model.stopRecordingTask()
    }

    @Test("エラーハンドリング（録音開始失敗）")
    func testRecordingStartFailureHandling() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startStream = { throw NSError(domain: "test", code: -1) }
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        // When
        await model.startRecordingTask()

        // Then
        // Expect isRecording to be false (it sets true then catches error and sets false)
        #expect(!model.isRecording)
    }
    @Test("トランスクリプトのクリア")
    func testClearTranscripts() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
            $0.translationClient.reset = {}
        } operation: {
            HomeViewModel()
        }

        let transcriptionText = "こんにちは"
        model.transcripts.append(HomeViewModel.TranscriptItem(original: transcriptionText))

        // When
        await model.clearTranscriptsTask()

        // Then
        #expect(model.transcripts.isEmpty)
    }

    @Test("ソース言語変更時の処理（録音中）")
    func testSourceLanguageChangeWhileRecording() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startStream = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopStream = {}
            $0.audioCaptureClient.startLevelMonitoring = { AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.startRecognition = { _, _ in AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.stopRecognition = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        await model.startRecordingTask()
        #expect(model.isRecording)

        // When
        await model.handleSourceLanguageChangeTask()

        // Then
        // Restart is now awaited inside handleSourceLanguageChangeTask -> restartRecordingTask
        #expect(model.isRecording)
    }

    @Test("ターゲット言語変更時の処理")
    func testTargetLanguageChange() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        // When
        await model.handleTargetLanguageChangeTask()

        // Then
        #expect(model.isTranslationModelInstalled)
    }

    @Test("翻訳モデル未インストール時の録音停止")
    func testStopRecordingWhenModelNotInstalled() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startStream = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopStream = {}
            $0.audioCaptureClient.startLevelMonitoring = { AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.startRecognition = { _, _ in AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.stopRecognition = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in false }
        } operation: {
            HomeViewModel()
        }

        await model.startRecordingTask()

        // When
        await model.handleSourceLanguageChangeTask()

        // Then
        #expect(!model.isTranslationModelInstalled)
        #expect(!model.isRecording)
    }

    @Test("デバイス変更時の再起動処理")
    func testRestartOnDeviceChange() async {
        // Given
        let devices = [
            AudioDevice(id: "device1", name: "Mic 1"),
            AudioDevice(id: "device2", name: "Mic 2"),
        ]

        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { devices }
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.audioCaptureClient.startStream = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopStream = {}
            $0.audioCaptureClient.startLevelMonitoring = { AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.startRecognition = { _, _ in AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.stopRecognition = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        await model.startRecordingTask()
        #expect(model.isRecording)

        // When
        model.selectedDeviceID = "device2"

        // Then
        try? await Task.sleep(nanoseconds: 500_000_000)  // Wait for restart
        #expect(model.isRecording)
        #expect(model.selectedDeviceID == "device2")
    }

    @Test("デバイス変更時のレベルモニタリング再起動（録音していない場合）")
    func testRestartLevelMonitoringOnDeviceChange() async {
        // Given
        let devices = [
            AudioDevice(id: "device1", name: "Mic 1"),
            AudioDevice(id: "device2", name: "Mic 2"),
        ]

        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { devices }
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startLevelMonitoringOnly = {
                AsyncStream { continuation in
                    continuation.yield(0.5)
                    continuation.finish()
                }
            }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        #expect(!model.isRecording)

        // When
        model.selectedDeviceID = "device2"

        // Then
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(model.selectedDeviceID == "device2")

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(model.audioLevel == 0.5)
    }

    @Test("表示言語名の取得")
    func testDisplayLanguageNameRetrieval() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        #expect(model.getDisplayLanguageName(for: "en-US") != "en-US")  // 言語ごとの名前になること
    }

    @Test("isFinal かつ LLM 有効のときだけ LLM 翻訳が1回呼ばれる")
    func testLLMTranslationCalledOnlyOnFinalWithLLMEnabled() async {
        // Given
        let callLogger = CallLogger()
        let originalLLMSetting = UserDefaults.standard.bool(forKey: "llmTranslationEnabled")
        UserDefaults.standard.set(true, forKey: "llmTranslationEnabled")

        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startStream = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopStream = {}
            $0.audioCaptureClient.startLevelMonitoring = { AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.startRecognition = { _, _ in
                AsyncStream { continuation in
                    continuation.yield(TranscriptionResult(text: "Hel", isFinal: false))
                    continuation.yield(TranscriptionResult(text: "Hello", isFinal: false))
                    continuation.yield(TranscriptionResult(text: "Hello World", isFinal: true))
                    continuation.finish()
                }
            }
            $0.speechRecognitionClient.stopRecognition = {}
            $0.translationClient.translate = { _ in
                await callLogger.append("t")
                return "翻訳結果"
            }
            $0.translationClient.translateWithLLM = { _, _, _, _ in
                await callLogger.append("l")
                return "LLM翻訳結果"
            }
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        // When
        await model.startRecordingTask()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        #expect(
            await callLogger.log == ["t", "t", "t", "l"], "translate 3回の後に translateWithLLM 1回")
        #expect(model.transcripts.count == 1)
        #expect(model.transcripts.first?.translation == "LLM翻訳結果")

        // Cleanup
        UserDefaults.standard.set(originalLLMSetting, forKey: "llmTranslationEnabled")
        await model.stopRecordingTask()
    }

    @Test("LLM 無効のときは translateWithLLM が呼ばれない")
    func testLLMTranslationNotCalledWhenDisabled() async {
        // Given
        let callLogger = CallLogger()
        let originalLLMSetting = UserDefaults.standard.bool(forKey: "llmTranslationEnabled")
        UserDefaults.standard.set(false, forKey: "llmTranslationEnabled")

        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { [] }
            $0.audioCaptureClient.startLevelMonitoringOnly = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopLevelMonitoringOnly = {}
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.audioCaptureClient.startStream = { AsyncStream { $0.finish() } }
            $0.audioCaptureClient.stopStream = {}
            $0.audioCaptureClient.startLevelMonitoring = { AsyncStream { $0.finish() } }
            $0.speechRecognitionClient.startRecognition = { _, _ in
                AsyncStream { continuation in
                    continuation.yield(TranscriptionResult(text: "Hello", isFinal: true))
                    continuation.finish()
                }
            }
            $0.speechRecognitionClient.stopRecognition = {}
            $0.translationClient.translate = { _ in
                await callLogger.append("t")
                return "翻訳結果"
            }
            $0.translationClient.translateWithLLM = { _, _, _, _ in
                await callLogger.append("l")
                return "LLM翻訳結果"
            }
            $0.translationClient.isTranslationModelInstalled = { _, _ in true }
        } operation: {
            HomeViewModel()
        }

        // When
        await model.startRecordingTask()
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then
        #expect(await callLogger.log == ["t"], "translate のみ1回呼ばれ、translateWithLLM は呼ばれない")
        #expect(model.transcripts.first?.translation == "翻訳結果")

        // Cleanup
        UserDefaults.standard.set(originalLLMSetting, forKey: "llmTranslationEnabled")
        await model.stopRecordingTask()
    }
}
