import SwiftUI

struct CategoriesView: View {
    @ObservedObject var viewModel: FinanceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Categorías")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("Así se distribuyen tus gastos")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.easyMuted)
                }

                if viewModel.categorySummaries.isEmpty {
                    InlineStatusView(
                        icon: "square.grid.2x2",
                        message: "Las categorías aparecerán cuando registres gastos."
                    )
                } else {
                    ForEach(viewModel.categorySummaries) { summary in
                        NavigationLink {
                            ExpenseListView(
                                viewModel: viewModel,
                                selectedCategory: summary.category
                            )
                        } label: {
                            categoryCard(summary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .background(Color.easyBackground)
        .navigationTitle("Categorías")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func categoryCard(_ summary: CategorySummary) -> some View {
        HStack(spacing: 10) {
            Image(systemName: summary.category.symbolName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(summary.category.color)
                .frame(width: 34, height: 34)
                .background(summary.category.color.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.category.displayName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(categorySubtitle(summary))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.easyMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 3) {
                Text(summary.totals.combinedText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.easyMuted)
            }
        }
        .padding(11)
        .background(Color.easyCard)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func categorySubtitle(_ summary: CategorySummary) -> String {
        if summary.subcategories.isEmpty {
            return summary.count == 1 ? "1 gasto" : "\(summary.count) gastos"
        }

        let names = summary.subcategories.prefix(3).joined(separator: ", ")
        return "\(summary.count) gastos · \(names)"
    }
}
