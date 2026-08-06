import SwiftUI
import WebKit

public enum AISidebarTab: String, CaseIterable {
    case chat = "Chat"
    case research = "Research"
    case sources = "Sources"
    case notes = "Notes"
    case actions = "Actions"
}

/// Resizable native SwiftUI AI Sidebar drawer featuring tabbed navigation (Chat, Research, Sources, Notes, Actions).
public struct AISidebarView: View {
    @ObservedObject var aiManager: AIManager
    let activeTab: Tab?
    
    @StateObject private var researchManager = ResearchManager()
    @StateObject private var actionManager = AIActionManager()
    @State private var selectedTab: AISidebarTab = .chat
    @State private var sidebarWidth: CGFloat = 340
    @State private var showPreviewSheet: Bool = false
    @State private var pendingContext: PageContext? = nil
    
    public init(aiManager: AIManager, activeTab: Tab?) {
        self.aiManager = aiManager
        self.activeTab = activeTab
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Sidebar Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("Holo AI")
                        .font(.system(size: 14, weight: .bold))
                }
                
                if aiManager.provider.isLocal {
                    Text("Local AI Active")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.2)))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Keyboard Shortcut Badge (⌘⇧A)
                HStack(spacing: 2) {
                    Text("⌘⇧A")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.gray.opacity(0.15)))
                
                // Close Sidebar Button
                Button(action: {
                    aiManager.isSidebarVisible = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close AI Sidebar (⌘⇧A)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Tab Selector (Chat, Research, Sources, Notes, Actions)
            Picker("", selection: $selectedTab) {
                ForEach(AISidebarTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            
            Divider()
            
            // Active Content View depending on Tab
            switch selectedTab {
            case .chat:
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text(activeTab?.title.isEmpty == false ? activeTab!.title : "No Page Loaded")
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(aiManager.provider.name)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.purple.opacity(0.12)))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    
                    Divider()
                    
                    ConversationView(conversationManager: aiManager.conversationManager)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Divider()
                    
                    PromptInputView(
                        aiManager: aiManager,
                        onSummarize: { triggerSummarize() },
                        onAsk: { question in triggerAsk(question: question) },
                        onExplain: { triggerExplain() },
                        onRewrite: { triggerRewrite() }
                    )
                }
            case .research:
                ResearchWorkspaceView(researchManager: researchManager, aiManager: aiManager, isPrivate: false)
            case .sources:
                ResearchSourcesView(researchManager: researchManager)
            case .notes:
                ResearchNotesView(researchManager: researchManager, isPrivate: false)
            case .actions:
                ActionsView(actionManager: actionManager)
            }
        }
        .frame(width: sidebarWidth)
        .background(
            VisualEffectViewWrapper(material: .sidebar, blendingMode: .withinWindow)
        )
        .overlay(
            Divider(), alignment: .leading
        )
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
    
    // MARK: - Action Dispatchers
    
    private func triggerSummarize() {
        guard let webView = activeTab?.webView else { return }
        Task { @MainActor in
            if let context = try? await PageContextBuilder.buildContext(from: webView) {
                self.pendingContext = context
                self.showPreviewSheet = true
            }
        }
    }
    
    private func triggerAsk(question: String) {
        guard let webView = activeTab?.webView else { return }
        Task { @MainActor in
            if let context = try? await PageContextBuilder.buildContext(from: webView) {
                aiManager.askPage(question: question, text: context.bodyText)
            } else {
                aiManager.chat(userText: question)
            }
        }
    }
    
    private func triggerExplain() {
        guard let webView = activeTab?.webView else { return }
        Task { @MainActor in
            if let selection = await SelectionExtractor.extractSelection(from: webView) {
                aiManager.explainSelection(selection)
            }
        }
    }
    
    private func triggerRewrite() {
        guard let webView = activeTab?.webView else { return }
        Task { @MainActor in
            if let selection = await SelectionExtractor.extractSelection(from: webView) {
                aiManager.rewriteSelection(selection)
            }
        }
    }
}

private struct ActionsView: View {
    @ObservedObject var actionManager: AIActionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let plan = actionManager.activePlan {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Active Plan: \(plan.goal)")
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                        Spacer()
                        Text(plan.status.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    Text(plan.explanation)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                
                Divider()
            }
            
            Text("Execution Audit Log:")
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 8)
            
            if !actionManager.actionLogs.isEmpty {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(actionManager.actionLogs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.actionName)
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(log.result)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: log.wasApproved ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(log.wasApproved ? .green : .red)
                                    .font(.system(size: 12))
                            }
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "shield.checkmark")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No action history recorded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.vertical, 6)
    }
}
