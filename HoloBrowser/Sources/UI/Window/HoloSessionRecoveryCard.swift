import SwiftUI

public struct HoloSessionRecoveryCard: View {
    @ObservedObject var viewModel: BrowserViewModel
    
    public init(viewModel: BrowserViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(HoloTheme.Palette.heroGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: HoloTheme.Glow.cyan.opacity(0.4), radius: 8, x: 0, y: 0)
                
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Restore Previous Browsing Session?")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(HoloTheme.Text.primary)
                Text("Holo unexpectedly quit. Reopen your tabs from your previous session.")
                    .font(.system(size: 12))
                    .foregroundColor(HoloTheme.Text.secondary)
            }
            
            Spacer(minLength: 24)
            
            // Actions
            HStack(spacing: 12) {
                Button("Start Fresh") {
                    dismissPromptAndClear()
                }
                .buttonStyle(HoloSecondaryButtonStyle())
                
                Button("Restore Session") {
                    restoreSession()
                }
                .buttonStyle(HoloPrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 600)
        .holoFloatingGlass(cornerRadius: 16, isHovered: true)
    }
    
    @MainActor
    private func dismissPromptAndClear() {
        withAnimation(HoloTheme.Animations.springSnappy) {
            viewModel.sessionManager.showRecoveryPrompt = false
        }
        // Run clearance after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.sessionManager.clearSavedSession()
        }
    }
    
    @MainActor
    private func restoreSession() {
        withAnimation(HoloTheme.Animations.springSnappy) {
            viewModel.sessionManager.showRecoveryPrompt = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.restorePreviousSession()
        }
    }
}
