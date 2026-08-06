import SwiftUI

/// Settings panel for configuring AI providers, Keychain API keys, privacy levels, and conversation history.
public struct AISettingsView: View {
    @ObservedObject var aiManager: AIManager
    @ObservedObject var privacyManager: AIPrivacyManager
    
    @State private var selectedProviderTag: String = "Mock"
    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var openAISavedStatus: String? = nil
    @State private var anthropicSavedStatus: String? = nil
    
    public init(aiManager: AIManager, privacyManager: AIPrivacyManager) {
        self.aiManager = aiManager
        self.privacyManager = privacyManager
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.system(size: 16))
                    Text("Holo AI Preferences & Credentials")
                        .font(.headline)
                }
                Spacer()
            }
            
            Divider()
            
            // Active Provider Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Active AI Provider").font(.subheadline).bold()
                Picker("", selection: $selectedProviderTag) {
                    Text("Local Mock Provider (Fast / Offline)").tag("Mock")
                    Text("OpenAI GPT-4o").tag("OpenAI")
                    Text("Anthropic Claude 3.5 Sonnet").tag("Anthropic")
                }
                .pickerStyle(.menu)
                .onChange(of: selectedProviderTag) { _, newTag in
                    Task { @MainActor in
                        let type: AIProviderFactory.ProviderType
                        switch newTag {
                        case "OpenAI": type = .openAI
                        case "Anthropic": type = .anthropic
                        default: type = .mock
                        }
                        self.aiManager.provider = await AIProviderFactory.provider(for: type)
                    }
                }
            }
            
            Divider()
            
            // Keychain Credentials Management
            VStack(alignment: .leading, spacing: 10) {
                Text("API Key Credentials (Stored in Apple Keychain)").font(.subheadline).bold()
                
                // OpenAI Key Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI API Key").font(.caption).foregroundColor(.secondary)
                    HStack {
                        SecureField("sk-...", text: $openAIKey)
                            .textFieldStyle(.roundedBorder)
                        Button("Save Key") {
                            Task { @MainActor in
                                let success = await AIProviderFactory.saveKey(openAIKey, for: .openAI)
                                openAISavedStatus = success ? "Saved to Keychain" : "Invalid Key"
                                if success && selectedProviderTag == "OpenAI" {
                                    self.aiManager.provider = await AIProviderFactory.provider(for: .openAI)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    if let status = openAISavedStatus {
                        Text(status).font(.caption2).foregroundColor(status.contains("Saved") ? .green : .red)
                    }
                }
                
                // Anthropic Key Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Anthropic API Key").font(.caption).foregroundColor(.secondary)
                    HStack {
                        SecureField("sk-ant-...", text: $anthropicKey)
                            .textFieldStyle(.roundedBorder)
                        Button("Save Key") {
                            Task { @MainActor in
                                let success = await AIProviderFactory.saveKey(anthropicKey, for: .anthropic)
                                anthropicSavedStatus = success ? "Saved to Keychain" : "Invalid Key"
                                if success && selectedProviderTag == "Anthropic" {
                                    self.aiManager.provider = await AIProviderFactory.provider(for: .anthropic)
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    if let status = anthropicSavedStatus {
                        Text(status).font(.caption2).foregroundColor(status.contains("Saved") ? .green : .red)
                    }
                }
            }
            
            Divider()
            
            // Privacy Mode Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Page Context Privacy Shield").font(.subheadline).bold()
                Picker("", selection: $privacyManager.privacyMode) {
                    ForEach(AIPrivacyMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            
            Divider()
            
            // Storage Management
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clear AI Conversations").font(.subheadline).bold()
                    Text("Deletes all local chat records and message logs.").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button("Clear History") {
                    aiManager.conversationManager.clearConversation()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 460)
        .onAppear {
            Task { @MainActor in
                let isOpenAI = await AIProviderFactory.isConfigured(for: .openAI)
                let isAnthropic = await AIProviderFactory.isConfigured(for: .anthropic)
                if isOpenAI { openAISavedStatus = "Key configured in Keychain" }
                if isAnthropic { anthropicSavedStatus = "Key configured in Keychain" }
            }
        }
    }
}
