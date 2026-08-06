# Holo Browser — Local AI Engine & Hardware Acceleration Architecture

**Author**: AI Systems Lead & Principal Engineer  
**Date**: July 30, 2026  

---

## 1. On-Device Hardware Acceleration Architecture

Holo Browser prioritizes local-first artificial intelligence running directly on Apple Silicon:

- **Apple Neural Engine (ANE)**: Core ML models execute text embeddings and document classification on the NPU without CPU/GPU overhead.
- **Local Ollama Integration**: Connects to `http://localhost:11434` for running local GGUF models (e.g., Llama 3 8B, Mistral 7B, Phi-3).
- **Zero Cloud Requirement**: Users can operate Holo Browser with cloud providers completely disabled.
- **Mandatory Privacy Gatekeeper**: Even local AI queries pass through `AIContextGatekeeper.shared` regex sanitization to strip passwords and credit card numbers.
