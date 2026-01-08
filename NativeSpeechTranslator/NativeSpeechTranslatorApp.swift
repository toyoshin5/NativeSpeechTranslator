import SwiftUI
import FoundationModels

@main
@available(macOS 26, *)
struct NativeSpeechTranslatorApp: App {
    init() {
        let defaults: [String: Any] = [
            "polishingEnabled": SystemLanguageModel.default.isAvailable
        ]
        UserDefaults.standard.register(defaults: defaults)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background {
                    TranslationHostView()
                }
        }

        Settings {
            SettingsView()
        }
    }
}
