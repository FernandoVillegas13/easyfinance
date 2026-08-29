import Combine
import Foundation

@MainActor
final class FinanceViewModel: ObservableObject {
    @Published private(set) var spendings: [Spending] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var hasLoaded = false
    @Published private(set) var loadError: String?

    @Published private(set) var isLoggingExpense = false
    @Published private(set) var logTranscript: String?
    @Published private(set) var logFeedback: String?
    @Published private(set) var pendingCount = 0

    @Published private(set) var isChatting = false
    @Published private(set) var chatQuestion: String?
    @Published private(set) var chatResponse: String?
    @Published private(set) var chatError: String?

    /// Set to present the dictation sheet; the view observes this and shows
    /// `DictationSheet` when non-nil, clearing it once the user submits or
    /// cancels.
    @Published var activeDictation: DictationPurpose?

    private let apiClient: AgentAPIClient
    private let pendingStore: PendingExpenseStore

    init(
        apiClient: AgentAPIClient? = nil,
        pendingStore: PendingExpenseStore? = nil
    ) {
        self.apiClient = apiClient ?? AgentAPIClient(configuration: .live())
        self.pendingStore = pendingStore ?? PendingExpenseStore()
    }

    var todayTotals: MoneyTotals {
        MoneyTotals(spendings: spendings.filter(\.isToday))
    }

    var allTimeTotals: MoneyTotals {
        MoneyTotals(spendings: spendings)
    }

    var todayExpenseCount: Int {
        spendings.filter(\.isToday).count
    }

    var categorySummaries: [CategorySummary] {
        SpendingCategory.allCases.compactMap { category in
            let matchingSpendings = spendings.filter { $0.category == category }
            guard !matchingSpendings.isEmpty else { return nil }

            let subcategories = Set(
                matchingSpendings.compactMap { spending -> String? in
                    guard let value = spending.subcategory?
                        .trimmingCharacters(in: .whitespacesAndNewlines),
                          !value.isEmpty else {
                        return nil
                    }
                    return value.capitalized
                }
            ).sorted()

            return CategorySummary(
                category: category,
                count: matchingSpendings.count,
                totals: MoneyTotals(spendings: matchingSpendings),
                subcategories: subcategories
            )
        }
    }

    func spendings(in category: SpendingCategory?) -> [Spending] {
        guard let category else { return spendings }
        return spendings.filter { $0.category == category }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refreshPendingCount()
        await refresh()
    }

    func refresh(silently: Bool = false) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        if !silently {
            loadError = nil
        }
        defer {
            isRefreshing = false
            hasLoaded = true
        }

        await drainPendingExpenses()

        do {
            spendings = try await apiClient.fetchSpendings()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    /// Sends every queued transcript to `/log`. Stops at the first retryable
    /// (network) failure so remaining items stay queued for the next attempt;
    /// non-retryable failures (bad request, invalid key) drop that one item
    /// so it doesn't block the rest of the queue forever.
    private func drainPendingExpenses() async {
        for pending in await pendingStore.all() {
            do {
                _ = try await apiClient.logExpense(pending.dateStampedTranscript)
                await pendingStore.remove(pending.id)
            } catch let error as AgentAPIError where error.isRetryable {
                break
            } catch {
                await pendingStore.remove(pending.id)
            }
        }
        await refreshPendingCount()
    }

    private func refreshPendingCount() async {
        pendingCount = await pendingStore.count()
    }

    func startLoggingExpense() {
        guard !isLoggingExpense else { return }
        activeDictation = .logExpense
    }

    func startAsking() {
        guard !isChatting else { return }
        activeDictation = .chat
    }

    func cancelDictation() {
        activeDictation = nil
    }

    /// Called by the view once the user submits text from the dictation
    /// sheet. Routes it to the log or chat flow based on why the sheet was
    /// opened.
    func handleDictationResult(_ purpose: DictationPurpose, text: String) async {
        activeDictation = nil
        let transcript = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else { return }

        switch purpose {
        case .logExpense:
            await logExpense(transcript)
        case .chat:
            await ask(transcript)
        }
    }

    private func logExpense(_ transcript: String) async {
        guard !isLoggingExpense else { return }
        isLoggingExpense = true
        logFeedback = nil
        logTranscript = transcript
        defer { isLoggingExpense = false }

        do {
            logFeedback = "Registrando…"
            let response = try await apiClient.logExpense(transcript)
            logFeedback = response.trimmingCharacters(in: .whitespacesAndNewlines)
            await refresh(silently: true)
        } catch let error as AgentAPIError where error.isRetryable {
            // Dictation already happened locally — never lose it because the
            // network failed. Queue it and retry automatically on refresh.
            await pendingStore.add(transcript)
            await refreshPendingCount()
            logFeedback = "Sin conexión. Se enviará automáticamente."
        } catch {
            logFeedback = error.localizedDescription
        }
    }

    func ask(_ question: String) async {
        let normalizedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuestion.isEmpty, !isChatting else { return }

        isChatting = true
        chatQuestion = normalizedQuestion
        chatResponse = nil
        chatError = nil
        defer { isChatting = false }

        do {
            let response = try await apiClient.chat(normalizedQuestion)
            chatResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            chatError = error.localizedDescription
        }
    }
}

struct MoneyTotals: Equatable, Sendable {
    let pen: Double
    let usd: Double

    init(pen: Double = 0, usd: Double = 0) {
        self.pen = pen
        self.usd = usd
    }

    init(spendings: [Spending]) {
        pen = spendings
            .filter { $0.currency.uppercased() != "USD" }
            .reduce(0) { $0 + $1.amount }
        usd = spendings
            .filter { $0.currency.uppercased() == "USD" }
            .reduce(0) { $0 + $1.amount }
    }

    var primaryText: String {
        if pen > 0 || usd == 0 {
            return String(format: "S/ %.2f", pen)
        }
        return String(format: "$ %.2f", usd)
    }

    var secondaryText: String? {
        guard pen > 0, usd > 0 else { return nil }
        return String(format: "$ %.2f", usd)
    }

    var combinedText: String {
        var values: [String] = []
        if pen > 0 || usd == 0 {
            values.append(String(format: "S/ %.2f", pen))
        }
        if usd > 0 {
            values.append(String(format: "$ %.2f", usd))
        }
        return values.joined(separator: " · ")
    }
}

struct CategorySummary: Identifiable, Equatable, Sendable {
    var id: SpendingCategory { category }

    let category: SpendingCategory
    let count: Int
    let totals: MoneyTotals
    let subcategories: [String]
}
