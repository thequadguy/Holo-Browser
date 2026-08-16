import SwiftUI

/// Native modal dialog overlay for JavaScript alert(), confirm(), and prompt().
/// Displays asynchronously over the browser content without blocking the main AppKit event loop.
public struct JavaScriptDialogOverlayView: View {
    public let dialog: JavaScriptDialogRequest
    public let onResolveAlert: () -> Void
    public let onResolveConfirm: (Bool) -> Void
    public let onResolvePrompt: (String?) -> Void

    @State private var promptText: String = ""

    public init(
        dialog: JavaScriptDialogRequest,
        onResolveAlert: @escaping () -> Void,
        onResolveConfirm: @escaping (Bool) -> Void,
        onResolvePrompt: @escaping (String?) -> Void
    ) {
        self.dialog = dialog
        self.onResolveAlert = onResolveAlert
        self.onResolveConfirm = onResolveConfirm
        self.onResolvePrompt = onResolvePrompt

        if case .prompt(_, let defaultText) = dialog.type {
            _promptText = State(initialValue: defaultText ?? "")
        }
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header with Origin Domain
            HStack(spacing: 12) {
                Image(systemName: headerIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(headerColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(dialog.originDomain)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(headerSubtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Dialog Content
            VStack(alignment: .leading, spacing: 12) {
                switch dialog.type {
                case .alert(let message):
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                case .confirm(let message):
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                case .prompt(let prompt, _):
                    if !prompt.isEmpty {
                        Text(prompt)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    TextField("", text: $promptText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .onSubmit {
                            onResolvePrompt(promptText)
                        }
                }
            }

            Divider()

            // Action Buttons
            HStack(spacing: 10) {
                Spacer()

                switch dialog.type {
                case .alert:
                    Button("OK") {
                        onResolveAlert()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)

                case .confirm:
                    Button("Cancel") {
                        onResolveConfirm(false)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)

                    Button("OK") {
                        onResolveConfirm(true)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)

                case .prompt:
                    Button("Cancel") {
                        onResolvePrompt(nil)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)

                    Button("OK") {
                        onResolvePrompt(promptText)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(
            VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
    }

    private var headerIcon: String {
        switch dialog.type {
        case .alert:
            return "exclamationmark.circle.fill"
        case .confirm:
            return "questionmark.circle.fill"
        case .prompt:
            return "text.bubble.fill"
        }
    }

    private var headerColor: Color {
        switch dialog.type {
        case .alert:
            return .blue
        case .confirm:
            return .purple
        case .prompt:
            return .teal
        }
    }

    private var headerSubtitle: String {
        switch dialog.type {
        case .alert:
            return "Webpage Alert"
        case .confirm:
            return "Webpage Confirmation"
        case .prompt:
            return "Webpage Prompt"
        }
    }
}
