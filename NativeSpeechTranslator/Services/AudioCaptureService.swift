import AVFoundation
import Foundation

actor AudioCaptureService {

    private let engine = AVAudioEngine()

    private(set) var currentInputDevice: AVCaptureDevice?

    private(set) var isStreaming: Bool = false

    private var streamContinuation: AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>.Continuation?

    static let shared = AudioCaptureService()

    private init() {}

    /// 音声入力を開始し、バッファの非同期ストリームを返します。
    ///
    /// - Returns: `AVAudioPCMBuffer` と `AVAudioTime` の非同期ストリーム。
    /// - Throws: 音声エンジンの開始に失敗した場合にエラーをスローします。
    func startStream() throws -> AsyncStream<(AVAudioPCMBuffer, AVAudioTime)> {
        let inputNode = engine.inputNode
        let bus = 0
        let format = inputNode.inputFormat(forBus: bus)

        return AsyncStream { continuation in
            self.streamContinuation = continuation

            inputNode.removeTap(onBus: bus)
            inputNode.installTap(onBus: bus, bufferSize: 1024, format: format) { buffer, time in
                guard self.isStreaming else { return }
                self.processAudioLevel(buffer: buffer)

                continuation.yield((buffer, time))
            }

            do {
                if !self.engine.isRunning {
                    try self.engine.start()
                }
                self.isStreaming = true
            } catch {
                print("AudioEngine start error: \(error)")
                continuation.finish()
                self.isStreaming = false
            }
        }
    }

    func stopStream() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        streamContinuation?.finish()
        streamContinuation = nil

        levelContinuation?.finish()
        levelContinuation = nil

        isStreaming = false
    }

    // MARK: - Audio Levels

    /// 音声レベル（0.0 - 1.0）の継続
    private var levelContinuation: AsyncStream<Float>.Continuation?

    /// 音声レベルのモニタリングを開始し、レベルの非同期ストリームを返します。
    ///
    /// - Returns: 音声レベル（RMS, 0.0 - 1.0）の非同期ストリーム。
    func startLevelMonitoring() -> AsyncStream<Float> {
        AsyncStream { continuation in
            self.levelContinuation = continuation
        }
    }

    private func processAudioLevel(buffer: AVAudioPCMBuffer) {
        let channelData = buffer.floatChannelData
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        guard let channelData = channelData, frameLength > 0 else { return }

        var totalRms: Float = 0.0

        for i in 0..<channelCount {
            let channel = channelData[i]
            var channelSum: Float = 0.0

            // vDSPを使わずに手動計算 (簡易実装)
            // 必要に応じてAccelerate frameworkを使うと高速化可能
            for j in 0..<frameLength {
                let sample = channel[j]
                channelSum += sample * sample
            }

            totalRms += sqrt(channelSum / Float(frameLength))
        }

        let avgRms = totalRms / Float(channelCount)

        // 扱いやすいように少し増幅し、0.0-1.0にクランプ
        let amplifiedLevel = min(max(avgRms * 5.0, 0.0), 1.0)

        levelContinuation?.yield(amplifiedLevel)
    }

    nonisolated func getAvailableDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        ).devices
    }
}
