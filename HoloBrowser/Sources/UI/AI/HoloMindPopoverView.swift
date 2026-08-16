import SwiftUI
import WebKit

/// Floating contextual AI panel that anchors to the HoloMind toolbar button or Omnibox.
/// Redesigned using the Extreme Crystal Glass system.
public struct HoloMindPopoverView: View {
    @ObservedObject var aiManager: AIManager
    let activeTab: Tab?

    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var showPreviewSheet: Bool = false
    @State private var pendingContext: PageContext?

    // Breathing animation for loading state
    @State private var isBreathing: Bool = false

    public init(aiManager: AIManager, activeTab: Tab?) {
        self.aiManager = aiManager
        self.activeTab = activeTab
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HoloMindHeaderView(
                isThinking: aiManager.conversationManager.isStreaming,
                isBreathing: isBreathing,
                onClose: {
                    aiManager.isSidebarVisible = false
                }
            )

            Divider().overlay(Color.white.opacity(0.1))

            // Response / Context Area
            ScrollView {
                VStack(spacing: 12) {
                    if let lastMessage = aiManager.conversationManager.messages.last(where: { $0.role != .user }) {
                        // AI Response
                        HoloMindResponseArea(message: lastMessage)
                    } else if aiManager.conversationManager.isStreaming {
                        // Loading State (if no text yet)
                        HStack {
                            Text("Thinking...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(16)
                    } else {
                        // Empty Welcome State
                        VStack(alignment: .leading, spacing: 6) {
                            Text("How can I help?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Ask a question, summarize this page, or compare open tabs.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: 400) // Dynamically grows, but caps at 400
            .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(Color.white.opacity(0.1))

            // Quick Actions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    HoloMindQuickAction(
                        title: ScreenshotManager.shared.isCapturing ? "Capturing..." : "Capture & Ask",
                        icon: "camera.viewfinder"
                    ) {
                        triggerCaptureAndAsk()
                    }
                    HoloMindQuickAction(title: "Summarize", icon: "doc.plaintext") {
                        triggerSummarize()
                    }
                    HoloMindQuickAction(title: "Explain", icon: "text.magnifyingglass") {
                        triggerExplain()
                    }
                    HoloMindQuickAction(title: "Compare Tabs", icon: "arrow.left.and.right") {
                        submitAction("Compare my open tabs")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            // Screenshot Preview Badge
            if let visualContext = ScreenshotManager.shared.lastCapturedVisualContext,
               let nsImage = NSImage(data: visualContext.imageData) {
                HStack(spacing: 8) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 28)
                        .cornerRadius(4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screenshot Attached (\(visualContext.width)x\(visualContext.height))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("\(visualContext.imageData.count / 1024) KB JPEG")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        ScreenshotManager.shared.clearVisualContext()
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    })
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear screenshot preview")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(HoloTheme.Palette.holoCyan.opacity(0.12)))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Input Bar
            HoloMindInputBar(
                text: $inputText,
                isFocused: $isInputFocused,
                onSubmit: {
                    submitAction(inputText)
                    inputText = ""
                }
            )
        }
        .frame(width: 400)
        .background(
            ZStack {
                VisualEffectViewWrapper(material: .popover, blendingMode: .withinWindow)
                HoloTheme.Palette.chromeFill
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            HoloTheme.Palette.holoCyan.opacity(0.12),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Color.black.opacity(0.20), radius: 16, x: 0, y: 8)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
        .sheet(isPresented: $showPreviewSheet) {
            if let ctx = pendingContext {
                AIContextPreviewView(
                    pageContext: ctx,
                    onConfirm: {
                        showPreviewSheet = false
                        aiManager.summarizePage(title: ctx.title, text: ctx.bodyText)
                        pendingContext = nil
                    },
                    onCancel: {
                        showPreviewSheet = false
                        pendingContext = nil
                    }
                )
            }
        }
    }

    // MARK: - Actions

    private func triggerCaptureAndAsk() {
        guard let tab = activeTab else { return }

        // CB-2 Fix: derive private-browsing state from the tab's authoritative isPrivate
        // property — never trust a hardcoded Boolean. ScreenshotManager independently
        // enforces the same guard as a second layer of defence.
        let isPrivate = tab.isPrivate

        Task { @MainActor in
            do {
                // Pre-flight gatekeeper check before capture is attempted.
                // This is intentionally called BEFORE WKWebView.takeSnapshot so no
                // pixels are captured from a blocked context.
                try AIContextGatekeeper.shared.validateImageContext(
                    visualContext: nil,          // Pre-capture check — no data yet.
                    isPrivateBrowsing: isPrivate,
                    domainHost: tab.url?.host?.lowercased()
                )

                let visual = try await ScreenshotManager.shared.captureTabSnapshot(
                    tab: tab,
                    isPrivateBrowsing: isPrivate
                )

                // Post-capture gatekeeper: validates the actual payload size.
                try AIContextGatekeeper.shared.validateImageContext(
                    visualContext: visual,
                    isPrivateBrowsing: isPrivate,
                    domainHost: tab.url?.host?.lowercased()
                )

                // Auto-submit: "Capture & Ask" means capture AND send to AI.
                // The default prompt can be overridden by text already in the input bar.
                let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Analyze this page screenshot and describe what you see in detail."
                    : inputText

                aiManager.captureAndAsk(
                    question: prompt,
                    visualContext: visual,
                    pageText: nil,
                    isPrivate: isPrivate
                )
                inputText = ""
            } catch {
                // Any failure (private browsing, domain block, size limit, capture failure)
                // surfaces the reason and clears any partially captured data.
                ScreenshotManager.shared.clearVisualContext()
                let id = aiManager.conversationManager.appendAssistantPlaceholder()
                aiManager.conversationManager.updateStreamingMessage(
                    id: id,
                    text: "Screenshot blocked: \(error.localizedDescription)"
                )
                aiManager.conversationManager.finishStreaming()
            }
        }
    }

    private func submitAction(_ prompt: String) {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let webView = activeTab?.webView else {
            aiManager.chat(userText: trimmed)
            return
        }

        Task { @MainActor in
            if let context = try? await PageContextBuilder.buildContext(from: webView) {
                aiManager.askPage(question: trimmed, text: context.bodyText)
            } else {
                aiManager.chat(userText: trimmed)
            }
        }
    }

    private func triggerSummarize() {
        guard let webView = activeTab?.webView else { return }
        Task { @MainActor in
            if let context = try? await PageContextBuilder.buildContext(from: webView) {
                self.pendingContext = context
                self.showPreviewSheet = true
            }
        }
    }

    private func triggerExplain() {
        guard let webView = activeTab?.webView else { return }
        Task { @MainActor in
            if let selection = await SelectionExtractor.extractSelection(from: webView) {
                aiManager.explainSelection(selection)
            } else {
                // Fallback if nothing selected
                submitAction("Explain the main concepts of this page")
            }
        }
    }
}

// MARK: - Private Subcomponents

private struct HoloMindHeaderView: View {
    let isThinking: Bool
    let isBreathing: Bool
    let onClose: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(HoloTheme.Palette.holoCyan)
                    .font(.system(size: 14, weight: .bold))
                    .scaleEffect(isThinking && isBreathing ? 1.2 : 1.0)
                    .opacity(isThinking && isBreathing ? 0.7 : 1.0)

                Text("HoloMind")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                if isThinking {
                    Text("Thinking...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(HoloTheme.Palette.holoCyan)
                        .padding(.leading, 4)
                        .opacity(isBreathing ? 0.6 : 1.0)
                }
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct HoloMindResponseArea: View {
    let message: AIMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.content.isEmpty ? "..." : message.content)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
                .lineSpacing(4)
                .textSelection(.enabled)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HoloMindQuickAction: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isHovered ? HoloTheme.Palette.holoCyan.opacity(0.2) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(
                        isHovered ? HoloTheme.Palette.holoCyan.opacity(0.4) : Color.white.opacity(0.1),
                        lineWidth: 0.5
                    )
            )
            .foregroundColor(isHovered ? HoloTheme.Palette.holoCyan : .primary)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hover
            }
        }
    }
}

private struct HoloMindInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Ask HoloMind...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused(isFocused)
                .onSubmit {
                    onSubmit()
                }

            Button(action: onSubmit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(text.isEmpty ? .secondary.opacity(0.5) : HoloTheme.Palette.holoCyan)
                    .scaleEffect(text.isEmpty ? 1.0 : 1.1)
                    .animation(HoloDesign.Animations.springFast, value: text.isEmpty)
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused.wrappedValue
                        ? HoloTheme.Palette.holoCyan.opacity(0.5)
                        : Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
