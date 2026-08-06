import Foundation

public final class ReportGenerator {
    public let baseDir: String
    public let screenshotsDir: String
    public let logsDir: String

    public init(baseDir: String = "/Users/jake/Desktop/Holo Browser/HoloBrowserTestLab") {
        self.baseDir = baseDir
        self.screenshotsDir = "\(baseDir)/screenshots"
        self.logsDir = "\(baseDir)/logs"

        let fm = FileManager.default
        try? fm.createDirectory(atPath: baseDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: screenshotsDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: logsDir, withIntermediateDirectories: true)
    }

    public func generateReports(
        results: [TestCaseResult],
        bugs: [BugReport],
        metrics: PerformanceMetrics,
        scorecard: FinalScorecard
    ) {
        writeMarkdownReport(results: results, bugs: bugs, metrics: metrics, scorecard: scorecard)
        writeHTMLReport(results: results, bugs: bugs, metrics: metrics, scorecard: scorecard)
        writeBugsFound(bugs: bugs)
        writePerformanceJSON(metrics: metrics)
    }

    private func writeMarkdownReport(
        results: [TestCaseResult],
        bugs: [BugReport],
        metrics: PerformanceMetrics,
        scorecard: FinalScorecard
    ) {
        var md = """
        # 🧪 HOLO BROWSER TESTLAB — COMPREHENSIVE AUTOMATED QA REPORT

        **Date**: \(ISO8601DateFormatter().string(from: Date()))  
        **Target App**: Holo Browser.app  
        **Framework**: HoloBrowserTestLab Standalone Suite  

        ---

        ## 📊 FINAL SCORECARD

        | Metric | Value |
        | :--- | :--- |
        | **Tests Passed** | `\(scorecard.testsPassed)` / `\(scorecard.totalTests)` |
        | **Tests Failed** | `\(scorecard.testsFailed)` |
        | **Warnings** | `\(scorecard.warnings)` |
        | **Coverage %** | `\(String(format: "%.1f", scorecard.coveragePercent))%` |
        | **Critical Bugs** | `\(scorecard.criticalBugs)` |
        | **Beta Ready** | **\(scorecard.betaReady ? "YES ✅" : "NO ❌")** |

        ---

        ## ⚡ PERFORMANCE SUMMARY

        - **Launch Time**: `\(String(format: "%.1f", metrics.launchTimeMs))` ms
        - **Page Load Latency**: `\(String(format: "%.1f", metrics.pageLoadMs))` ms
        - **Tab Switch Latency**: `\(String(format: "%.1f", metrics.tabSwitchMs))` ms
        - **RAM Usage**: `\(String(format: "%.1f", metrics.ramUsageMB))` MB
        - **CPU Utilization**: `\(String(format: "%.2f", metrics.cpuUsagePercent))` %
        - **UI Frame Rate**: `\(String(format: "%.1f", metrics.estimatedFPS))` FPS

        ---

        ## 📋 DETAILED TEST RESULTS BY CATEGORY

        """

        let categories = TestCategory.allCases
        for cat in categories {
            let catResults = results.filter { $0.category == cat }
            md += "\n### \(cat.rawValue)\n\n"
            md += "| Status | Test ID | Test Name | Duration (s) | Details |\n"
            md += "| :---: | :--- | :--- | :---: | :--- |\n"
            for r in catResults {
                let badge = r.passed ? "✅ PASS" : "❌ FAIL"
                md += "| \(badge) | `\(r.id)` | \(r.name) | \(String(format: "%.3f", r.durationSeconds)) | \(r.details) |\n"
            }
        }

        if !bugs.isEmpty {
            md += "\n---\n\n## 🐞 BUGS DETECTED (\(bugs.count))\n\n"
            for (idx, b) in bugs.enumerated() {
                md += "### Bug #\(idx + 1): \(b.testName) [Severity: \(b.severity.rawValue)]\n"
                md += "- **Expected**: \(b.expected)\n"
                md += "- **Actual**: \(b.actual)\n"
                md += "- **Likely Cause**: \(b.likelyCause)\n"
                md += "- **Possible Files**: \(b.possibleFiles.joined(separator: ", "))\n"
                md += "- **Screenshot**: [View Screenshot](\(b.screenshot))\n\n"
            }
        }

        try? md.write(toFile: "\(baseDir)/TEST_RESULTS.md", atomically: true, encoding: .utf8)
    }

