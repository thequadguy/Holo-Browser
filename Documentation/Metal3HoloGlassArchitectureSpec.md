# HOLO BROWSER — METAL 3 LIQUID GLASS ARCHITECTURE SPECIFICATION

## Executive Overview

This design specification outlines the GPU rendering architecture for `Metal3HoloGlassRenderer`, a high-performance liquid glass caustics shader subsystem for Holo Browser V1.3+. The renderer provides real-time optical glass refractions, liquid fluid dynamics, and dynamic blur caustics behind Holo Browser toolbars, tab strips, and sidebar overlays.

---

## 1. Design & Performance Objectives

1. **Native Metal 3 Pipeline**: Direct GPU shading via MSL (Metal Shading Language) on Apple Silicon (M1/M2/M3/M4) and Intel Macs with Metal 3 support.
2. **60–120 FPS Sustained Rendering**: Frame render budget under 2.5 ms per frame.
3. **Zero Overhead Fallback**: Automatic graceful fallback to standard `NSVisualEffectView` vibrancy on legacy GPUs or Low Power Mode.

---

## 2. Abstraction Layer Architecture

```
                       ┌──────────────────────────────┐
                       │  HoloGlassBackdrop (SwiftUI)  │
                       └──────────────┬───────────────┘
                                      │
              ┌───────────────────────┴───────────────────────┐
              ▼                                               ▼
┌───────────────────────────┐                   ┌───────────────────────────┐
│ Metal3HoloGlassRenderer   │                   │ NSVisualEffectView        │
│ (GPU Shaders / MetalKit)  │                   │ (Legacy / Low Power Mode) │
└───────────────────────────┘                   └───────────────────────────┘
```

---

## 3. Shader Pipeline Specifications

### A. MSL Caustic Shader (`HoloGlassCaustics.metal`)
- **Refraction Index**: Snell's Law optical glass refraction simulation (\(n = 1.52\)).
- **Noise Generator**: Simplex 3D noise for liquid fluid dynamic motion.
- **Chromatic Aberration**: Separate R/G/B channel offset sampling at glass edge boundaries.

### B. Dynamic Blur & Chromatic Depth Pass
- Dual-pass Gaussian Downsample -> Metal Performance Shaders (MPS) `MPSImageGaussianBlur`.

---

## 4. Hardware Fallback Policy

- **Apple Silicon (M1+)**: Active Metal 3 liquid dynamic shading.
- **Intel Macs (Dedicated GPU)**: Metal 3 shading active when AC powered.
- **Intel Macs (Integrated UHD Graphics) / Low Power Mode**: Automatic fallback to native `NSVisualEffectView`.

---

## 5. Implementation Roadmap Strategy

1. **Phase 1 (Current V1.2)**: Architecture specification finalized. No runtime GPU overhead added.
2. **Phase 2 (V1.3)**: Implement `HoloGlassMetalView` SwiftUI wrapper backed by MTKView.
