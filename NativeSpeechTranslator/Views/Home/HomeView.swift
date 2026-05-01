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

    @AppStorage("sourceLanguage") private var sourceLanguage: String = "en-US"
    @AppStorage("targetLanguage") private var targetLanguage: String = "ja-JP"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(viewModel.getDisplayLanguageName(for: sourceLanguage))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .bold()
                    Divider()
                    Text(viewModel.getDisplayLanguageName(for: targetLanguage))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .bold()
                }
                .frame(height: 32)

                Divider()

                AutoScrollView(
                    items: viewModel.transcripts, isAutoScrollEnabled: isAutoScrollEnabled
                ) { item in
                    TranscriptRow(
                        original: item.original,
                        translation: item.translation,
                        fontSize: fontSize
                    )
                    .padding(.horizontal)
                    Divider()
                }
                .overlay(alignment: .bottomTrailing) {
                    Button(action: {
                        isAutoScrollEnabled.toggle()
                    }) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .glassEffect(.clear.interactive())
                    .foregroundStyle(isAutoScrollEnabled ? .red : .secondary)
                    .padding()
                }

                if !viewModel.isTranslationModelInstalled {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("翻訳モデルがインストールされていません")
                            .foregroundStyle(.secondary)
                        SettingsLink {
                            Text("設定を開く")
                        }
                        .buttonStyle(.link)
                    }
                    .padding(.vertical, 8)
                }
            }
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 8) {
                    RecordingButton(isRecording: viewModel.isRecording) {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(!viewModel.isTranslationModelInstalled)
                    .opacity(viewModel.isTranslationModelInstalled ? 1.0 : 0.5)

                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .status) {
                    HStack{
                        AudioVisualizerView(level: viewModel.audioLevel)
                            .frame(width: 16, height: 24)
                            .padding(.leading,12)
                        Picker("入力デバイス", selection: $viewModel.selectedDeviceID) {
                            ForEach(viewModel.inputDevices, id: \.id) { device in
                                Text(device.name).tag(device.id)
                            }

                        }
                        .padding(.trailing,8)
                        .frame(width: 160)
                    }


                }

                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 4) {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundStyle(.secondary)
                        Slider(value: $fontSize, in: 10...40)
                            .frame(width: 80)
                        Image(systemName: "textformat.size.larger")
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Toggle(isOn: $viewModel.isOverlayEnabled) {
                        Image(systemName: "rectangle.inset.filled.on.rectangle")
                    }
                    .toggleStyle(.button)
                    .help("翻訳オーバーレイを表示")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.clearTranscripts()
                    }) {
                        Image(systemName: "trash")
                    }
                    .help("ログ消去")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        let content = LogExporter.export(transcripts: viewModel.transcripts)
                        exportDocument = TranscriptDocument(content: content)
                        isExporting = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("ログ保存")
                }
            }
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
        .onChange(of: sourceLanguage) { _, _ in
            viewModel.handleSourceLanguageChange()
        }
        .onChange(of: targetLanguage) { _, _ in
            viewModel.handleTargetLanguageChange()
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
        .tint(.red)
}
