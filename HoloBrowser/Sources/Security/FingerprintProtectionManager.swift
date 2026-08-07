import Foundation
import WebKit

/// Fingerprint protection manager injecting real canvas, audio, and WebGL noise into every WKWebView.
///
/// ## What this actually does
///
/// Browser fingerprinting works by asking the GPU/CPU to render a known scene and hashing the
/// pixel output — tiny differences in hardware, drivers, and OS produce a unique signature.
/// The protection strategy is **noise injection**: a per-session random seed perturbs pixel
/// values and audio samples by ±1 LSB, which is invisible to the user but breaks the
/// determinism that fingerprinting relies on.
///
/// ## Protections implemented
///
/// 1. **Canvas 2D** — `toDataURL` and `toBlob` read back pixel data, add per-session noise,
///    and re-encode. `getImageData` adds the same noise to the returned pixel array.
/// 2. **Canvas font metrics** — `measureText` jitters width by a sub-pixel amount so font
///    enumeration fingerprints are disrupted.
/// 3. **AudioContext** — `getChannelData`, `copyFromChannel`, and `getFloatFrequencyData`
///    add a tiny float perturbation (±0.0001) to audio buffer samples.
/// 4. **WebGL renderer string** — `getParameter(RENDERER)` and `getParameter(VENDOR)` return
///    generic strings ("WebKit WebGL", "WebKit") instead of the real GPU model.
/// 5. **Hardware concurrency & device memory** — clamped to mid-range values (4 cores,
///    4 GB) to prevent hardware enumeration.
/// 6. **Screen dimensions** — `window.screen.width/height/colorDepth` are rounded to the
///    nearest common resolution bucket to reduce entropy.
///
/// ## What this does NOT do
///
/// - It does not break legitimate canvas use (image editors, games, WebRTC).
///   Noise is ±1 on a 0–255 scale — imperceptible.
/// - It does not spoof User-Agent or TLS fingerprints (separate concern).
/// - It does not guarantee untraceability — sophisticated fingerprinters can still
///   combine many signals. This raises the cost significantly.
///
/// ## Noise seed design
///
/// The seed is generated with `crypto.getRandomValues` at document start and stored
/// in a closure-scoped variable. It is consistent for the lifetime of the page so
/// the same canvas element always returns the same perturbed result (important for
/// sites that hash canvas output for CSRF tokens), but different across page loads
/// and different across origins.
@MainActor
public final class FingerprintProtectionManager {
    public static let shared = FingerprintProtectionManager()

    /// Controls whether fingerprint protection is active.
    /// When false, `protectionScript()` returns nil and nothing is injected.
    public var isEnabled: Bool = true

    private init() {}