    private func writeHTMLReport(
        results: [TestCaseResult],
        bugs: [BugReport],
        metrics: PerformanceMetrics,
        scorecard: FinalScorecard
    ) {
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Holo Browser TESTLAB — Automated Test Report</title>
            <style>
                :root {
                    --bg: #0b0f19;
                    --card: #151c2c;
                    --border: #232d42;
                    --accent: #38bdf8;
                    --text: #f1f5f9;
                    --muted: #94a3b8;
                    --pass: #10b981;
                    --fail: #ef4444;
                    --warn: #f59e0b;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    background: var(--bg);
                    color: var(--text);
                    margin: 0;
                    padding: 30px;
                }
                .container { max-width: 1200px; margin: 0 auto; }
                header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); padding-bottom: 20px; margin-bottom: 30px; }
                h1 { margin: 0; color: var(--accent); font-size: 28px; }
                .subtitle { color: var(--muted); margin-top: 4px; font-size: 14px; }
                .badge { padding: 6px 14px; border-radius: 20px; font-weight: bold; font-size: 14px; }
                .badge-yes { background: rgba(16, 185, 129, 0.2); color: var(--pass); border: 1px solid var(--pass); }
                .badge-no { background: rgba(239, 68, 68, 0.2); color: var(--fail); border: 1px solid var(--fail); }
                
                .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-bottom: 30px; }
                .card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 20px; text-align: center; }
                .card .val { font-size: 32px; font-weight: bold; margin-top: 8px; }
                .card .label { color: var(--muted); font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }

                .table-section { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin-bottom: 30px; }
                h2 { margin-top: 0; font-size: 20px; border-bottom: 1px solid var(--border); padding-bottom: 10px; }
                table { width: 100%; border-collapse: collapse; margin-top: 15px; }
                th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid var(--border); }
                th { color: var(--muted); font-size: 12px; text-transform: uppercase; }
                .status-pass { color: var(--pass); font-weight: bold; }
                .status-fail { color: var(--fail); font-weight: bold; }
                
                .bug-card { background: rgba(239, 68, 68, 0.05); border: 1px solid rgba(239, 68, 68, 0.3); border-radius: 8px; padding: 16px; margin-bottom: 15px; }
                .bug-title { font-weight: bold; color: var(--fail); font-size: 16px; margin-bottom: 8px; }
                .bug-detail { color: var(--text); font-size: 14px; margin: 4px 0; }
                code { background: #0f172a; padding: 2px 6px; border-radius: 4px; color: var(--accent); font-family: monospace; }
            </style>
        </head>
        <body>
            <div class="container">
                <header>
                    <div>
                        <h1>🧪 Holo Browser TESTLAB</h1>
                        <div class="subtitle">Automated Regression & Quality Assurance Dashboard</div>
                    </div>
                    <div>
                        <span class="badge \(scorecard.betaReady ? "badge-yes" : "badge-no")">
                            BETA READY: \(scorecard.betaReady ? "YES" : "NO")
                        </span>
                    </div>
                </header>

                <div class="grid">
                    <div class="card">
                        <div class="label">Tests Passed</div>
                        <div class="val" style="color: var(--pass)">\(scorecard.testsPassed) / \(scorecard.totalTests)</div>
                    </div>
                    <div class="card">
                        <div class="label">Tests Failed</div>
                        <div class="val" style="color: \(scorecard.testsFailed > 0 ? "var(--fail)" : "var(--pass)")">\(scorecard.testsFailed)</div>
                    </div>
                    <div class="card">
                        <div class="label">Coverage %</div>
                        <div class="val" style="color: var(--accent)">\(String(format: "%.1f", scorecard.coveragePercent))%</div>
                    </div>
                    <div class="card">
                        <div class="label">Launch Time</div>
                        <div class="val">\(String(format: "%.0f", metrics.launchTimeMs)) ms</div>
                    </div>
                    <div class="card">
                        <div class="label">RAM Usage</div>
                        <div class="val">\(String(format: "%.1f", metrics.ramUsageMB)) MB</div>
                    </div>
                </div>

                <div class="table-section">
                    <h2>📊 Test Category Breakdown</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>Status</th>
                                <th>Category</th>
                                <th>Test Name</th>
                                <th>Duration</th>
                                <th>Details</th>
                            </tr>
                        </thead>
                        <tbody>
        """

        for r in results {
            let statusClass = r.passed ? "status-pass" : "status-fail"
            let statusText = r.passed ? "PASS" : "FAIL"
            html += """
                            <tr>
                                <td class="\(statusClass)">\(statusText)</td>
                                <td><code>\(r.category.rawValue)</code></td>
                                <td><strong>\(r.name)</strong></td>
                                <td>\(String(format: "%.3f", r.durationSeconds)) s</td>
                                <td>\(r.details)</td>
                            </tr>
            """
        }

        html += """
                        </tbody>
                    </table>
                </div>
        """

        if !bugs.isEmpty {
            html += """
                <div class="table-section">
                    <h2>🐞 Detailed Bug Reports (\(bugs.count))</h2>
            """
            for b in bugs {
                html += """
                    <div class="bug-card">
                        <div class="bug-title">[\(b.severity.rawValue.uppercased())] \(b.testName)</div>
                        <div class="bug-detail"><strong>Expected:</strong> \(b.expected)</div>
                        <div class="bug-detail"><strong>Actual:</strong> \(b.actual)</div>
                        <div class="bug-detail"><strong>Likely Cause:</strong> \(b.likelyCause)</div>
                        <div class="bug-detail"><strong>Possible Files:</strong> <code>\(b.possibleFiles.joined(separator: ", "))</code></div>
                    </div>
                """
            }
            html += "</div>"
        }

        html += """
            </div>
        </body>
        </html>
        """

        try? html.write(toFile: "\(baseDir)/TEST_RESULTS.html", atomically: true, encoding: .utf8)
    }

    private func writeBugsFound(bugs: [BugReport]) {
        var md = "# 🐞 BUGS DETECTED AUDIT REPORT\n\n"
        if bugs.isEmpty {
            md += "✅ **No Bugs Found! All automated test assertions passed cleanly.**\n"
        } else {
            md += "Total Failures Detected: \(bugs.count)\n\n"
            for (idx, b) in bugs.enumerated() {
                md += "## Bug #\(idx + 1): \(b.testName)\n"
                md += "- **Severity**: \(b.severity.rawValue)\n"
                md += "- **Expected**: \(b.expected)\n"
                md += "- **Actual**: \(b.actual)\n"
                md += "- **Screenshot**: \(b.screenshot)\n"
                md += "- **Likely Cause**: \(b.likelyCause)\n"
                md += "- **Possible Files**: \(b.possibleFiles.joined(separator: ", "))\n\n"
            }
        }
        try? md.write(toFile: "\(baseDir)/bugs_found.md", atomically: true, encoding: .utf8)
    }

    private func writePerformanceJSON(metrics: PerformanceMetrics) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(metrics) {
            try? data.write(to: URL(fileURLWithPath: "\(baseDir)/performance.json"))
        }
    }
}
