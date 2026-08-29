import SwiftUI

struct VoiceButton: View {
    let isActive: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.easyMint.opacity(isActive ? 0.16 : 0.10))
                    .frame(width: 106, height: 106)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.easyMint, Color(red: 0.16, green: 0.68, blue: 0.62)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 82, height: 82)
                    .shadow(color: Color.easyMint.opacity(0.35), radius: 12)
                Image(systemName: isActive ? "waveform" : "mic.fill")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(Color.easyInk)
                    .symbolEffect(.variableColor.iterative, isActive: isActive)
            }
        }
        .buttonStyle(.plain)
        .disabled(isActive)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct ExpenseRow: View {
    let spending: Spending
    var showsDate = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: spending.category.symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(spending.category.color)
                .frame(width: 30, height: 30)
                .background(spending.category.color.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(spending.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(detailText)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.easyMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(spending.formattedAmount)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }

    private var detailText: String {
        guard showsDate, let date = spending.dateValue else {
            return spending.categoryDetail
        }
        return "\(spending.categoryDetail) · \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}

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

struct InlineStatusView: View {
    let icon: String
    let message: String
    var tint = Color.easyMuted

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(message)
                .foregroundStyle(Color.easyMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.system(size: 10, weight: .medium, design: .rounded))
        .padding(10)
        .background(Color.easyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct AgentMessageText: View {
    let content: String

    var body: some View {
        Text(attributedContent)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributedContent: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: content, options: options))
            ?? AttributedString(content)
    }
}

extension Color {
    static let easyBackground = Color(red: 0.035, green: 0.045, blue: 0.09)
    static let easyCard = Color(red: 0.075, green: 0.09, blue: 0.16)
    static let easyMuted = Color(red: 0.55, green: 0.59, blue: 0.70)
    static let easyMint = Color(red: 0.35, green: 0.94, blue: 0.79)
    static let easyInk = Color(red: 0.035, green: 0.09, blue: 0.10)
}

extension SpendingCategory {
    var color: Color {
        switch self {
        case .food: .orange
        case .transport: .blue
        case .shopping: .pink
        case .entertainment: .purple
        case .tech: .cyan
        case .health: .red
        case .travel: .indigo
        case .education: .yellow
        case .other: .gray
        }
    }
}
