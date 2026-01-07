import AVFoundation
import SwiftUI

@available(macOS 26, *)
struct ContentView: View {

    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー領域
            HStack {
                Picker("入力デバイス", selection: $viewModel.selectedDeviceID) {
                    ForEach(viewModel.inputDevices, id: \.uniqueID) { device in
                        Text(device.localizedName).tag(device.uniqueID as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 250)

                // マイク入力ビジュアライザー
                AudioVisualizerView(level: viewModel.audioLevel)
                    .frame(width: 80, height: 20)
                    .padding(.leading, 8)

                Spacer()

                // ステータスインジケータ
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

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.transcripts) { item in
                        TranscriptRow(
                            original: item.original,
                            translation: item.translation,
                            isTranslating: item.isTranslating
                        )
                        .padding(.horizontal)
                        Divider()
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // フッター領域（コントロール）
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
                .keyboardShortcut(.space, modifiers: [])  // スペースキーで開始/停止

                Spacer()

                Button("ログを保存") {
                    // TODO: ログ保存機能（未実装）
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}
