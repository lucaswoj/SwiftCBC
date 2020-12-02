import XCTest
@testable import SwiftCBC

final class ModelTests: XCTestCase {
    func testConstantConstraint() {
        let model = Model()
        let a = model.variable("a", .integer)
        model.constraint(a == 17)

        XCTAssertEqual(model.bestSolution().variables, [a: 17])
    }

    func testAdditionConstraint() {
        let model = Model()
        let a = model.variable("a", .integer, upperBound: 10)
        let b = model.variable("b", .integer)
        model.constraint(a + b == 17)

        XCTAssertEqual(model.bestSolution().variables, [a: 10, b: 7])
    }

    func testMultiplicationConstraint() {
        let model = Model()
        let a = model.variable("a", .integer)
        model.constraint(2 * a == 20)

        XCTAssertEqual(model.bestSolution().variables, [a: 10])
    }

    func testSpecialOrderedSet() {
        let model = Model()
        let a = model.variable("a", .integer, upperBound: 10)
        let b = model.variable("b", .integer)
        model.constraint(a + b == 17)
        model.specialOrderedSet1([a, b])

        XCTAssertEqual(model.bestSolution().variables, [a: 0, b: 17])
    }

    func testObjectiveMaximize() {
        let model = Model()
        let a = model.variable("a", .integer, lowerBound: 0, upperBound: 10)
        let b = model.variable("b", .integer)
        model.constraint(a + b == 17)
        model.objective(.maximize(b))

        XCTAssertEqual(model.bestSolution().variables, [a: 0, b: 17])
    }

    func testWordProblem1() {
        // Martin is four times as old as his brother Luther at present. After
        // 10 years he will be twice the age of his brother. Find their present
        // ages.
        let model = Model()
        let martin = model.variable("martin", .integer)
        let luther = model.variable("luter", .integer)
        model.constraint(martin == 4 * luther)
        model.constraint(martin + 10 == 2 * (luther + 10))
        XCTAssertEqual(model.bestSolution().variables, [martin: 20, luther: 5])
    }

    func testWordProblem2() {
        // Five years ago, John’s age was half of the age he will be in 8 years.
        // How old is he now?
        let model = Model()
        let john = model.variable("john", .integer)
        model.constraint(john - 5 == 0.5 * (john + 8))
        XCTAssertEqual(model.bestSolution().variables, [john: 18])
    }

    func testWordProblem3() {
        // John is twice as old as his friend Peter. Peter is 5 years older
        // than Alice. In 5 years, John will be three times as old as Alice.
        // How old is Peter now?
        let model = Model()
        let john = model.variable("john", .integer)
        let peter = model.variable("john", .integer)
        let alice = model.variable("john", .integer)
        model.constraint(john == 2 * peter)
        model.constraint(peter == 5 + alice)
        model.constraint(john + 5 == 3 * (alice + 5))
        XCTAssertEqual(model.bestSolution().variables![peter], 5)
    }

    static var allTests = [
        ("testConstantConstraint"),
    ]
}
