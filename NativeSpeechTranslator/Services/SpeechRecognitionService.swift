import AVFoundation
import Foundation
import Speech

struct TranscriptionResult: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isFinal: Bool
}

actor SpeechRecognitionService {

    static let shared = SpeechRecognitionService()

    private var analysisTask: Task<Void, Never>?
    private var audioConverter: AVAudioConverter?
    private var bestAvailableAudioFormat: AVAudioFormat?

    private init() {}

    /// 音声認識を開始します。
    ///
    /// - Parameter audioStream: 音声バッファの非同期ストリーム。
    /// - Returns: 認識結果の非同期ストリーム。
    func startRecognition(audioStream: AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>) -> AsyncStream<
        TranscriptionResult
    > {
        AsyncStream { continuation in
            analysisTask = Task {
                do {
                    guard
                        let locale = await SpeechTranscriber.supportedLocale(
                            equivalentTo: Locale.current)
                    else {
                        print("Supported locale not found")
                        continuation.finish()
                        return
                    }

                    try await AssetInventory.reserve(locale: locale)

                    let preset: SpeechTranscriber.Preset = .progressiveTranscription

                    let transcriber = SpeechTranscriber(
                        locale: locale,
                        preset: preset
                    )

                    let analyzer = SpeechAnalyzer(
                        modules: [transcriber],
                        options: .init(priority: .userInitiated, modelRetention: .processLifetime))

                    self.bestAvailableAudioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
                        compatibleWith: [transcriber])

                    try await analyzer.prepareToAnalyze(
                        in: self.bestAvailableAudioFormat, withProgressReadyHandler: nil)

                    let installed = (await SpeechTranscriber.installedLocales).contains(locale)
                    if !installed {
                        if let installationRequest =
                            try await AssetInventory.assetInstallationRequest(
                                supporting: [transcriber])
                        {
                            try await installationRequest.downloadAndInstall()
                        }
                    }

                    let (inputSequence, inputBuilder) = AsyncStream.makeStream(
                        of: AnalyzerInput.self)

                    Task {
                        do {
                            try await analyzer.start(inputSequence: inputSequence)
                        } catch {
                            print("Analyzer start error: \(error)")
                            continuation.finish()
                        }
                    }

                    Task {
                        for await (buffer, _) in audioStream {
                            if let format = self.bestAvailableAudioFormat {
                                if let converted = self.convertBuffer(buffer, to: format) {
                                    let input = AnalyzerInput(buffer: converted)
                                    inputBuilder.yield(input)
                                }
                            } else {
                                let input = AnalyzerInput(buffer: buffer)
                                inputBuilder.yield(input)
                            }
                        }
                        inputBuilder.finish()
                    }

                    do {
                        for try await result in transcriber.results {
                            let bestTranscription = result.text
                            let plainText = String(bestTranscription.characters)
                            let isFinal = result.isFinal

                            let res = TranscriptionResult(text: plainText, isFinal: isFinal)
                            continuation.yield(res)
                        }
                    } catch {
                        if error is CancellationError {
                            print("Task cancelled")
                        } else {
                            print("Transcription processing error: \(error)")
                        }
                    }

                    continuation.finish()

                    try await analyzer.finalize(through: nil)
                    await AssetInventory.release(reservedLocale: locale)

                } catch {
                    print("Speech recognition setup error: \(error)")
                    continuation.finish()
                }
            }
        }
    }

    func stopRecognition() {
        analysisTask?.cancel()
        analysisTask = nil
    }

    ///
    /// SpeechAnalyzerが要求するフォーマットに、入力された音声バッファを変換
    /// 例えば、マイク入力が48kHz/Stereoで、Analyzerが16kHz/Monoを要求する場合に使用
    ///
    /// - Parameters:
    ///   - buffer: 変換元の音声バッファ。
    ///   - format: 変換先のターゲットフォーマット。
    /// - Returns: 変換された音声バッファ。変換に失敗した場合は `nil`。
    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat)
        -> AVAudioPCMBuffer?
    {
        let inputFormat = buffer.format

        guard inputFormat != format else {
            return buffer
        }

        if audioConverter == nil || audioConverter?.outputFormat != format {
            audioConverter = AVAudioConverter(from: inputFormat, to: format)
            audioConverter?.primeMethod = .none
        }

        guard let converter = audioConverter else {
            print("Failed to create Audio Converter")
            return nil
        }

        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.up))

        guard
            let conversionBuffer = AVAudioPCMBuffer(
                pcmFormat: converter.outputFormat, frameCapacity: frameCapacity)
        else {
            print("Failed to create AVAudioPCMBuffer")
            return nil
        }

        var error: NSError?
        var bufferProcessed = false

        let inputBlock: AVAudioConverterInputBlock = { _, inputStatusPointer in
            defer { bufferProcessed = true }
            inputStatusPointer.pointee = bufferProcessed ? .noDataNow : .haveData
            return bufferProcessed ? nil : buffer
        }

        let status = converter.convert(
            to: conversionBuffer, error: &error, withInputFrom: inputBlock)

        if status == .error {
            print("Conversion failed: \(String(describing: error))")
            return nil
        }

        return conversionBuffer
    }
}
