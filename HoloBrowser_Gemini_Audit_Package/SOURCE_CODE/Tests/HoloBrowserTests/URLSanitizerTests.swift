import XCTest
@testable import HoloBrowserCore

final class URLSanitizerTests: XCTestCase {
    
    func testURLWithSchemeLoadsDirectly() {
        let input = "https://apple.com"
        let resolved = URLSanitizer.sanitize(input)
        XCTAssertEqual(resolved.absoluteString, "https://apple.com")
    }
    
    func testDomainWithoutSchemePrependsHTTPS() {
        let input = "apple.com"
        let resolved = URLSanitizer.sanitize(input)
        XCTAssertEqual(resolved.absoluteString, "https://apple.com")
    }
    
    func testSearchQueryRoutesToSearchEngine() {
        let input = "best pizza near me"
        let resolved = URLSanitizer.sanitize(input)
        XCTAssertTrue(resolved.absoluteString.contains("google.com/search"))
        XCTAssertTrue(resolved.absoluteString.contains("best%20pizza%20near%20me"))
    }
    
    func testSubdomainURL() {
        let input = "en.wikipedia.org/wiki/Main_Page"
        let resolved = URLSanitizer.sanitize(input)
        XCTAssertEqual(resolved.absoluteString, "https://en.wikipedia.org/wiki/Main_Page")
    }
}
