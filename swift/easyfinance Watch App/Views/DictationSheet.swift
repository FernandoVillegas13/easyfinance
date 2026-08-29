import SwiftUI

/// Presents Apple Watch's native text input (dictation, Scribble, or Quick
/// Type suggestions) using a focused `TextField` inside a sheet.
///
/// `WKExtension.shared().visibleInterfaceController` only works for apps
/// built on the classic `WKInterfaceController` lifecycle. This app is pure
/// SwiftUI (`WKApplication`), so that controller is always `nil` here. A
/// focused `TextField` is the supported SwiftUI-native way to trigger the
/// same system dictation/keyboard picker on watchOS.
struct DictationSheet: View {
    let title: String
    let suggestions: [String]
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            TextField("", text: $text)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .labelsHidden()

            if !suggestions.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) { text = suggestion }
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            HStack {
                Button("Cancelar", role: .cancel, action: onCancel)
                Button("Listo") { onSubmit(text) }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .padding(12)
        .task {
            // watchOS presents the dictation/Scribble picker automatically
            // once the field becomes focused and visible.
            isFocused = true
        }
    }
}
