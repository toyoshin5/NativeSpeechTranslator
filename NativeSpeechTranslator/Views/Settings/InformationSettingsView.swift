import SwiftUI

struct InformationSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Native Speech Translator")
                    .font(.title2)
                    .fontWeight(.medium)

                Text(
                    "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0")"
                )
                .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                Text("© 2026 Shingo Toyoda")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    InformationSettingsView()
}
