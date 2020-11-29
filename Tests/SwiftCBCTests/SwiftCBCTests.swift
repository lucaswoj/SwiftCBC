import XCTest
@testable import SwiftCBC

final class SwiftCBCTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        let model = Model()
        let a = model.variable("a", .integer, lowerBound: 0)
        let b = model.variable("b", .integer, lowerBound: 0)
        model.constraint(a + b == 2)
        model.objective(.maximize(a))
        XCTAssertEqual(model.bestSolution(), [a: 2, b: 0])
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
