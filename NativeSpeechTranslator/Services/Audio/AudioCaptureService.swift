import AVFoundation
import CoreAudio
import Foundation

actor AudioCaptureService {

    private let engine = AVAudioEngine()
    private(set) var currentInputDeviceID: String?
    private(set) var isStreaming: Bool = false
    private(set) var isLevelMonitoringOnly: Bool = false
    private var streamContinuation: AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>.Continuation?
    private var levelContinuation: AsyncStream<Float>.Continuation?

    static let shared = AudioCaptureService()
    private init() {}

    // MARK: - Device Selection

    func setInputDevice(deviceID: String?) {
        guard currentInputDeviceID != deviceID, let deviceID else {
            currentInputDeviceID = deviceID
            return
        }
        currentInputDeviceID = deviceID
        applySystemDefaultInputDevice(uid: deviceID)
    }

    private nonisolated func applySystemDefaultInputDevice(uid: String) {
        var audioDeviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let cfUID: CFString = uid as CFString

        var translateAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyTranslateUIDToDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = withUnsafePointer(to: cfUID) { cfUIDPtr in
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &translateAddress,
                UInt32(MemoryLayout<CFString>.size),
                UnsafeMutableRawPointer(mutating: cfUIDPtr),
                &size,
                &audioDeviceID
            )
        }
        guard status == noErr else { return }

        var defaultAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &audioDeviceID
        )
    }

    // MARK: - Audio Streaming

    func startStream() throws -> AsyncStream<(AVAudioPCMBuffer, AVAudioTime)> {
        stopLevelMonitoringOnly()
        return AsyncStream { continuation in
            self.streamContinuation = continuation
            self.installTap { buffer, time in
                guard self.isStreaming else { return }
                self.processAudioLevel(buffer: buffer)
                continuation.yield((buffer, time))
            }
            self.startEngineIfNeeded()
            self.isStreaming = true
        }
    }

    func stopStream() {
        stopEngine()
        streamContinuation?.finish()
        streamContinuation = nil
        levelContinuation?.finish()
        levelContinuation = nil
        isStreaming = false
    }

    // MARK: - Audio Levels

    func startLevelMonitoring() -> AsyncStream<Float> {
        AsyncStream { self.levelContinuation = $0 }
    }

    func startLevelMonitoringOnly() -> AsyncStream<Float> {
        guard !isStreaming && !isLevelMonitoringOnly else {
            return startLevelMonitoring()
        }
        installTap { buffer, _ in self.processAudioLevel(buffer: buffer) }
        startEngineIfNeeded()
        isLevelMonitoringOnly = true
        return AsyncStream { self.levelContinuation = $0 }
    }

    func stopLevelMonitoringOnly() {
        guard isLevelMonitoringOnly else { return }
        stopEngine()
        levelContinuation?.finish()
        levelContinuation = nil
        isLevelMonitoringOnly = false
    }

    private func processAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData, buffer.frameLength > 0 else { return }
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        var totalRms: Float = 0.0
        for i in 0..<channelCount {
            var sum: Float = 0.0
            for j in 0..<frameLength { sum += channelData[i][j] * channelData[i][j] }
            totalRms += sqrt(sum / Float(frameLength))
        }
        levelContinuation?.yield(min(totalRms / Float(channelCount) * 5.0, 1.0))
    }

    // MARK: - Engine Helpers

    private func installTap(handler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(
            onBus: 0, bufferSize: 1024, format: inputNode.inputFormat(forBus: 0), block: handler)
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do { try engine.start() } catch { print("AudioEngine start error: \(error)") }
    }

    private func stopEngine() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
    }

    // MARK: - Device Discovery

    nonisolated func getAvailableDevices() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        ).devices
    }
}