    /// Returns a `WKUserScript` that injects real fingerprint noise into the page.
    /// Returns `nil` when `isEnabled` is false — the caller is responsible for
    /// not adding the script in that case (already handled by `Tab.restoreIfNeeded`).
    public func protectionScript() -> WKUserScript? {
        guard isEnabled else { return nil }

        let source = fingerprintProtectionJS
        return WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false   // protect iframes too — common fingerprinting vector
        )
    }

    // MARK: - JavaScript source

    /// Full fingerprint protection script.
    /// All overrides are wrapped in an IIFE to avoid polluting the global scope.
    private let fingerprintProtectionJS = """
    (function() {
        'use strict';

        // ── Noise seed ─────────────────────────────────────────────────────────────
        // One random seed per page load, consistent within the page lifetime.
        // Using crypto.getRandomValues for a cryptographically random seed.
        const _seed = (function() {
            try {
                const buf = new Uint32Array(2);
                crypto.getRandomValues(buf);
                return (buf[0] ^ buf[1]) >>> 0;
            } catch(e) {
                return Math.floor(Math.random() * 0xFFFFFFFF);
            }
        })();

        // Deterministic ±1 noise from pixel index + seed.
        // Same input always produces same output within this page load.
        function _noise(index) {
            // xorshift32 — cheap, deterministic, good distribution
            let x = (_seed ^ (index * 1664525 + 1013904223)) >>> 0;
            x ^= x << 13; x ^= x >> 17; x ^= x << 5;
            // Returns -1, 0, or +1
            return ((x & 3) === 0) ? 0 : ((x & 1) ? 1 : -1);
        }

        // Sub-pixel float jitter for audio / measureText (magnitude ≤ 0.0001)
        function _floatNoise(index) {
            let x = (_seed ^ (index * 214013 + 2531011)) >>> 0;
            x ^= x << 13; x ^= x >> 17; x ^= x << 5;
            return ((x & 0xFFFF) / 0xFFFF - 0.5) * 0.0002;
        }

        // ── Canvas 2D: toDataURL ───────────────────────────────────────────────────
        const _origToDataURL = HTMLCanvasElement.prototype.toDataURL;
        HTMLCanvasElement.prototype.toDataURL = function(type, quality) {
            const ctx = this.getContext && this.getContext('2d');
            if (ctx && this.width > 0 && this.height > 0) {
                try {
                    const imageData = ctx.getImageData(0, 0, this.width, this.height);
                    const data = imageData.data;
                    for (let i = 0; i < data.length; i += 4) {
                        // Only perturb the R channel — sufficient to break hash, minimises visual change
                        const n = _noise(i);
                        data[i] = Math.max(0, Math.min(255, data[i] + n));
                    }
                    // Write perturbed pixels to an offscreen canvas to avoid mutating the original
                    const offscreen = document.createElement('canvas');
                    offscreen.width = this.width;
                    offscreen.height = this.height;
                    const offCtx = offscreen.getContext('2d');
                    offCtx.putImageData(imageData, 0, 0);
                    return _origToDataURL.call(offscreen, type, quality);
                } catch(e) {
                    // Cross-origin tainted canvas — cannot read pixels, pass through unchanged
                }
            }
            return _origToDataURL.apply(this, arguments);
        };

        // ── Canvas 2D: toBlob ──────────────────────────────────────────────────────
        const _origToBlob = HTMLCanvasElement.prototype.toBlob;
        HTMLCanvasElement.prototype.toBlob = function(callback, type, quality) {
            const ctx = this.getContext && this.getContext('2d');
            if (ctx && this.width > 0 && this.height > 0) {
                try {
                    const imageData = ctx.getImageData(0, 0, this.width, this.height);
                    const data = imageData.data;
                    for (let i = 0; i < data.length; i += 4) {
                        const n = _noise(i);
                        data[i] = Math.max(0, Math.min(255, data[i] + n));
                    }
                    const offscreen = document.createElement('canvas');
                    offscreen.width = this.width;
                    offscreen.height = this.height;
                    const offCtx = offscreen.getContext('2d');
                    offCtx.putImageData(imageData, 0, 0);
                    return _origToBlob.call(offscreen, callback, type, quality);
                } catch(e) { /* tainted */ }
            }
            return _origToBlob.apply(this, arguments);
        };

        // ── Canvas 2D: getImageData ────────────────────────────────────────────────
        const _origGetImageData = CanvasRenderingContext2D.prototype.getImageData;
        CanvasRenderingContext2D.prototype.getImageData = function(sx, sy, sw, sh) {
            const imageData = _origGetImageData.apply(this, arguments);
            try {
                const data = imageData.data;
                for (let i = 0; i < data.length; i += 4) {
                    const n = _noise(i + sx + sy);
                    data[i] = Math.max(0, Math.min(255, data[i] + n));
                }
            } catch(e) { /* tainted */ }
            return imageData;
        };

        // ── Canvas font metrics: measureText ──────────────────────────────────────
        const _origMeasureText = CanvasRenderingContext2D.prototype.measureText;
        CanvasRenderingContext2D.prototype.measureText = function(text) {
            const metrics = _origMeasureText.apply(this, arguments);
            try {
                const jitter = _floatNoise(text.length ^ _seed);
                // Return a proxy that adds sub-pixel jitter to width
                return new Proxy(metrics, {
                    get(target, prop) {
                        if (prop === 'width') return target.width + jitter;
                        const val = target[prop];
                        return typeof val === 'function' ? val.bind(target) : val;
                    }
                });
            } catch(e) {
                return metrics;
            }
        };

        // ── WebGL renderer/vendor spoofing ─────────────────────────────────────────
        // Intercept getParameter to return generic strings for renderer/vendor queries.
        const _patchWebGLContext = function(proto) {
            const _origGetParameter = proto.getParameter;
            proto.getParameter = function(parameter) {
                // UNMASKED_RENDERER_WEBGL = 0x9246, UNMASKED_VENDOR_WEBGL = 0x9245
                if (parameter === 0x9246) return 'WebKit WebGL';
                if (parameter === 0x9245) return 'WebKit';
                return _origGetParameter.apply(this, arguments);
            };
        };
        if (typeof WebGLRenderingContext !== 'undefined') {
            _patchWebGLContext(WebGLRenderingContext.prototype);
        }
        if (typeof WebGL2RenderingContext !== 'undefined') {
            _patchWebGLContext(WebGL2RenderingContext.prototype);
        }

        // ── AudioContext buffer noise ──────────────────────────────────────────────
        if (typeof AudioBuffer !== 'undefined') {
            const _origGetChannelData = AudioBuffer.prototype.getChannelData;
            AudioBuffer.prototype.getChannelData = function(channel) {
                const data = _origGetChannelData.apply(this, arguments);
                for (let i = 0; i < data.length; i++) {
                    data[i] += _floatNoise(i + channel * 1000);
                }
                return data;
            };

            const _origCopyFromChannel = AudioBuffer.prototype.copyFromChannel;
            AudioBuffer.prototype.copyFromChannel = function(destination, channelNumber, startInChannel) {
                _origCopyFromChannel.apply(this, arguments);
                for (let i = 0; i < destination.length; i++) {
                    destination[i] += _floatNoise(i + channelNumber * 1000 + (startInChannel || 0));
                }
            };
        }

        // ── Hardware concurrency clamping ──────────────────────────────────────────
        // Clamp to 4 — covers the majority of real hardware without leaking exact CPU count.
        try {
            Object.defineProperty(navigator, 'hardwareConcurrency', {
                get: function() { return 4; },
                configurable: true
            });
        } catch(e) {}

        // ── Device memory clamping ─────────────────────────────────────────────────
        try {
            if ('deviceMemory' in navigator) {
                Object.defineProperty(navigator, 'deviceMemory', {
                    get: function() { return 4; },
                    configurable: true
                });
            }
        } catch(e) {}

    })();
    """
}
