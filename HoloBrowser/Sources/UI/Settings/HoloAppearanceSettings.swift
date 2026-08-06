import SwiftUI
import Combine

/// Phase 9: Settings model for Holo Appearance and Visual Effects
public final class HoloAppearanceSettings: ObservableObject {
    public static let shared = HoloAppearanceSettings()
    
    @AppStorage("holo_effects_level")
    public var effectsLevelString: String = HoloEffectsLevel.maximum.rawValue {
        didSet {
            updateEngine()
        }
    }
    
    public var effectsLevel: HoloEffectsLevel {
        get { HoloEffectsLevel(rawValue: effectsLevelString) ?? .maximum }
        set { effectsLevelString = newValue.rawValue }
    }
    
    // Granular Toggles
    @AppStorage("holo_enable_liquid_glass") public var enableLiquidGlass: Bool = true
    @AppStorage("holo_enable_holographic_accents") public var enableHolographicAccents: Bool = true
    @AppStorage("holo_enable_animated_bg") public var enableAnimatedBackground: Bool = true
    @AppStorage("holo_enable_h_presence") public var enableHPresenceEffects: Bool = true
    @AppStorage("holo_enable_tab_glow") public var enableTabGlow: Bool = true
    @AppStorage("holo_reduced_motion") public var reducedMotion: Bool = false {
        didSet { updateEngine() }
    }
    
    private init() {
        // Sync initial state
        updateEngine()
    }
    
    private func updateEngine() {
        DispatchQueue.main.async {
            HoloVisualEngine.shared.effectsLevel = self.effectsLevel
        }
    }
}
