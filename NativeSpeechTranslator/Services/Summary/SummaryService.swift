import Cocoa
import Foundation

@MainActor
class SummaryService {
    static let shared = SummaryService()

    private var windowController: SummaryWindowController?

    private init() {}

    func showAndSummarize(transcripts: [String]) {
        if windowController == nil {
            windowController = SummaryWindowController()
        }

        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        windowController?.viewModel.summarize(transcripts: transcripts)
    }

    func hide() {
        windowController?.close()
        windowController = nil
    }
}
