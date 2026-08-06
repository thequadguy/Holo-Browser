# HOLO BROWSER — LIQUID GLASS DESIGN SYSTEM SPECIFICATION

## 1. Design System Principles

The Holo Liquid Glass rendering pipeline provides an intelligent, physical glass material experience calibrated to Apple visionOS and macOS Sonoma human interface standards.

Surfaces react dynamically to:
- Desktop wallpapers & background windows bleeding through with behind-window vibrancy (`.behindWindow`).
- Real-time continuous mouse coordinate tracking casting continuous specular light beams.
- Specular rim gradients capturing top-left key studio lighting and bottom-right prismatic caustics.

---

## 2. Liquid Glass Material Tiers

| Tier Name | `NSVisualEffectView.Material` | Fill Opacity | Blur Radius | Specular Rim Gradient | Target Component |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **`HoloClear`** | `.hudWindow` | `0.04` | 16pt | `white(0.65)` → `cyan(0.30)` | Address Bar & Search Pills |
| **`HoloGlass`** | `.sidebar` | `0.08` | 28pt | `white(0.70)` → `cyan(0.35)` → `purple(0.25)` | Floating Tab Bar & Toolbar |
| **`HoloFrost`** | `.popover` | `0.14` | 40pt | `white(0.75)` → `magenta(0.30)` | Sidebars & Preference Cards |
| **`HoloSolid`** | `.menu` | `0.32` | 52pt | `white(0.80)` → `cyan(0.25)` | Modal Dialogs & Settings Window |

---

## 3. Optical Physics & Animation Tokens

```swift
// Continuous Optical Mouse Tracking Physics
public static let opticalTracking = Animation.spring(response: 0.18, dampingFraction: 0.85)

// Snappy visionOS Interaction Physics
public static let springSnappy = Animation.spring(response: 0.24, dampingFraction: 0.75)
```
