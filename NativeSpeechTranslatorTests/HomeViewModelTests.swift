import Dependencies
import Foundation
import Testing

@testable import NativeSpeechTranslator

@Suite("HomeViewModel Tests")
@MainActor
struct HomeViewModelTests {

    @Test("初期状態の確認")
    func 初期状態_確認() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient = .testValue
            $0.speechRecognitionClient = .testValue
            $0.translationClient = .testValue
        } operation: {
            HomeViewModel()
        }

        // Then
        #expect(!model.isRecording)
        #expect(model.transcripts.isEmpty)
        #expect(model.inputDevices.isEmpty)
    }

    @Test("録音開始と停止が正しく機能する")
    func 録音開始_停止_正常系() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient = .testValue
            $0.speechRecognitionClient = .testValue
            $0.translationClient = .testValue
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
    func 音声認識結果_反映() async {
        // Given
        let transcriptionText = "こんにちは"
        let model = withDependencies {
            $0.audioCaptureClient = .testValue
            $0.speechRecognitionClient.startRecognition = { _, _ in
                AsyncStream { continuation in
                    continuation.yield(TranscriptionResult(text: transcriptionText, isFinal: true))
                    continuation.finish()
                }
            }
            $0.translationClient.translate = { _ in "Hello" }
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
    func 録音開始失敗_処理() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient.startStream = { throw NSError(domain: "test", code: -1) }
            $0.speechRecognitionClient = .testValue
            $0.translationClient = .testValue
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
    func トランスクリプト_クリア() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient = .testValue
            $0.speechRecognitionClient = .testValue
            $0.translationClient = .testValue
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
    func ソース言語変更_録音中() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient = .testValue
            $0.speechRecognitionClient = .testValue
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
    func ターゲット言語変更() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient = .testValue
            $0.speechRecognitionClient = .testValue
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
    func モデル未インストール_録音停止() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient = .testValue
            $0.speechRecognitionClient = .testValue
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
    func デバイス変更_再起動() async {
        // Given
        let devices = [
            AudioDevice(id: "device1", name: "Mic 1"),
            AudioDevice(id: "device2", name: "Mic 2"),
        ]

        let model = withDependencies {
            $0.audioCaptureClient.getAvailableDevices = { devices }
            $0.audioCaptureClient.setInputDevice = { _ in }
            $0.speechRecognitionClient = .testValue
            $0.translationClient = .testValue
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
    func デバイス変更_レベルモニタリング再起動() async {
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
            $0.speechRecognitionClient = .testValue
            $0.translationClient = .testValue
        } operation: {
            HomeViewModel()
        }

        #expect(!model.isRecording)

        // When
        model.selectedDeviceID = "device2"

        // Then
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(model.selectedDeviceID == "device2")
        // Ideally verify startLevelMonitoringOnly caused audioLevel update
        // Simple check:
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(model.audioLevel == 0.5)
    }

    @Test("表示言語名の取得")
    func 表示言語名_取得() async {
        // Given
        let model = withDependencies {
            $0.audioCaptureClient = .testValue
            $0.speechRecognitionClient = .testValue
            $0.translationClient = .testValue
        } operation: {
            HomeViewModel()
        }

        #expect(model.getDisplayLanguageName(for: "en-US") != "en-US")  // 言語ごとの名前になること
    }
}
