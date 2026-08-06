import Foundation

public final class TestRunner {
    private var results: [TestCaseResult] = []
    private var bugs: [BugReport] = []
    private var warningsCount: Int = 0

    public let appController = AppController.shared
    public let localServer = LocalServer()
    public let visualComparer = VisualComparer()
    public let reportGenerator = ReportGenerator()

    public init() {}

    public func runTest(
        id: String,
        name: String,
        category: TestCategory,
        expected: String,
        possibleFiles: [String],
        severity: Severity = .medium,
        block: () throws -> (passed: Bool, details: String, warning: String?)
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        var passed = false
        var details = ""
        var warningText: String? = nil
        var failureReason: String? = nil
        var screenshotPath: String? = nil

        do {
            let res = try block()
            passed = res.passed
            details = res.details
            warningText = res.warning
            if warningText != nil {
                warningsCount += 1
            }
        } catch {
            passed = false
            details = "Exception thrown during test execution: \(error.localizedDescription)"
            failureReason = details
        }

        let duration = CFAbsoluteTimeGetCurrent() - startTime

        if !passed {
            let shotName = "failure_\(id.replacingOccurrences(of: ".", with: "_"))"
            screenshotPath = visualComparer.captureScreenshot(name: shotName)

            let bug = BugReport(
                testName: name,
                expected: expected,
                actual: details,
                screenshot: screenshotPath ?? "screenshots/\(shotName).png",
                likelyCause: failureReason ?? details,
                possibleFiles: possibleFiles,
                severity: severity
            )
            bugs.append(bug)
        }

        let result = TestCaseResult(
            id: id,
            name: name,
            category: category,
            passed: passed,
            durationSeconds: duration,
            details: details,
            warning: warningText,
            screenshotPath: screenshotPath,
            failureReason: failureReason
        )
        results.append(result)

        let statusSymbol = passed ? "✅" : "❌"
        print("\(statusSymbol) [\(category.rawValue)] \(name) (\(String(format: "%.3f", duration))s) - \(details)")
    }

    public func getResults() -> [TestCaseResult] { return results }
    public func getBugs() -> [BugReport] { return bugs }
    public func getWarningsCount() -> Int { return warningsCount }
}
