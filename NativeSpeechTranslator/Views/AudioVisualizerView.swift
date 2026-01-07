import SwiftUI

struct AudioVisualizerView: View {
    var level: Float

    private let barCount = 10
    private let gain: Float = 5.0 // 入力レベルの増幅
    private let exponent: Float = 0.4 // 指数

    private var normalizedLevel: Float {
        let amplified = min(level * gain, 1.0)
        return pow(amplified, exponent)
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                let threshold = Float(index) / Float(barCount)

                RoundedRectangle(cornerRadius: 2)
                    .fill(color(for: index, active: normalizedLevel > threshold))
                    .frame(width: 6, height: 16)
                    .opacity(normalizedLevel > threshold ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.1), value: normalizedLevel)
            }
        }
    }

    func color(for index: Int, active: Bool) -> Color {
        guard active else { return .gray }

        if index < 6 {
            return .green
        } else if index < 8 {
            return .yellow
        } else {
            return .red
        }
    }
}

#Preview {
    AudioVisualizerView(level: 0.7)
        .padding()
        .background(Color.black)
}
