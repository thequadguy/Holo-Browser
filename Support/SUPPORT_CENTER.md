# Holo Browser 1.0 — Official User Support Center & Help Hub

Welcome to the Holo Browser User Support Center!

## 🔍 Quick Help Categories

### 1. Installation & Gatekeeper Prompts
- **Issue**: macOS displays "App downloaded from the Internet".
- **Solution**: Click **Open** on the standard Apple Gatekeeper dialog. Holo Browser is signed with a Developer ID certificate and notarized by Apple.

### 2. Password Security & Keychain
- **Issue**: How are my passwords stored?
- **Solution**: Passwords store exclusively in your Mac's native Apple Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`). They are encrypted on-device and never sync to cloud servers.

### 3. AI Privacy & Sanitization
- **Issue**: Does Holo Browser share my webpage data with AI providers?
- **Solution**: No raw webpage data leaves your Mac. Holo Browser's regex privacy pipeline automatically redacts passwords, auth tokens, API keys, and credit cards before queries dispatch. In Private Browsing, cloud AI is blocked by default.

### 4. Diagnostics & Reporting
- **Issue**: How do I export diagnostic logs for support?
- **Solution**: Open **Preferences > Diagnostics** or click **Export Diagnostics** in `BetaStatusView.swift` to copy a privacy-sanitized diagnostic text file.
