import AVFoundation
import Combine
import Foundation

@MainActor
@available(macOS 26, *)
class AppViewModel: ObservableObject {

    struct TranscriptItem: Identifiable {
        let id = UUID()
        let original: String
        var translation: String?
        var isTranslating: Bool = false
    }

    @Published var transcripts: [TranscriptItem] = []

    @Published var isRecording: Bool = false

    @Published var inputDevices: [AVCaptureDevice] = []

    @Published var audioLevel: Float = 0.0

    @Published var selectedDeviceID: String? = nil {
        didSet {
            // デバイス変更時の処理（再起動など）は必要に応じて実装
            // 現状はシンプルな実装とする
        }
    }

    private let audioService = AudioCaptureService.shared
    private let recognitionService = SpeechRecognitionService.shared
    private let translationService = TranslationService.shared

    /// 初期化
    init() {
        self.inputDevices = audioService.getAvailableDevices()
        if let defaultDevice = inputDevices.first {
            self.selectedDeviceID = defaultDevice.uniqueID
        }
    }

    /// 録音と認識を開始します。
    func startRecording() {
        guard !isRecording else { return }
        isRecording = true

        Task {
            do {
                let audioStream = try await audioService.startStream()

                // 音声認識の開始
                let transcriptionStream = await recognitionService.startRecognition(
                    audioStream: audioStream)

                // レベルモニタリングの開始
                let levelStream = await audioService.startLevelMonitoring()

                // 音声認識結果のハンドリング
                Task {
                    for await result in transcriptionStream {
                        await handleRecognitionResult(result)
                    }
                }

                // レベルストリームのハンドリング
                Task {
                    for await level in levelStream {
                        self.audioLevel = level
                    }
                }

            } catch {
                print("Error starting recording: \(error)")
                isRecording = false
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        Task {
            await audioService.stopStream()
            await recognitionService.stopRecognition()
            isRecording = false
        }
    }

    private func restartRecording() {
        stopRecording()
        // TODO: デバイス変更の反映ロジックが必要であればAudioServiceへ伝達
        // 注: AudioCaptureServiceのAPIをデバイス指定に対応させる必要があるが、今回は簡易的に再起動のみ

        // 少し待ってから再開
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            startRecording()
        }
    }

    /// 音声認識結果を処理
    ///
    /// - Parameter result: 認識結果
    private func handleRecognitionResult(_ result: TranscriptionResult) {
        if result.isFinal {
            let item = TranscriptItem(original: result.text, translation: nil, isTranslating: true)
            transcripts.append(item)

            let index = transcripts.count - 1
            translate(text: result.text, at: index)
        } else {
            // 途中経過を表示したい場合はここにロジックを追加
        }
    }

    /// 指定されたインデックスのテキストを翻訳
    ///
    /// - Parameters:
    ///   - text: 翻訳元のテキスト
    ///   - index: リスト内のインデックス
    private func translate(text: String, at index: Int) {
        Task {
            let translation = await translationService.translate(text)

            // UI更新
            if index < transcripts.count {
                transcripts[index].translation = translation
                transcripts[index].isTranslating = false
            }
        }
    }
}
