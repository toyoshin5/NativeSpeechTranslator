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

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @State private var isExporting = false
    @State private var exportDocument: TranscriptDocument?
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("selectedDeviceID") private var savedDeviceID: String = ""
    @AppStorage("isAutoScrollEnabled") private var isAutoScrollEnabled: Bool = true

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
                
                HStack(spacing: 8) {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundStyle(.secondary)
                    Slider(value: $fontSize, in: 10...40)
                        .frame(width: 100)
                    Image(systemName: "textformat.size.larger")
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 16)

                Spacer()

                if viewModel.isRecording {
                    Label("聞き取り中", systemImage: "recordingtape")
                        .foregroundColor(.red)
                } else {
                    Label("停止中", systemImage: "stop.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            AutoScrollView(items: viewModel.transcripts, isAutoScrollEnabled: isAutoScrollEnabled) { item in
                TranscriptRow(
                    original: item.original,
                    translation: item.translation,
                    isTranslating: item.isShowLoading,
                    fontSize: fontSize
                )
                .padding(.horizontal)
                Divider()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .overlay {
                Button(action: {
                    isAutoScrollEnabled.toggle()
                }) {
                    Image(systemName: "arrow.down.to.line")
                        .font(.title)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .glassEffect(.clear.interactive())
                .foregroundStyle(isAutoScrollEnabled ? .blue : .secondary)
                .padding()

                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            }

            Divider()

            HStack {
                RecordingButton(isRecording: viewModel.isRecording) {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
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
        .onAppear {
            if !savedDeviceID.isEmpty {
                viewModel.selectedDeviceID = savedDeviceID
            }
        }
        .onChange(of: viewModel.selectedDeviceID) { _, newValue in
            if let newValue = newValue {
                savedDeviceID = newValue
            }
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

#Preview {
    HomeView()
}
