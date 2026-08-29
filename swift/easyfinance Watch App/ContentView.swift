//
//  ContentView.swift
//  easyfinance Watch App
//
//  A small, voice-first expense logger for Apple Watch.
//

import SwiftUI

// MARK: - Models

struct Expense: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let category: String
    let amount: Double
    let date: Date
    let icon: String
    let color: Color
}

enum MockExpenseAPI {
    static let examples = [
        Expense(title: "Pasaje", category: "Transporte", amount: 1.50, date: .now, icon: "bus.fill", color: .blue),
        Expense(title: "Café", category: "Comida", amount: 10.00, date: .now.addingTimeInterval(-3600), icon: "cup.and.saucer.fill", color: .orange),
        Expense(title: "Mercado", category: "Hogar", amount: 42.80, date: .now.addingTimeInterval(-86_400), icon: "cart.fill", color: .green),
        Expense(title: "Taxi", category: "Transporte", amount: 15.00, date: .now.addingTimeInterval(-172_800), icon: "car.fill", color: .purple)
    ]

    static func newExpense() -> Expense {
        let sample = examples.randomElement() ?? examples[0]
        return Expense(
            title: sample.title,
            category: sample.category,
            amount: sample.amount,
            date: .now,
            icon: sample.icon,
            color: sample.color
        )
    }
}

enum MockInsightsAPI {
    static func answer(for question: String, total: Double) -> (String, String) {
        if question.localizedCaseInsensitiveContains("hoy") {
            return ("Hoy llevas", "S/ 11.50")
        }
        if question.localizedCaseInsensitiveContains("transporte") {
            return ("En transporte", "S/ 16.50")
        }
        return ("Tus gastos registrados", String(format: "S/ %.2f", total))
    }
}

// MARK: - Root

struct ContentView: View {
    @State private var expenses = MockExpenseAPI.examples
    @State private var isRecording = false
    @State private var feedback = ""

    private var todayTotal: Double {
        expenses.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    balanceCard
                    voiceLogger
                    recentExpenses
                    quickLinks
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)
            .background(Color.easyBackground)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("easyfinance")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Mi dinero, sin complicaciones")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.easyMuted)
            }
            Spacer()
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.easyMint)
                .symbolRenderingMode(.hierarchical)
        }
        .padding(.top, 10)
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("GASTOS DE HOY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Color.easyMuted)
                Spacer()
                Text("13 AGO")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.easyMint)
            }
            Text(String(format: "S/ %.2f", todayTotal))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            HStack(spacing: 5) {
                Circle().fill(Color.easyMint).frame(width: 6, height: 6)
                Text("Todo bajo control")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.easyMint)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.easyCard, Color(red: 0.10, green: 0.14, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06)))
    }

    private var voiceLogger: some View {
        VStack(spacing: 10) {
            VoiceButton(isRecording: $isRecording) {
                guard !isRecording else { return }
                isRecording = true
                feedback = "Escuchando…"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                    let expense = MockExpenseAPI.newExpense()
                    expenses.insert(expense, at: 0)
                    isRecording = false
                    feedback = "Guardado: \(expense.title) · S/ \(String(format: "%.2f", expense.amount))"
                }
            }
            Text(isRecording ? "Di cuánto gastaste…" : "Toca para agregar un gasto")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(feedback.isEmpty ? "Ej. “gasté 10 soles en café”" : feedback)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(isRecording ? Color.easyMint : Color.easyMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var recentExpenses: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("Últimos gastos", action: "Ver lista")
            ForEach(Array(expenses.prefix(2))) { expense in
                ExpenseRow(expense: expense)
            }
        }
    }

    private var quickLinks: some View {
        VStack(spacing: 9) {
            NavigationLink(destination: ExpenseListView(expenses: expenses)) {
                LinkRow(icon: "list.bullet.rectangle.portrait.fill", title: "Ver lista", subtitle: "Revisa tus gastos")
            }
            NavigationLink(destination: ConsultView(expenses: expenses)) {
                LinkRow(icon: "sparkles", title: "Consultar", subtitle: "Pregúntale a tu dinero")
            }
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ title: String, action: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            NavigationLink(action, destination: ExpenseListView(expenses: expenses))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.easyMint)
        }
    }
}

// MARK: - Voice control

struct VoiceButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.easyMint.opacity(isRecording ? 0.16 : 0.10))
                    .frame(width: 106, height: 106)
                Circle()
                    .fill(LinearGradient(colors: [Color.easyMint, Color(red: 0.16, green: 0.68, blue: 0.62)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 82, height: 82)
                    .shadow(color: Color.easyMint.opacity(0.35), radius: 12)
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(Color.easyInk)
                    .symbolEffect(.variableColor.iterative, isActive: isRecording)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Detener grabación" : "Agregar gasto por voz")
    }
}

// MARK: - Expense list

struct ExpenseListView: View {
    let expenses: [Expense]

    private var total: Double { expenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tus gastos")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Text(String(format: "Total registrado · S/ %.2f", total))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.easyMuted)
                }
                ForEach(expenses) { expense in
                    ExpenseRow(expense: expense, showsDate: true)
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .background(Color.easyBackground)
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExpenseRow: View {
    let expense: Expense
    var showsDate = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: expense.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(expense.color)
                .frame(width: 30, height: 30)
                .background(expense.color.opacity(0.14))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(showsDate ? expense.date.formatted(date: .abbreviated, time: .shortened) : expense.category)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.easyMuted)
            }
            Spacer()
            Text(String(format: "S/ %.2f", expense.amount))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Consult

struct ConsultView: View {
    let expenses: [Expense]
    @State private var isRecording = false
    @State private var question = ""
    @State private var answer: (String, String)?

    private let suggestions = ["¿Cuánto gasté hoy?", "¿Cuánto en transporte?", "¿Cuánto llevo?"]
    private var total: Double { expenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Consulta")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("Habla con tus gastos")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.easyMuted)
                }

                VStack(spacing: 9) {
                    VoiceButton(isRecording: $isRecording) {
                        guard !isRecording else { return }
                        isRecording = true
                        question = "¿Cuánto gasté hoy?"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                            answer = MockInsightsAPI.answer(for: question, total: total)
                            isRecording = false
                        }
                    }
                    Text(isRecording ? "Estoy escuchando…" : "Toca para preguntar")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                if let answer {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(question)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.easyMuted)
                        Text(answer.0)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.easyMint)
                        Text(answer.1)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.easyCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("También puedes preguntar")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.easyMuted)
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            question = suggestion
                            answer = MockInsightsAPI.answer(for: suggestion, total: total)
                        } label: {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                Text(suggestion)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .background(Color.easyBackground)
        .navigationTitle("Consultar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting views and styling

struct LinkRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.easyMint)
                .frame(width: 32, height: 32)
                .background(Color.easyMint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.easyMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.easyMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.easyCard)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

extension Color {
    static let easyBackground = Color(red: 0.035, green: 0.045, blue: 0.09)
    static let easyCard = Color(red: 0.075, green: 0.09, blue: 0.16)
    static let easyMuted = Color(red: 0.55, green: 0.59, blue: 0.70)
    static let easyMint = Color(red: 0.35, green: 0.94, blue: 0.79)
    static let easyInk = Color(red: 0.035, green: 0.09, blue: 0.10)
}

#Preview {
    ContentView()
}
