import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: FinanceViewModel

    init(viewModel: FinanceViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? FinanceViewModel())
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
        .task {
            await viewModel.loadIfNeeded()
        }
        .sheet(item: $viewModel.activeDictation) { purpose in
            DictationSheet(
                title: purpose.title,
                suggestions: purpose.suggestions,
                onSubmit: { text in
                    Task { await viewModel.handleDictationResult(purpose, text: text) }
                },
                onCancel: { viewModel.cancelDictation() }
            )
        }
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
            if viewModel.pendingCount > 0 {
                pendingBadge
            }
            refreshButton
            Image(systemName: connectionSymbol)
                .font(.system(size: 26))
                .foregroundStyle(connectionColor)
                .symbolRenderingMode(.hierarchical)
                .accessibilityLabel(connectionLabel)
        }
        .padding(.top, 10)
    }

    private var pendingBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 9, weight: .bold))
            Text("\(viewModel.pendingCount)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color.easyInk)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.orange)
        .clipShape(Capsule())
        .accessibilityLabel("\(viewModel.pendingCount) gastos pendientes de sincronizar")
    }

    private var refreshButton: some View {
        Button {
            Task { await viewModel.refresh() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.easyMuted)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isRefreshing)
        .accessibilityLabel("Actualizar gastos")
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("GASTOS DE HOY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Color.easyMuted)
                Spacer()
                Text(Date.now.formatted(.dateTime.day().month(.abbreviated)).uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.easyMint)
            }

            Text(viewModel.todayTotals.primaryText)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if let secondaryText = viewModel.todayTotals.secondaryText {
                Text(secondaryText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.easyMuted)
            }

            HStack(spacing: 5) {
                Circle()
                    .fill(balanceStatusColor)
                    .frame(width: 6, height: 6)
                Text(balanceStatus)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(balanceStatusColor)
                    .lineLimit(1)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.easyCard, Color(red: 0.10, green: 0.14, blue: 0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06)))
    }

    private var voiceLogger: some View {
        VStack(spacing: 10) {
            VoiceButton(
                isActive: viewModel.isLoggingExpense,
                accessibilityLabel: viewModel.isLoggingExpense
                    ? "Registrando gasto"
                    : "Agregar gasto con dictado"
            ) {
                viewModel.startLoggingExpense()
            }

            Text(viewModel.isLoggingExpense ? "Procesando…" : "Toca para agregar un gasto")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(logStatusText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(viewModel.isLoggingExpense ? Color.easyMint : Color.easyMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var recentExpenses: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle

            if viewModel.isRefreshing && viewModel.spendings.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.easyMint)
                    Spacer()
                }
                .padding(.vertical, 10)
            } else if let loadError = viewModel.loadError, viewModel.spendings.isEmpty {
                InlineStatusView(icon: "wifi.exclamationmark", message: loadError, tint: .orange)
            } else if viewModel.spendings.isEmpty {
                InlineStatusView(
                    icon: "tray",
                    message: "Aún no hay gastos. Registra el primero con el micrófono."
                )
            } else {
                ForEach(viewModel.spendings.prefix(3)) { spending in
                    ExpenseRow(spending: spending)
                }
            }
        }
    }

    private var sectionTitle: some View {
        HStack {
            Text("Últimos gastos")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            NavigationLink("Ver lista") {
                ExpenseListView(viewModel: viewModel)
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color.easyMint)
        }
    }

    private var quickLinks: some View {
        VStack(spacing: 9) {
            NavigationLink {
                ExpenseListView(viewModel: viewModel)
            } label: {
                LinkRow(
                    icon: "list.bullet.rectangle.portrait.fill",
                    title: "Ver lista",
                    subtitle: "Revisa tus gastos"
                )
            }

            NavigationLink {
                CategoriesView(viewModel: viewModel)
            } label: {
                LinkRow(
                    icon: "square.grid.2x2.fill",
                    title: "Categorías",
                    subtitle: "Descubre en qué gastas"
                )
            }

            NavigationLink {
                ConsultView(viewModel: viewModel)
            } label: {
                LinkRow(
                    icon: "sparkles",
                    title: "Consultar",
                    subtitle: "Pregúntale a tu dinero"
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var logStatusText: String {
        if let feedback = viewModel.logFeedback, !feedback.isEmpty {
            return feedback
        }
        if let transcript = viewModel.logTranscript, !transcript.isEmpty {
            return "“\(transcript)”"
        }
        return "Ej. “gasté 10 soles en café”"
    }

    private var balanceStatus: String {
        if viewModel.isRefreshing && !viewModel.hasLoaded {
            return "Actualizando tus gastos…"
        }
        if viewModel.pendingCount > 0 {
            return viewModel.pendingCount == 1
                ? "1 gasto pendiente de sincronizar"
                : "\(viewModel.pendingCount) gastos pendientes de sincronizar"
        }
        if viewModel.loadError != nil {
            return "No se pudo actualizar"
        }
        switch viewModel.todayExpenseCount {
        case 0: return "Sin gastos registrados hoy"
        case 1: return "1 gasto registrado hoy"
        default: return "\(viewModel.todayExpenseCount) gastos registrados hoy"
        }
    }

    private var balanceStatusColor: Color {
        (viewModel.loadError == nil && viewModel.pendingCount == 0) ? Color.easyMint : Color.orange
    }

    private var connectionSymbol: String {
        if viewModel.isRefreshing { return "arrow.triangle.2.circlepath.circle.fill" }
        if viewModel.loadError != nil { return "exclamationmark.circle.fill" }
        return "waveform.circle.fill"
    }

    private var connectionColor: Color {
        viewModel.loadError == nil ? Color.easyMint : .orange
    }

    private var connectionLabel: String {
        viewModel.loadError == nil ? "Agente conectado" : "Error de conexión"
    }
}

#Preview {
    ContentView()
}
