import XCTest
@testable import SwiftCBC

final class solverTests: XCTestCase {
    func testConstantConstraint() {
        let solver = Solver()
        let a = solver.variable("a", .integer)
        solver.constraint(a == 17)

        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [a: 17])
    }

    func testAdditionConstraint() {
        let solver = Solver()
        let a = solver.variable("a", .integer, upperBound: 10)
        let b = solver.variable("b", .integer)
        solver.constraint(a + b == 17)

        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [a: 10, b: 7])
    }

    func testMultiplicationConstraint() {
        let solver = Solver()
        let a = solver.variable("a", .integer)
        solver.constraint(2 * a == 20)

        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [a: 10])
    }

    func testSpecialOrderedSet() {
        let solver = Solver()
        let a = solver.variable("a", .integer, upperBound: 10)
        let b = solver.variable("b", .integer)
        solver.constraint(a + b == 17)
        solver.specialOrderedSet1([a, b])

        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [a: 0, b: 17])
    }

    func testObjectiveMaximize() {
        let solver = Solver()
        let a = solver.variable("a", .integer, lowerBound: 0, upperBound: 10)
        let b = solver.variable("b", .integer)
        solver.constraint(a + b == 17)
        solver.objective(.maximize(b))

        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [a: 0, b: 17])
    }

    func testRangeConstraintUpper() {
        let solver = Solver()
        let a = solver.variable("a", .integer)
        solver.constraint((1...10).contains(a))
        solver.objective(.maximize(a))
        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [a: 10])
    }

    func testRangeConstraintLower() {
        let solver = Solver()
        let a = solver.variable("a", .integer)
        solver.constraint((1...10).contains(a))
        solver.objective(.minimize(a))
        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [a: 1])
    }

    func testWordProblem1() {
        // Martin is four times as old as his brother Luther at present. After
        // 10 years he will be twice the age of his brother. Find their present
        // ages.
        let solver = Solver()
        let martin = solver.variable("martin", .integer)
        let luther = solver.variable("luter", .integer)
        solver.constraint(martin == 4 * luther)
        solver.constraint(martin + 10 == 2 * (luther + 10))
        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [martin: 20, luther: 5])
    }

    func testWordProblem2() {
        // Five years ago, John’s age was half of the age he will be in 8 years.
        // How old is he now?
        let solver = Solver()
        let john = solver.variable("john", .integer)
        solver.constraint(john - 5 == 0.5 * (john + 8))
        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables, [john: 18])
    }

    func testWordProblem3() {
        // John is twice as old as his friend Peter. Peter is 5 years older
        // than Alice. In 5 years, John will be three times as old as Alice.
        // How old is Peter now?
        let solver = Solver()
        let john = solver.variable("john", .integer)
        let peter = solver.variable("john", .integer)
        let alice = solver.variable("john", .integer)
        solver.constraint(john == 2 * peter)
        solver.constraint(peter == 5 + alice)
        solver.constraint(john + 5 == 3 * (alice + 5))
        XCTAssertEqual((solver.bestSolution() as? FeasibleSolution)?.variables[peter], 5)
    }

    static var allTests = [
        ("testConstantConstraint"),
    ]
}
