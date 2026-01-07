import AVFoundation
import Foundation

/// 音声入力を管理し、`AVAudioPCMBuffer` のストリームを提供するアクター。
///
/// システムのマイクやその他の入力デバイスからの音声キャプチャを処理します。
actor AudioCaptureService {
    
    /// 音声エンジン
    private let engine = AVAudioEngine()
    
    /// 現在選択されている入力デバイス
    private(set) var currentInputDevice: AVCaptureDevice?
    
    /// ストリーミング中かどうか
    private(set) var isStreaming: Bool = false
    
    /// 音声バッファの継続（Continuation）
    private var streamContinuation: AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>.Continuation?
    
    /// シングルトンインスタンス
    static let shared = AudioCaptureService()
    
    /// 初期化
    private init() {}
    
    /// 音声入力を開始し、バッファの非同期ストリームを返します。
    ///
    /// - Returns: `AVAudioPCMBuffer` と `AVAudioTime` の非同期ストリーム。
    /// - Throws: 音声エンジンの開始に失敗した場合にエラーをスローします。
    /// 音声入力を開始し、バッファの非同期ストリームを返します。
    ///
    /// - Returns: `AVAudioPCMBuffer` と `AVAudioTime` の非同期ストリーム。
    /// - Throws: 音声エンジンの開始に失敗した場合にエラーをスローします。
    func startStream() throws -> AsyncStream<(AVAudioPCMBuffer, AVAudioTime)> {
        let inputNode = engine.inputNode
        let bus = 0
        let inputFormat = inputNode.inputFormat(forBus: bus)
        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                               sampleRate: inputFormat.sampleRate,
                                               channels: inputFormat.channelCount,
                                               interleaved: false) else {
            throw NSError(domain: "AudioCaptureService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create output audio format"])
        }
        
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
             throw NSError(domain: "AudioCaptureService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
        }
        
        return AsyncStream { continuation in
            self.streamContinuation = continuation
            
            inputNode.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { buffer, time in
                guard self.isStreaming else { return }
                
                if let outputBuffer = self.convert(buffer: buffer, using: converter, outputFormat: outputFormat) {
                    continuation.yield((outputBuffer, time))
                }
            }
            
            do {
                try self.engine.start()
                self.isStreaming = true
            } catch {
                continuation.finish()
                self.isStreaming = false
            }
        }
    }
    
    /// 音声バッファを指定されたフォーマット（Int16 PCM）に変換します。
    private func convert(buffer: AVAudioPCMBuffer, using converter: AVAudioConverter, outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: buffer.frameLength) else { return nil }
        
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if status != .error, error == nil {
            return outputBuffer
        } else {
            print("Audio conversion error: \(String(describing: error))")
            return nil
        }
    }
    
    /// 音声入力を停止します。
    func stopStream() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        streamContinuation?.finish()
        streamContinuation = nil
        isStreaming = false
    }
    
    /// 利用可能な音声入力デバイスのリストを取得します。
    ///
    /// - Returns: 利用可能な `AVCaptureDevice` の配列。
    nonisolated func getAvailableDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        ).devices
    }
}
