import SwiftUI
import Translation

struct SettingsView: View {
    @AppStorage("translationProvider") private var translationProvider: String = "LLM"
    
    var body: some View {
        Form {
            Section("Translation Service") {
                Picker("Provider", selection: $translationProvider) {
                    Text("LLM").tag("LLM")
                    if #available(macOS 15.0, *) {
                        Text("Apple Translation").tag("Apple")
                    }
                }
                .pickerStyle(.segmented)
                
                Text(translationProvider == "LLM" ? "Uses local LLM model." : "Uses Apple's system translation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if #available(macOS 15.0, *), translationProvider == "Apple" {
                AppleTranslationSettingsView()
            }
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}

struct AppleTranslationSettingsView: View {
    @State private var downloadConfiguration: TranslationSession.Configuration?
    @State private var status: LanguageAvailability.Status?
    @State private var errorMessage: String?
    
    // We assume translation to Japanese for this app
    private let targetLanguage = Locale.Language(identifier: "ja")
    
    var body: some View {
        Section("Offline Models (Target: Japanese)") {
            HStack {
                if let status = status {
                    switch status {
                    case .installed:
                        Label("Installed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    case .supported:
                        Label("Available to Download", systemImage: "arrow.down.circle").foregroundStyle(.orange)
                    case .unsupported:
                        Label("Unsupported", systemImage: "xmark.circle").foregroundStyle(.red)
                    @unknown default:
                        Text("Unknown Status")
                    }
                } else {
                    ProgressView().controlSize(.small)
                }
                
                Spacer()
                
                if status == .supported {
                    Button("Download") {
                        startDownload()
                    }
                } else if status == .installed {
                    Button("Check Again") {
                        Task { await checkStatus() }
                    }
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .task {
            await checkStatus()
        }
        .translationTask(downloadConfiguration) { session in
            do {
                if let config = downloadConfiguration {
                    print("Starting preparation for \(config)")
                    try await session.prepareTranslation()
                    print("Preparation complete")
                    await checkStatus()
                }
            } catch {
                print("Prepare error: \(error)")
                self.errorMessage = error.localizedDescription
            }
            downloadConfiguration = nil
        }
    }
    
    private func startDownload() {
        // Trigger download/prepare
        // NOTE: We do not specify source to allow system to prepare generic 'to Japanese' if possible,
        // or we assume English->Japanese if source is needed for a specific pair.
        // TranslationSession.Configuration docs suggest pair. 
        // Let's try specifying current language as source for better matching.
        let source = Locale.current.language
        downloadConfiguration = TranslationSession.Configuration(source: source, target: targetLanguage)
    }
    
    private func checkStatus() async {
        let availability = LanguageAvailability()
        let source = Locale.current.language
        let status = await availability.status(from: source, to: targetLanguage)
        self.status = status
    }
}

#Preview {
    SettingsView()
}
