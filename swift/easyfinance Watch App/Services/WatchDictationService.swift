import Foundation
import WatchKit

@MainActor
final class WatchDictationService {
    func transcribe(suggestions: [String] = []) async throws -> String {
        guard let interfaceController = WKExtension.shared().visibleInterfaceController else {
            throw WatchDictationError.interfaceUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            interfaceController.presentTextInputController(
                withSuggestions: suggestions.isEmpty ? nil : suggestions,
                allowedInputMode: .plain
            ) { results in
                guard let text = results?.first as? String else {
                    continuation.resume(throwing: WatchDictationError.cancelled)
                    return
                }

                let transcript = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty else {
                    continuation.resume(throwing: WatchDictationError.emptyTranscript)
                    return
                }

                continuation.resume(returning: transcript)
            }
        }
    }
}

enum WatchDictationError: LocalizedError {
    case interfaceUnavailable
    case cancelled
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .interfaceUnavailable:
            "No se pudo abrir el dictado del Apple Watch."
        case .cancelled:
            nil
        case .emptyTranscript:
            "No se recibió ninguna transcripción."
        }
    }
}
