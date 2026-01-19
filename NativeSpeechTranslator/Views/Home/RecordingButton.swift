import SwiftUI

struct RecordingButton: View {
    var isRecording: Bool
    var action: () -> Void

    @State private var buttonScale: CGFloat = 1.0
    @Namespace private var animationNamespace

    var body: some View {
        Button(action: {
            withAnimation(.smooth(duration: 0.3)) {
                action()
            }
        }) {
            HStack(spacing: 0) {
                ZStack {
                    if isRecording {
                        Image(systemName: "square.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.red))
                            .matchedGeometryEffect(id: "icon", in: animationNamespace)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .matchedGeometryEffect(id: "icon", in: animationNamespace)
                    }
                }
                .frame(width: 52, height: 50)

                if isRecording {
                    Text("聞き取り中")
                        .font(.headline)
                        .foregroundColor(.red)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                        .padding(.trailing, 16)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .background {
                Capsule()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .overlay(
                        Capsule()
                            .stroke(
                                isRecording
                                    ? Color.red.opacity(0.5) : Color(NSColor.separatorColor),
                                lineWidth: 1)
                    )
                    .frame(height: 52)
            }
            .scaleEffect(buttonScale)
        }
        .buttonStyle(.plain)
        .onChange(of: isRecording) { oldValue, newValue in
            buttonScale = 0.9
            withAnimation(.smooth(duration: 0.3)) {
                buttonScale = 1.0
            }
        }
    }
}
