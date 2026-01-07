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
    func startStream() throws -> AsyncStream<(AVAudioPCMBuffer, AVAudioTime)> {
        let inputNode = engine.inputNode
        let bus = 0
        let format = inputNode.inputFormat(forBus: bus)
        
        return AsyncStream { continuation in
            self.streamContinuation = continuation
            
            inputNode.installTap(onBus: bus, bufferSize: 1024, format: format) { buffer, time in
                if self.isStreaming {
                    continuation.yield((buffer, time))
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
