import XCTest
@testable import SwiftCBC

final class SwiftCBCTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftCBC().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
