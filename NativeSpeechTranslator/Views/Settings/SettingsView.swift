import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("一般", systemImage: "gearshape")
                }
                .tag("general")
            
            InformationSettingsView()
                .tabItem {
                    Label("情報", systemImage: "info.circle")
                }
                .tag("information")
        }
        .frame(width: 450, height: 400) // Adjusted frame for better fit
        .padding()
    }
}

#Preview {
    SettingsView()
}
