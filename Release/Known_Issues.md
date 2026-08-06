# Holo Browser 1.0 — Known Issues & Workarounds

1. **Chrome Extension Manifest V2 Compatibility**: Holo Browser supports native WebKit WebExtensions and select MV3 extensions. Legacy MV2 extensions relying on deprecated background pages are not supported.
2. **Local AI Memory Usage**: Running 70B parameter local LLMs via Ollama requires 32GB+ Unified Memory. For 8GB/16GB Macs, 7B/8B quantized GGUF models are recommended.
3. **WebRTC IP Leak Protection**: WebRTC peer connections use standard WebKit media constraints. Advanced multi-homed VPN routing overrides can be configured in Preferences > Network.
