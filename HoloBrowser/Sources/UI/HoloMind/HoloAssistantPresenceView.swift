import SwiftUI

/// Phase 9: H's Visual Identity
/// A subtle, animated holographic orb representing the assistant's state.
public struct HoloAssistantPresenceView: View {
    public enum PresenceState {
        case idle
        case analyzing
        case planning
        case awaitingApproval
        case executing
    }
    
    var state: PresenceState
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var innerRingOpacity: Double = 0.5
    
    public init(state: PresenceState = .idle) {
        self.state = state
    }
    
    public var body: some View {
        ZStack {
            // Base Core
            Circle()
                .fill(coreColor)
                .frame(width: 24, height: 24)
                .blur(radius: 4)
                .scaleEffect(pulseScale)
            
            // Outer Ring (Rotates based on state)
            Circle()
                .stroke(ringColor.opacity(0.8), lineWidth: 1.5)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .trim(from: 0.0, to: 0.2)
                        .stroke(Color.white, lineWidth: 2)
                        .rotationEffect(.degrees(rotation))
                )
            
            // Inner Ring (For complex states like planning/analyzing)
            if state == .analyzing || state == .planning {
                Circle()
                    .stroke(Color.cyan.opacity(innerRingOpacity), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-rotation * 1.5))
            }
        }
        .frame(width: 40, height: 40)
        .onChange(of: state) { _, newState in
            updateAnimations(for: newState)
        }
        .onAppear {
            updateAnimations(for: state)
        }
    }
    
    private var coreColor: Color {
        switch state {
        case .idle: return .gray.opacity(0.4)
        case .analyzing: return .blue
        case .planning: return .purple
        case .awaitingApproval: return .orange
        case .executing: return .green
        }
    }
    
    private var ringColor: Color {
        switch state {
        case .idle: return .white.opacity(0.2)
        case .analyzing: return .cyan
        case .planning: return .purple
        case .awaitingApproval: return .yellow
        case .executing: return .green
        }
    }
    
    private func updateAnimations(for state: PresenceState) {
        guard HoloVisualEngine.shared.shouldAnimateContinuous else {
            // Stop animations if reduced motion
            withAnimation {
                pulseScale = 1.0
                rotation = 0
                innerRingOpacity = 0.5
            }
            return
        }
        
        switch state {
        case .idle:
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
        case .analyzing:
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                innerRingOpacity = 1.0
            }
            
        case .planning:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                innerRingOpacity = 0.8
            }
            
        case .awaitingApproval:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
        case .executing:
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
