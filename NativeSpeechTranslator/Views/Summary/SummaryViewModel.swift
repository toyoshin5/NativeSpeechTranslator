import Foundation

@Observable
@MainActor
class SummaryViewModel {
    var summaryText: String = ""
    var isLoading: Bool = false
    var error: String?

    private var transcripts: [String] = []

    func summarize(transcripts: [String]) {
        self.transcripts = transcripts
        self.isLoading = true
        self.error = nil
        self.summaryText = ""

        Task {
            do {
                let result = try await SummaryLLMService.shared.summarize(transcripts: transcripts)
                self.summaryText = result
            } catch {
                self.error = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func retry() {
        guard !transcripts.isEmpty else { return }
        summarize(transcripts: transcripts)
    }
}
