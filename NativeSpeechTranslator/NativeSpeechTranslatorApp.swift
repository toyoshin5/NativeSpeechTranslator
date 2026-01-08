import SwiftUI

@main
@available(macOS 26, *)
struct NativeSpeechTranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background {
                    if #available(macOS 15.0, *) {
                        TranslationHostView()
                    }
                }
        }
        
        Settings {
            SettingsView()
        }
    }
}
