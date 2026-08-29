import Foundation

/// A pending expense transcript that failed to send while offline, waiting
/// to be retried once connectivity is back.
nonisolated struct PendingExpense: Codable, Identifiable, Sendable {
    let id: UUID
    let transcript: String
    /// When the send attempt failed — sent along on retry so the agent can
    /// date the expense correctly even if the retry happens much later.
    let failedAt: Date

    init(transcript: String, failedAt: Date = .now) {
        id = UUID()
        self.transcript = transcript
        self.failedAt = failedAt
    }

    /// The original transcript with its real date prepended, e.g.
    /// "el 2026-08-29 gasté 1.60 en el bus" — so a retry sent later still
    /// logs the expense on the day it actually happened.
    var dateStampedTranscript: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateText = formatter.string(from: failedAt)
        return "El \(dateText) \(transcript)"
    }
}

/// Persists pending expense transcripts to disk so dictated expenses survive
/// app relaunches and lack of connectivity until they can be sent to `/log`.
actor PendingExpenseStore {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory
            self.fileURL = directory.appendingPathComponent("pending_expenses.json")
        }
    }

    func all() -> [PendingExpense] {
        load()
    }

    func count() -> Int {
        load().count
    }

    @discardableResult
    func add(_ transcript: String) -> PendingExpense {
        var items = load()
        let item = PendingExpense(transcript: transcript)
        items.append(item)
        save(items)
        return item
    }

    func remove(_ id: PendingExpense.ID) {
        var items = load()
        items.removeAll { $0.id == id }
        save(items)
    }

    private func load() -> [PendingExpense] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([PendingExpense].self, from: data)) ?? []
    }

    private func save(_ items: [PendingExpense]) {
        guard let data = try? encoder.encode(items) else { return }
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }
}
