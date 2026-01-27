import SwiftUI

struct OverlayView: View {
    @State var viewModel: OverlayViewModel

    var body: some View {
        ZStack {
            // Color.black.opacity(0.3)  // Re-add background for visibility if desired, or keep clear? converting to VStack

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.originalText.isEmpty ? "" : viewModel.originalText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .shadow(color: .black, radius: 2, x: -1, y: -1)

                Text(viewModel.text.isEmpty ? "Waiting for translation..." : viewModel.text)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                    .shadow(color: .black, radius: 2, x: -1, y: -1)
            }
            .padding()
            .frame(maxWidth: 800)  // Max width restriction
        }
        .edgesIgnoringSafeArea(.all)
        .frame(minHeight: 100)  // Ensure a reasonable minimum size for the view
    }
}

#Preview {
    let vm = OverlayViewModel()
    vm.originalText = "Hello, world!"
    vm.text = "こんにちは、世界！"
    return OverlayView(viewModel: vm)
        .background(Color.gray)
}
