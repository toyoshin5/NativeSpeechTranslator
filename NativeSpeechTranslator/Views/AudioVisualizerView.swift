import SwiftUI

struct AudioVisualizerView: View {
    var level: Float

    private let barCount = 10

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                let threshold = Float(index) / Float(barCount)

                RoundedRectangle(cornerRadius: 2)
                    .fill(color(for: index, active: level > threshold))
                    .frame(width: 6, height: 16)
                    .opacity(level > threshold ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.1), value: level)
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
