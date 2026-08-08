# HOLO BROWSER — APPLE VISION PRO SPATIAL DESIGN SPECIFICATION (V1.8)

## 1. Visual Target: "Safari + Vision Pro + macOS 2030"

Holo Browser V1.8 implements an Apple first-party spatial computing interface:

- **Optical Transparency**: Wallpaper and background windows bleed softly through all UI layers via `.behindWindow` vibrancy.
- **Crystal Palette**: `Crystal White`, `Frost White`, `Ice Blue`, `Soft Cyan`, `Soft Violet`.
- **Pure White Specular Lighting**: Edge strokes consume `crystalSpecularGradient` (`Color.white.opacity(0.92)` -> `Color.white.opacity(0.50)` -> `iceBlue.opacity(0.35)`). Zero neon or dark backgrounds.

---

## 2. 5 Sheer Apple Crystal Material Tiers

| Tier Name | `NSVisualEffectView.Material` | Fill Opacity | Blur Radius | Target Component |
| :--- | :--- | :---: | :---: | :--- |
| **`crystalGlass`** | `.hudWindow` | `0.14` | 20pt | Toolbar, Floating Tab Bar, Navigation |
| **`clearGlass`** | `.titlebar` | `0.20` | 28pt | Buttons, Floating Controls |
| **`frostGlass`** | `.sidebar` | `0.32` | 42pt | Sidebars, Cards, Preference Panels |
| **`deepGlass`** | `.popover` | `0.48` | 54pt | Popovers, Context Menus, Dropdowns |
| **`holoGlass`** | `.menu` | `0.58` | 66pt | HoloMind AI Overlay & Vision Pro Cards |

---

## 3. Scorecard & Performance Metrics

- **Test Suite Pass Rate**: `102 / 102 Passed (100.0%)`
- **Cold Launch Latency**: `1636.6 ms`
- **RAM RSS Footprint**: `91.4 MB`
- **UI Frame Rate**: `60.0 FPS`
- **Beta Ready Status**: **YES ✅**
