import AVFoundation
import Dependencies

struct AudioCaptureClient {
    var setInputDevice: @Sendable (String?) async -> Void
    var startStream: @Sendable () async throws -> AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>
    var stopStream: @Sendable () async -> Void
    var startLevelMonitoring: @Sendable () async -> AsyncStream<Float>
    var startLevelMonitoringOnly: @Sendable () async -> AsyncStream<Float>
    var stopLevelMonitoringOnly: @Sendable () async -> Void
    var getAvailableDevices: @Sendable () -> [AVCaptureDevice]
}

extension DependencyValues {
    var audioCaptureClient: AudioCaptureClient {
        get { self[AudioCaptureClient.self] }
        set { self[AudioCaptureClient.self] = newValue }
    }
}

extension AudioCaptureClient: DependencyKey {
    static let liveValue = AudioCaptureClient(
        setInputDevice: { deviceID in
            await AudioCaptureService.shared.setInputDevice(deviceID: deviceID)
        },
        startStream: {
            try await AudioCaptureService.shared.startStream()
        },
        stopStream: {
            await AudioCaptureService.shared.stopStream()
        },
        startLevelMonitoring: {
            await AudioCaptureService.shared.startLevelMonitoring()
        },
        startLevelMonitoringOnly: {
            await AudioCaptureService.shared.startLevelMonitoringOnly()
        },
        stopLevelMonitoringOnly: {
            await AudioCaptureService.shared.stopLevelMonitoringOnly()
        },
        getAvailableDevices: {
            AudioCaptureService.shared.getAvailableDevices()
        }
    )

    static let testValue = AudioCaptureClient(
        setInputDevice: { _ in },
        startStream: {
            AsyncStream { continuation in
                continuation.finish()
            }
        },
        stopStream: {},
        startLevelMonitoring: {
            AsyncStream { continuation in
                continuation.yield(0.5)
                continuation.finish()
            }
        },
        startLevelMonitoringOnly: {
            AsyncStream { continuation in
                continuation.yield(0.1)
                continuation.finish()
            }
        },
        stopLevelMonitoringOnly: {},
        getAvailableDevices: { [] }
    )

    static let previewValue = AudioCaptureClient(
        setInputDevice: { _ in },
        startStream: {
            AsyncStream { continuation in
                continuation.finish()
            }
        },
        stopStream: {},
        startLevelMonitoring: {
            AsyncStream { continuation in
                continuation.yield(0.5)
                continuation.finish()
            }
        },
        startLevelMonitoringOnly: {
            AsyncStream { continuation in
                continuation.yield(0.1)
                continuation.finish()
            }
        },
        stopLevelMonitoringOnly: {},
        getAvailableDevices: { [] }
    )
}
