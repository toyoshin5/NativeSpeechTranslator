
import SwiftUI

struct RecordingButton: View {
    var isRecording: Bool
    var action: () -> Void

    @State private var waveScale: CGFloat = 0.8
    @State private var waveOpacity: Double = 1.0
    @Namespace private var animationNamespace

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                action()
            }
        }) {
            ZStack {
                // Background Pulse Effect (Only when recording)
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 4)
                        .scaleEffect(waveScale)
                        .opacity(waveOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                waveScale = 2.0
                                waveOpacity = 0.0
                            }
                        }
                        .frame(width: 50, height: 50)
                }

                // Main Capsule Background
                Capsule()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .overlay(
                        Capsule()
                            .stroke(isRecording ? Color.red.opacity(0.5) : Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .frame(width: isRecording ? 180 : 60, height: 50)

                // Content
                HStack(spacing: 12) {
                    if isRecording {
                        Image(systemName: "square.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.red))
                            .matchedGeometryEffect(id: "icon", in: animationNamespace)
                        
                        Text("聞き取り中")
                            .font(.headline)
                            .foregroundColor(.red)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .matchedGeometryEffect(id: "icon", in: animationNamespace)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        // Ensure state reset when recording stops
        .onChange(of: isRecording) { _, newValue in
            if !newValue {
                // Reset animation state if needed
                waveScale = 0.8
                waveOpacity = 1.0
            }
        }
    }
}
