import Foundation
import Speech
import AVFoundation

/// 音声認識結果を表す構造体。
struct TranscriptionResult: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isFinal: Bool
}

/// `SpeechAnalyzer` を使用して音声をテキストに変換するアクター。
@available(macOS 26, *)
actor SpeechRecognitionService {
    
    /// シングルトンインスタンス
    static let shared = SpeechRecognitionService()
    
    /// 分析タスク
    private var analysisTask: Task<Void, Never>?
    
    /// 初期化
    private init() {}
    
    /// 音声認識を開始します。
    ///
    /// - Parameter audioStream: 音声バッファの非同期ストリーム。
    /// - Returns: 認識結果の非同期ストリーム。
    func startRecognition(audioStream: AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>) -> AsyncStream<TranscriptionResult> {
        AsyncStream { continuation in
            analysisTask = Task {
                do {
                    // Step 1: Modules
                    // ユーザーのサンプルコードに従い、ロケールチェックとプリセット設定
                    guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) else {
                        print("Supported locale not found")
                        continuation.finish()
                        return
                    }
                    // .offlineTranscription が使えるか確認（サンプルコードにはある）
                    let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)
                    
                    // Step 2: Assets
                    // アセットのダウンロードとインストール
                    if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                        try await installationRequest.downloadAndInstall()
                    }
                    
                    // Step 3: Input sequence
                    // AnalyzerInputのストリームを作成
                    let (inputSequence, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
                    
                    // Step 4: Analyzer
                    // ベストなオーディオフォーマットを取得（今回は簡易的にAVAudioEngineのフォーマットを信頼するが、本来は変換が必要）
                    // let audioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
                    // 実際の実装では、入力オーディオを入力前にこのフォーマットにコンバートするのが理想
                    
                    let analyzer = SpeechAnalyzer(modules: [transcriber])
                    
                    // Step 5: Supply audio
                    // 引数の audioStream を inputSequence に流し込むタスク
                    Task {
                        for await (buffer, _) in audioStream {
                             // サンプルコード: let input = AnalyzerInput(buffer: pcmBuffer)
                            let input = AnalyzerInput(buffer: buffer)
                            inputBuilder.yield(input)
                        }
                        inputBuilder.finish()
                    }
                    
                    // Step 7: Act on results (Transcription)
                    // 結果受信タスク
                    Task {
                         do {
                             for try await result in transcriber.results {
                                 let bestTranscription = result.text // AttributedString
                                 // AttributedStringからStringへの変換: String(bestTranscription.characters)
                                 let plainText = String(bestTranscription.characters)
                                 let isFinal = result.isFinal
                                 
                                 let res = TranscriptionResult(text: plainText, isFinal: isFinal)
                                 continuation.yield(res)
                             }
                         } catch {
                             print("Transcription processing error: \(error)")
                         }
                         continuation.finish()
                     }
                    
                    // Step 6: Perform analysis
                    // 分析の実行（ここでブロックする可能性があるため、Analysis自体はawaitする）
                    // サンプルコード: let lastSampleTime = try await analyzer.analyzeSequence(inputSequence)
                    // ストリームが終了するまで待機
                    _ = try await analyzer.analyzeSequence(inputSequence)
                    
                    // Step 8: Finish analysis (今回はストリーム終了で自動的に終わるか、cancelで終わる)
                    
                } catch {
                    print("Speech recognition setup error: \(error)")
                    continuation.finish()
                }
            }
        }
    }
    
    /// 認識を停止します。
    func stopRecognition() {
        analysisTask?.cancel()
        analysisTask = nil
    }
}
