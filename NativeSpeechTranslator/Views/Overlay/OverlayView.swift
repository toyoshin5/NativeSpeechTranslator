import SwiftUI

struct OverlayView: View {
    @State var viewModel: OverlayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.originalText.isEmpty {
                Text(viewModel.originalText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .shadow(color: .black, radius: 2, x: -1, y: -1)
            }

            Text(viewModel.text.isEmpty ? "Waiting for translation..." : viewModel.text)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2, x: 1, y: 1)
                .shadow(color: .black, radius: 2, x: -1, y: -1)
        }
        .padding()
        .frame(width: 800, alignment: .leading)
    }
}

#Preview {
    let vm = OverlayViewModel()
    vm.originalText = "Hello, world!"
    vm.text = "こんにちは、世界！"
    return OverlayView(viewModel: vm)
        .background(Color.gray)
}
