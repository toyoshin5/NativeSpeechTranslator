import Cocoa
import Foundation

@MainActor
class OverlayService: ObservableObject {
    static let shared = OverlayService()

    private var windowController: OverlayWindowController?

    private init() {}

    func show() {
        if windowController == nil {
            windowController = OverlayWindowController()
        }

        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)

        // Center the window initially or set a specific frame
        if let window = windowController?.window, let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowWidth: CGFloat = 800
            
            // Initial positioning
            let x = screenRect.midX - (windowWidth / 2)
            let y = screenRect.minY + 200

            // Set width but allow height to be determined by content
            var frame = window.frame
            frame.origin.x = x
            frame.origin.y = y
            frame.size.width = windowWidth
            // We do NOT set height here to allow autosizing from content,
            // or we set a minimum if needed.

            window.setFrame(frame, display: true)
        }
    }

    func hide() {
        windowController?.close()
        windowController = nil  // Optional: Release the controller to save resources if really not needed
    }

    func updateText(_ text: String, original: String = "") {
        // If the window isn't visible, we might not want to show it automatically unless requested.
        // For now, assume if we are updating text, we might want it to be visible IF the user enabled overlay.
        // However, updating text shouldn't force-show if the user turned it off.
        // So we just update if the controller exists.
        // If the user hasn't called show(), windowController is nil.

        guard let controller = windowController, controller.window?.isVisible == true else {
            return
        }
        controller.updateText(text, original: original)
    }

    var isVisible: Bool {
        return windowController?.window?.isVisible == true
    }
}
