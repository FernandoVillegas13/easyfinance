import SwiftUI

struct ConsultView: View {
    @ObservedObject var viewModel: FinanceViewModel

    private let suggestions = [
        "¿Cuánto gasté hoy?",
        "¿En qué categoría gasto más?",
        "Resume mis gastos de esta semana"
    ]

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

                voiceConsultation

                if let question = viewModel.chatQuestion {
                    responseCard(question: question)
                } else if let error = viewModel.chatError {
                    InlineStatusView(icon: "exclamationmark.bubble", message: error, tint: .orange)
                }

                suggestionsSection
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .background(Color.easyBackground)
        .navigationTitle("Consultar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var voiceConsultation: some View {
        VStack(spacing: 9) {
            VoiceButton(
                isActive: viewModel.isChatting,
                accessibilityLabel: viewModel.isChatting
                    ? "Consultando al agente"
                    : "Preguntar con dictado"
            ) {
                Task { await viewModel.askUsingDictation() }
            }

            Text(viewModel.isChatting ? "Consultando al agente…" : "Toca para preguntar")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if let error = viewModel.chatError, viewModel.chatQuestion == nil {
                Text(error)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func responseCard(question: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 5) {
                Image(systemName: "person.fill")
                    .font(.system(size: 9))
                Text(question)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(Color.easyMuted)

            Divider()
                .overlay(Color.white.opacity(0.08))

            if viewModel.isChatting {
                HStack(spacing: 7) {
                    ProgressView()
                        .tint(Color.easyMint)
                    Text("Analizando tus finanzas…")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.easyMint)
                }
            } else if let response = viewModel.chatResponse, !response.isEmpty {
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.easyMint)
                    AgentMessageText(content: response)
                }
            } else if let error = viewModel.chatError {
                InlineStatusView(icon: "exclamationmark.triangle", message: error, tint: .orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.easyCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("También puedes preguntar")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.easyMuted)

            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    Task { await viewModel.ask(suggestion) }
                } label: {
                    HStack {
                        Image(systemName: "text.bubble.fill")
                        Text(suggestion)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isChatting)
            }
        }
    }
}
