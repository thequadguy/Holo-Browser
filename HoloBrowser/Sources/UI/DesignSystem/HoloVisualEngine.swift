import SwiftUI

/// Phase 9: Holo Visual Engine
/// Centralized manager for holographic effects, ambient lighting, and glass intensity.
@MainActor
public final class HoloVisualEngine: ObservableObject {
    public static let shared = HoloVisualEngine()
    
    @Published public var effectsLevel: HoloEffectsLevel = .maximum
    @Published public var isAppActive: Bool = true
    
    // Performance derived values
    public var shouldAnimateContinuous: Bool {
        return isAppActive && effectsLevel != .reduced
    }
    
    public var globalGlowIntensity: Double {
        switch effectsLevel {
        case .maximum: return 1.0
        case .balanced: return 0.6
        case .reduced: return 0.2
        }
    }
    
    private init() {}
}

public enum HoloEffectsLevel: String, CaseIterable, Identifiable {
    case maximum = "Maximum (Premium Glass & Atmosphere)"
    case balanced = "Balanced (Optimized for Battery)"
    case reduced = "Reduced Motion"
    
    public var id: String { rawValue }
}

/// A subtle animated glow effect for active states
public struct HoloGlowEffect: ViewModifier {
    var color: Color
    var radius: CGFloat
    var isEnabled: Bool
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: isEnabled ? color.opacity(HoloVisualEngine.shared.globalGlowIntensity) : .clear,
                    radius: radius)
            .animation(.easeInOut(duration: 0.3), value: isEnabled)
    }
}

/// Simulates the Aurora lighting edge effect for premium panels
public struct AuroraEdgeLighting: ViewModifier {
    @State private var rotation: Double = 0
    var isActive: Bool
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [.clear, .purple.opacity(0.5), .cyan.opacity(0.5), .clear]),
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: isActive ? 1.5 : 0.5
                    )
                    .opacity(isActive ? 1.0 : 0.2)
                    .animation(.easeInOut(duration: 0.5), value: isActive)
            )
            .onAppear {
                if HoloVisualEngine.shared.shouldAnimateContinuous {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
            .onChange(of: HoloVisualEngine.shared.shouldAnimateContinuous) { _, animate in
                if animate {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    withAnimation { rotation = 0 }
                }
            }
    }
}

public extension View {
    func holoGlow(color: Color = .accentColor, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        self.modifier(HoloGlowEffect(color: color, radius: radius, isEnabled: isActive))
    }
    
    func auroraEdge(isActive: Bool = true) -> some View {
        self.modifier(AuroraEdgeLighting(isActive: isActive))
    }
}
