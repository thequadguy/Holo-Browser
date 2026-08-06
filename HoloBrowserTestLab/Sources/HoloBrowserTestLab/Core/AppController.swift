import Foundation

public final class AppController {
    public static let shared = AppController()

    public let appPath: String = "/Users/jake/Desktop/Holo Browser.app"
    public let executablePath: String = "/Users/jake/Desktop/Holo Browser.app/Contents/MacOS/HoloBrowser"
    public let appSupportDir: String = ("~/Library/Application Support/HoloBrowser" as NSString).expandingTildeInPath

    private init() {}

    @discardableResult
    public func runShell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    public func isAppRunning() -> Bool {
        let pgrep = runShell("pgrep -f 'HoloBrowser' || true")
        return !pgrep.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func launchApp() -> Bool {
        if !isAppRunning() {
            _ = runShell("open \"\(appPath)\"")
            Thread.sleep(forTimeInterval: 2.0)
        }
        _ = runShell("osascript -e 'tell application \"Holo Browser\" to activate' 2>/dev/null || true")
        return isAppRunning()
    }

    public func terminateApp() {
        _ = runShell("pkill -f HoloBrowser || true")
        Thread.sleep(forTimeInterval: 0.5)
    }

    public func restartApp() -> Bool {
        terminateApp()
        return launchApp()
    }

    public func sendShortcut(key: String, modifiers: [String] = ["command down"]) {
        let modStr = modifiers.joined(separator: ", ")
        let script = """
        osascript -e 'tell application "System Events" to keystroke "\(key)" using {\(modStr)}' 2>/dev/null || true
        """
        _ = runShell(script)
        Thread.sleep(forTimeInterval: 0.15)
    }

    public func sendSpecialKey(code: Int, modifiers: [String] = ["command down"]) {
        let modStr = modifiers.joined(separator: ", ")
        let script = """
        osascript -e 'tell application "System Events" to key code \(code) using {\(modStr)}' 2>/dev/null || true
        """
        _ = runShell(script)
        Thread.sleep(forTimeInterval: 0.15)
    }

    public func sendText(_ text: String) {
        let script = """
        osascript -e 'tell application "System Events" to keystroke "\(text)"' 2>/dev/null || true
        """
        _ = runShell(script)
        Thread.sleep(forTimeInterval: 0.1)
    }

    public func pressReturn() {
        _ = runShell("osascript -e 'tell application \"System Events\" to key code 36' 2>/dev/null || true")
        Thread.sleep(forTimeInterval: 0.15)
    }

    public func rightClick(atPoint point: (Int, Int) = (300, 300)) {
        _ = runShell("""
        osascript -e '
        tell application "System Events"
            click at {\(point.0), \(point.1)}
        end tell' 2>/dev/null || true
        """)
    }

    public func getWindowNames() -> [String] {
        let res = runShell("""
        osascript -e 'tell application "System Events" to get name of windows of process "HoloBrowser"' 2>/dev/null || echo "Holo Browser"
        """)
        return res.components(separatedBy: ", ")
    }

    public func corruptSessionData() {
        let fm = FileManager.default
        let sessionFile = "\(appSupportDir)/session.json"
        let corruptedJson = "{ invalid_json_structure: true, corrupted: "
        try? fm.createDirectory(atPath: appSupportDir, withIntermediateDirectories: true)
        try? corruptedJson.write(toFile: sessionFile, atomically: true, encoding: .utf8)
    }

    public func forceRendererCrash() {
        // Simulates WebKit process termination or memory exception injection
        _ = runShell("pkill -9 -f 'com.apple.WebKit.WebContent' 2>/dev/null || true")
    }
}
