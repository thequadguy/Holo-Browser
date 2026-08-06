import Foundation

public final class LocalServer {
    private var process: Process?
    public let port: Int = 8085
    public let serverDir: String

    public init() {
        let tempDir = NSTemporaryDirectory() + "HoloTestLabServer"
        self.serverDir = tempDir
    }

    public func start() {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: serverDir, withIntermediateDirectories: true)

        // Generate mock html pages
        let sites = ["google", "apple", "github", "reddit", "youtube", "wikipedia", "homepage"]
        for site in sites {
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>\(site.capitalized) - Holo Browser QA Test Page</title>
                <style>
                    body { font-family: -apple-system, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; text-align: center; }
                    h1 { font-size: 32px; color: #38bdf8; }
                    .card { background: #1e293b; border-radius: 12px; padding: 24px; max-width: 600px; margin: 20px auto; border: 1px solid #334155; }
                    a { color: #818cf8; text-decoration: none; font-weight: bold; }
                </style>
            </head>
            <body>
                <div class="card">
                    <h1>Holo TestLab Mock — \(site.capitalized)</h1>
                    <p>Verified test endpoint for Holo Browser E2E suite.</p>
                    <a id="download-pdf" href="/sample.pdf">Download Sample PDF</a><br><br>
                    <a id="download-zip" href="/sample.zip">Download Sample ZIP</a><br><br>
                    <a id="download-img" href="/sample.png">Download Sample Image</a><br><br>
                    <a id="download-vid" href="/sample.mp4">Download Sample Video</a><br><br>
                    <a id="download-txt" href="/sample.txt">Download Sample Text</a>
                </div>
            </body>
            </html>
            """
            try? html.write(toFile: "\(serverDir)/\(site).html", atomically: true, encoding: .utf8)
        }

        // Write index.html
        try? fm.copyItem(atPath: "\(serverDir)/homepage.html", toPath: "\(serverDir)/index.html")

        // Create downloadable files
        try? "Holo Browser Sample PDF Content".write(toFile: "\(serverDir)/sample.pdf", atomically: true, encoding: .utf8)
        try? "Holo Browser Sample ZIP Content".write(toFile: "\(serverDir)/sample.zip", atomically: true, encoding: .utf8)
        try? "Holo Browser Sample Image Content".write(toFile: "\(serverDir)/sample.png", atomically: true, encoding: .utf8)
        try? "Holo Browser Sample Video Content".write(toFile: "\(serverDir)/sample.mp4", atomically: true, encoding: .utf8)
        try? "Holo Browser Sample Text File Content".write(toFile: "\(serverDir)/sample.txt", atomically: true, encoding: .utf8)

        // Kill any existing python server on port 8085
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        killTask.arguments = ["-f", "python3 -m http.server 8085"]
        try? killTask.run()
        killTask.waitUntilExit()

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        task.arguments = ["-m", "http.server", "\(port)", "--directory", serverDir]
        self.process = task
        try? task.run()
        Thread.sleep(forTimeInterval: 0.5)
    }

    public func stop() {
        process?.terminate()
        process = nil
    }

    public func urlFor(_ site: String) -> String {
        return "http://localhost:\(port)/\(site).html"
    }

    public func fileUrlFor(_ filename: String) -> String {
        return "http://localhost:\(port)/\(filename)"
    }
}
