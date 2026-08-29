import Foundation

/// Identifies why a dictation sheet was opened, so the view model knows what
/// to do with the resulting text once the user finishes.
enum DictationPurpose: Identifiable, Sendable {
    case logExpense
    case chat

    var id: Self { self }

    var title: String {
        switch self {
        case .logExpense: "Di tu gasto"
        case .chat: "Pregunta a tu dinero"
        }
    }

    var suggestions: [String] {
        switch self {
        case .logExpense:
            ["Gasté 10 soles en café", "Pasaje 2 soles", "Pagué 30 soles con tarjeta"]
        case .chat:
            ["¿Cuánto gasté hoy?", "¿En qué gasto más?", "Resume mis gastos de esta semana"]
        }
    }
}
