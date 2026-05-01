import Cocoa
import SwiftUI

class SummaryWindowController: NSWindowController {

    let viewModel = SummaryViewModel()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "内容の要約"
        window.minSize = NSSize(width: 400, height: 300)
        window.center()

        self.init(window: window)
        self.setupContentView()
    }

    private func setupContentView() {
        guard let window = self.window else { return }

        let rootView = SummaryView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: rootView)

        window.contentViewController = hostingController
    }
}
