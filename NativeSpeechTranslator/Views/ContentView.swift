import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct TranscriptDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var content: String

    init(content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            content = String(data: data, encoding: .utf8) ?? ""
        } else {
            content = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: content.data(using: .utf8) ?? Data())
    }
}

@available(macOS 26, *)
struct ContentView: View {

    @StateObject private var viewModel = AppViewModel()
    @State private var isExporting = false
    @State private var exportDocument: TranscriptDocument?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("入力デバイス", selection: $viewModel.selectedDeviceID) {
                    ForEach(viewModel.inputDevices, id: \.uniqueID) { device in
                        Text(device.localizedName).tag(device.uniqueID as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 250)

                AudioVisualizerView(level: viewModel.audioLevel)
                    .frame(width: 80, height: 20)
                    .padding(.leading, 8)

                Spacer()

                if viewModel.isRecording {
                    Label("聞き取り中", systemImage: "recordingtape")
                        .foregroundColor(.red)
                } else {
                    Label("待機中", systemImage: "stop.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            AutoScrollView(items: viewModel.transcripts) { item in
                TranscriptRow(
                    original: item.original,
                    translation: item.translation,
                    isTranslating: item.isTranslating
                )
                .padding(.horizontal)
                Divider()
            }
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            HStack {
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.title2)
                        .padding()
                }
                .keyboardShortcut(.space, modifiers: [])

                Spacer()

                Button("ログを消去") {
                    viewModel.clearTranscripts()
                }
                .foregroundColor(.red)

                Button("ログを保存") {
                    let content = LogExporter.export(transcripts: viewModel.transcripts)
                    exportDocument = TranscriptDocument(content: content)
                    isExporting = true
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .plainText,
            defaultFilename: "transcript_\(formattedDate()).txt"
        ) { result in
            if case .failure(let error) = result {
                print("Failed to save log: \(error)")
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}
