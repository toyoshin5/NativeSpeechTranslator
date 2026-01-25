import AVFoundation
import Dependencies
import DependenciesMacros

struct AudioDevice: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
}

@DependencyClient
struct AudioCaptureClient: Sendable {
    @DependencyEndpoint
    var setInputDevice: @Sendable (_ deviceID: String?) async -> Void
    @DependencyEndpoint
    var startStream: @Sendable () async throws -> AsyncStream<(AVAudioPCMBuffer, AVAudioTime)>
    @DependencyEndpoint
    var stopStream: @Sendable () async -> Void
    @DependencyEndpoint
    var startLevelMonitoring: @Sendable () async -> AsyncStream<Float> = {
        AsyncStream { $0.finish() }
    }
    @DependencyEndpoint
    var startLevelMonitoringOnly: @Sendable () async -> AsyncStream<Float> = {
        AsyncStream { $0.finish() }
    }
    @DependencyEndpoint
    var stopLevelMonitoringOnly: @Sendable () async -> Void
    @DependencyEndpoint
    var getAvailableDevices: @Sendable () -> [AudioDevice] = { [] }
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
            AudioCaptureService.shared.getAvailableDevices().map { device in
                AudioDevice(id: device.uniqueID, name: device.localizedName)
            }
        }
    )
}
