import SwiftUI

/// Vision Pro Spatial Glass Sphere Orb representing HoloMind AI in Holo Browser V1.5.
/// Features transparent crystal core, soft interior blue/cyan/violet light, and white pearl specular rim catch.
public struct HoloAssistantPresenceView: View {
    public enum PresenceState {
        case idle
        case listening
        case thinking
        case researching
        case responding
        case missionRunning
        
        // Legacy aliases
        public static let analyzing = PresenceState.listening
        public static let planning = PresenceState.thinking
        public static let awaitingApproval = PresenceState.responding
        public static let executing = PresenceState.missionRunning
    }
    
    var state: PresenceState
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var innerRingOpacity: Double = 0.6
    @State private var iridescentGlowOpacity: Double = 0.4
    @State private var particleAngle: Double = 0
    @State private var pulseWave: CGFloat = 1.0
    
    public init(state: PresenceState = .idle) {
        self.state = state
    }
    
    public var body: some View {
        ZStack {
            // 1. Soft Ambient Pearl/Cyan Holographic Aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(iridescentGlowOpacity * 0.7), Color.white.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .scaleEffect(pulseScale * pulseWave)
                .blur(radius: 5)
            
            // 2. Responding Soft Outward Light Pulse Wave
            if state == .responding {
                Circle()
                    .stroke(HoloTheme.Palette.holoCyan.opacity(0.4), lineWidth: 1.2)
                    .frame(width: 30, height: 30)
                    .scaleEffect(pulseWave)
                    .opacity(2.0 - Double(pulseWave))
            }
            
            // 3. Vision Pro Spatial Glass Core Sphere (Transparent core with soft interior spectral refractions)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.90), coreColor.opacity(0.75), HoloTheme.Palette.iceBlue.opacity(0.60)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 18, height: 18)
                .scaleEffect(pulseScale)
                .shadow(color: Color.white.opacity(0.5), radius: 3, x: -1, y: -1)
                .shadow(color: glowColor.opacity(0.25), radius: 4, x: 1, y: 1)
            
            // 4. White Pearl Specular Light Catch Edge
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), HoloTheme.Palette.holoCyan.opacity(0.40), Color.white.opacity(0.30)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .trim(from: 0.0, to: state == .missionRunning ? 0.85 : 0.25)
                        .stroke(state == .missionRunning ? HoloTheme.Palette.holoEmerald : Color.white, lineWidth: 1.5)
                        .rotationEffect(.degrees(rotation))
                )
            
            // 5. Researching Orbiting Particles
            if state == .researching {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(HoloTheme.Palette.holoCyan.opacity(0.8))
                        .frame(width: 3, height: 3)
                        .offset(x: 14 * cos(particleAngle + Double(i) * 2.09), y: 14 * sin(particleAngle + Double(i) * 2.09))
                }
            }
            
            // 6. Thinking Inner Orbiting Ring
            if state == .thinking || state == .listening {
                Circle()
                    .stroke(
                        HoloTheme.Palette.holoCyan.opacity(innerRingOpacity * 0.8),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(-rotation * 1.6))
            }
        }
        .frame(width: 36, height: 36)
        .onChange(of: state) { _, newState in
            updateAnimations(for: newState)
        }
        .onAppear {
            updateAnimations(for: state)
        }
    }
    
    private var coreColor: Color {
        switch state {
        case .idle: return HoloTheme.Palette.holoCyan.opacity(0.7)
        case .listening: return HoloTheme.Palette.holoBlue
        case .thinking: return HoloTheme.Palette.holoViolet
        case .researching: return HoloTheme.Palette.holoCyan
        case .responding: return HoloTheme.Palette.holoAmber
        case .missionRunning: return HoloTheme.Palette.holoEmerald
        }
    }
    
    private var ringColor: Color {
        switch state {
        case .idle: return HoloTheme.Palette.holoCyan
        case .listening: return HoloTheme.Palette.holoBlue
        case .thinking: return HoloTheme.Palette.holoViolet
        case .researching: return HoloTheme.Palette.holoCyan
        case .responding: return HoloTheme.Palette.holoAmber
        case .missionRunning: return HoloTheme.Palette.holoEmerald
        }
    }
    
    private var glowColor: Color {
        switch state {
        case .idle: return HoloTheme.Palette.holoCyan
        case .listening: return HoloTheme.Palette.holoBlue
        case .thinking: return HoloTheme.Palette.holoViolet
        case .researching: return HoloTheme.Palette.holoCyan
        case .responding: return HoloTheme.Palette.holoAmber
        case .missionRunning: return HoloTheme.Palette.holoEmerald
        }
    }
    
    private func updateAnimations(for state: PresenceState) {
        guard HoloVisualEngine.shared.shouldAnimateContinuous else {
            withAnimation {
                pulseScale = 1.0
                rotation = 0
                innerRingOpacity = 0.5
                iridescentGlowOpacity = 0.3
                pulseWave = 1.0
            }
            return
        }
        
        switch state {
        case .idle:
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
                iridescentGlowOpacity = 0.45
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
        case .listening:
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulseScale = 1.18
                iridescentGlowOpacity = 0.65
            }
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                innerRingOpacity = 0.95
            }
            
        case .thinking:
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
                iridescentGlowOpacity = 0.60
            }
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                innerRingOpacity = 0.85
            }
            
        case .researching:
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulseScale = 1.12
                iridescentGlowOpacity = 0.70
            }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                particleAngle = .pi * 2
                rotation = 360
            }
            
        case .responding:
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                pulseScale = 1.25
                iridescentGlowOpacity = 0.75
            }
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                pulseWave = 1.6
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
        case .missionRunning:
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.12
                iridescentGlowOpacity = 0.65
            }
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
