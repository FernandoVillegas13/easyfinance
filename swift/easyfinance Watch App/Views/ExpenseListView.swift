import SwiftUI

struct ExpenseListView: View {
    @ObservedObject var viewModel: FinanceViewModel
    @State private var selectedCategory: SpendingCategory?

    init(
        viewModel: FinanceViewModel,
        selectedCategory: SpendingCategory? = nil
    ) {
        self.viewModel = viewModel
        _selectedCategory = State(initialValue: selectedCategory)
    }

    private var visibleSpendings: [Spending] {
        viewModel.spendings(in: selectedCategory)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tus gastos")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("Total registrado · \(viewModel.allTimeTotals.combinedText)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.easyMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                categoryPicker

                if viewModel.isRefreshing && visibleSpendings.isEmpty {
                    ProgressView("Actualizando…")
                        .tint(Color.easyMint)
                        .frame(maxWidth: .infinity)
                } else if let error = viewModel.loadError, visibleSpendings.isEmpty {
                    InlineStatusView(icon: "wifi.exclamationmark", message: error, tint: .orange)
                } else if visibleSpendings.isEmpty {
                    InlineStatusView(
                        icon: "tray",
                        message: selectedCategory == nil
                            ? "Todavía no hay gastos registrados."
                            : "No hay gastos en esta categoría."
                    )
                } else {
                    ForEach(visibleSpendings) { spending in
                        ExpenseRow(spending: spending, showsDate: true)
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .background(Color.easyBackground)
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isRefreshing)
                .accessibilityLabel("Actualizar gastos")
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                categoryButton(title: "Todos", category: nil)
                ForEach(viewModel.categorySummaries) { summary in
                    categoryButton(
                        title: summary.category.displayName,
                        category: summary.category
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func categoryButton(
        title: String,
        category: SpendingCategory?
    ) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.easyInk : .white)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(isSelected ? Color.easyMint : Color.easyCard)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
