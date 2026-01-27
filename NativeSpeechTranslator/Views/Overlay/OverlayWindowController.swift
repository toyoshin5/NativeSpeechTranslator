import Cocoa
import SwiftUI

class TranslatingOverlayPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

@Observable
class OverlayViewModel {
    var text: String = ""
    var originalText: String = ""
}

class OverlayWindowController: NSWindowController {

    private let viewModel = OverlayViewModel()

    convenience init() {
        let window = TranslatingOverlayPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 200),
            styleMask: [
                .nonactivatingPanel, .utilityWindow, .borderless, .resizable, .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = NSWindow.Level.floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.title = "Translation Overlay"
        window.hasShadow = false
        window.isFloatingPanel = true

        self.init(window: window)

        self.setupContentView()
    }

    private func setupContentView() {
        guard let window = self.window else { return }

        let rootView = OverlayView(viewModel: self.viewModel)
        let hostingController = NSHostingController(rootView: rootView)
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor

        hostingController.sizingOptions = [.preferredContentSize]

        window.contentViewController = hostingController
    }

    func updateText(_ text: String, original: String) {
        Task { @MainActor in
            self.viewModel.text = text
            self.viewModel.originalText = original
        }
    }
}
