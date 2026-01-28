import FoundationModels
import SwiftUI

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
            HomeView()
                .tint(.red)
                .background {
                    TranslationHostView()
                }
        }

        Settings {
            SettingsView()
        }
    }
}
