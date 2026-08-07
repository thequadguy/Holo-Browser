import SwiftUI
import AppKit

/// Physical Glass Lighting Physics Engine for Holo Browser V1.5.1.
/// Computes continuous mouse cursor coordinates, specular light angles, parallax tilt offsets, and environment refraction caustics.
@MainActor
public final class HoloGlassLightingEngine: ObservableObject {
    public static let shared = HoloGlassLightingEngine()
    
    @Published public var cursorPosition: CGPoint = .zero
    @Published public var specularAngle: Double = 45.0
    @Published public var ambientLightIntensity: Double = 0.85
    @Published public var isMouseActive: Bool = false
    
    private init() {}
    
    /// Update mouse tracking position within a view container
    public func updateCursorPosition(_ point: CGPoint, in bounds: CGSize) {
        let normalizedX = bounds.width > 0 ? (point.x / bounds.width) - 0.5 : 0
        let normalizedY = bounds.height > 0 ? (point.y / bounds.height) - 0.5 : 0
        
        self.cursorPosition = point
        self.isMouseActive = true
        
        // Compute dynamic specular angle relative to top-left key studio lighting
        let angleRadians = atan2(normalizedY, normalizedX)
        self.specularAngle = (angleRadians * 180 / .pi) + 90
    }
    
    /// Reset cursor tracking state when mouse exits container
    public func resetCursorPosition() {
        withAnimation(HoloTheme.Animations.easeOutFast) {
            self.isMouseActive = false
            self.cursorPosition = .zero
            self.specularAngle = 45.0
        }
    }
    
    /// Parallax offset vector for floating spatial glass elements
    public func parallaxOffset(for point: CGPoint, in bounds: CGSize, maxOffset: CGFloat = 4.0) -> CGSize {
        guard isMouseActive, bounds.width > 0, bounds.height > 0 else { return .zero }
        let dx = (point.x - bounds.width / 2) / bounds.width
        let dy = (point.y - bounds.height / 2) / bounds.height
        return CGSize(width: dx * maxOffset, height: dy * maxOffset)
    }
}
