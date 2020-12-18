import cbc

public class Solver {
    let cbc: UnsafeMutableRawPointer
    public private(set) var variables = [Variable]()
    public private(set) var constraints = [Constraint]()

    var maxSeconds: Double {
        get { Cbc_getMaximumSeconds(cbc) }
        set { Cbc_setMaximumSeconds(cbc, newValue) }
    }

    public init(name: String = "", logLevel: Int32 = 0) {
        self.cbc = Cbc_newModel()
        Cbc_setProblemName(cbc, name)
        Cbc_setLogLevel(cbc, logLevel)
        objective(.ignore)
    }

    public func variable(
        _ type: VariableType,
        lowerBound: Double = -.infinity,
        upperBound: Double = .infinity,
        name: String = ""
    ) -> Variable {
        variable(type, lowerBound...upperBound, name: name)
    }

    public func variable(
        _ type: VariableType,
        _ range: ClosedRange<Double> = (-.infinity...(.infinity)),
        name: String = ""
    ) -> Variable {

        Cbc_addCol(
            cbc,
            name,
            range.lowerBound,
            range.upperBound,
            0, // objective function coefficient (overridden later)
            type == .integer ? 1 : 0, // 1 if variable is integer, 0 otherwise
            0, // row count (overridden later)
            UnsafeMutablePointer<Int32>(nil), // row indicies (overridden later)
            UnsafeMutablePointer<Double>(nil) // row coefficients (overridden later)
        )

        let variable = Variable(index: Int32(variables.count), name: name)
        variables.append(variable)
        return variable
    }

    public func constraint(_ constraint: Constraint, name: String = "") {
        switch constraint {
        case .lessThanOrEqual(let expression):
            self.constraint(expression, "L", name)

        case .greaterThanOrEqual(let expression):
            self.constraint(expression, "G", name)

        case .equal(let expression):
            self.constraint(expression, "E", name)

        case .range(let expression, let lowerBound, let upperBound):
            self.constraint(expression, "E", name)
            Cbc_setRowLower(cbc, Int32(constraints.count), lowerBound)
            Cbc_setRowUpper(cbc, Int32(constraints.count), upperBound)
        }

        constraints.append(constraint)
    }

    private func constraint(_ expression: Expression, _ sense: String, _ name: String) {
        let sum = expression.sum
        let terms = sum.terms.filter { $0.key != nil }

        Cbc_addRow(
            cbc,
            name,
            Int32(terms.count), // variable count
            terms.map { $0.key!.index }, // variable indicies
            terms.map { $0.value }, // variable coefficients
            sense.utf8CString[0], // L if <=, G if >=, E if =
            -1 * (sum.terms[nil] ?? 0) // constant rhs value
        )
    }

    public func objective(_ objective: Objective) {
        switch objective {
        case .maximize(let expression):
            Cbc_setObjSense(cbc, -1)
            self.objective(expression.sum)

        case .minimize(let expressionable):
            Cbc_setObjSense(cbc, 1)
            self.objective(expressionable.sum)

        case .ignore:
            Cbc_setObjSense(cbc, 0)
        }
    }

    private func objective(_ expression: Sum) {
        for variable in variables {
            Cbc_setObjCoeff(cbc, variable.index, 0)
        }

        for (variable, coefficient) in expression.terms {
            if let variable = variable {
                Cbc_setObjCoeff(cbc, variable.index, coefficient)
            }
        }
    }

    public func specialOrderedSet1(_ variables: [Variable]) {
        Cbc_addSOS(
            cbc,
            1, // numRows
            [0, Int32(variables.count)], // rowStarts
            variables.map(\.index), // colIndices
            variables.enumerated().map({_ in 0}), // weights
            1 // type
        )
    }

    public func bestSolution() -> Solution {
        Cbc_solve(cbc)
        if let solutionPointer = Cbc_bestSolution(cbc) {
            return FeasibleSolution(solver: self, solutionPointer: solutionPointer)
        } else {
            return NotFeasibleSolution(solver: self)
        }
    }

    deinit {
        Cbc_deleteModel(cbc)
    }
}

public protocol Solution {
    var solver: Solver { get }
}

public struct FeasibleSolution: Solution {
    public let solver: Solver
    public let variables: [Variable: Double]

    init(solver: Solver, solutionPointer: UnsafeMutablePointer<Double>!) {
        self.solver = solver

        let solutionArray = Array(UnsafeBufferPointer(
            start: solutionPointer!,
            count: solver.variables.count
        ))

        self.variables = solutionArray.enumerated().reduce(into: [:]) {(solution, value) in
            solution[solver.variables[value.0]] = value.1
        }
    }

    public var objectiveValue: Double { Cbc_getObjValue(solver.cbc) }
    public var bestObjectiveValue: Double { Cbc_getBestPossibleObjValue(solver.cbc) }
}

public struct NotFeasibleSolution: Solution {
    public let solver: Solver
}

extension Solution {
    public var iterationCount: Int32 { Cbc_getIterationCount(solver.cbc) }
    public var isContinuousUnbounded: Bool { Cbc_isContinuousUnbounded(solver.cbc) == 1 }
    public var isNodeLimitReached: Bool { Cbc_isNodeLimitReached(solver.cbc) == 1 }
    public var isSecondsLimitReached: Bool { Cbc_isSecondsLimitReached(solver.cbc) == 1 }
    public var isSolutionLimitReached: Bool { Cbc_isSolutionLimitReached(solver.cbc) == 1 }
    public var isInitialSolveAbandoned: Bool { Cbc_isInitialSolveAbandoned(solver.cbc) == 1 }
    public var isInitialSolveProvenOptimal: Bool { Cbc_isInitialSolveProvenOptimal(solver.cbc) == 1 }
    public var isInitialSolveProvenPrimalInfeasible: Bool { Cbc_isInitialSolveProvenOptimal(solver.cbc) == 1 }
    public var nodeCount: Int32 { Cbc_getNodeCount(solver.cbc) }
    public var status: Int32 { Cbc_status(solver.cbc) }
    public var secondaryStatus: Int32 { Cbc_secondaryStatus(solver.cbc) }
    func print() { Cbc_printSolution(solver.cbc) }
}

public struct Variable: Hashable, Expression, CustomDebugStringConvertible {
    let index: Int32
    let name: String

    public init(index: Int32, name: String = "") {
        self.index = index
        self.name = name
    }

    public static func == (lhs: Variable, rhs: Variable) -> Bool {
        lhs.index == rhs.index
    }

    public var sum: Sum {
        Sum([self: 1])
    }

    public var debugDescription: String {
        return name
    }

    public func evaluate(_ solution: FeasibleSolution) -> Double {
        solution.variables[self]!
    }
}

public enum VariableType {
    case integer
    case continuous
}

public struct Sum: Expression, CustomDebugStringConvertible {
    public var debugDescription: String {
        terms.sorted(by: {$0.key?.name ?? "" < $1.key?.name ?? ""}).map { variable, coefficient in
            if let variable = variable {
                if coefficient == 1 {
                    return variable.debugDescription
                } else {
                    return "\(coefficient) * \(variable.debugDescription)"
                }
            } else {
                return "\(coefficient)"
            }
        }.joined(separator: " + ")
    }

    public let terms: [Variable?: Double]

    public init() {
        self.terms = [:]
    }

    public init(_ expressions: [Expression]) {
        self.terms = expressions.reduce([Variable?: Double]()) { terms, expression in
            expression.sum.terms.merging(terms) { $0 + $1 }
        }
    }

    public init(_ terms: [Variable?: Double]) {
        self.terms = terms
    }

    public var sum: Sum {
        self
    }

    public func evaluate(_ solution: FeasibleSolution) -> Double {
        terms.reduce(0) { value, element in
            (element.key?.evaluate(solution) ?? 1) * element.value + value
        }
    }
}

extension Double: Expression {
    public var sum: Sum {
        Sum([nil: self])
    }

    public func evaluate(_ solution: FeasibleSolution) -> Double {
        self
    }
}

public enum Constraint {
    case lessThanOrEqual(Expression)
    case greaterThanOrEqual(Expression)
    case equal(Expression)
    case range(Expression, lowerBound: Double, upperBound: Double)
}

public enum Objective {
    case minimize(Expression)
    case maximize(Expression)
    case ignore
}

public protocol Expression {
    var sum: Sum { get }
    func evaluate(_ solution: FeasibleSolution) -> Double
}

public func * (lhs: Double, rhs: Expression) -> Sum {
    return rhs * lhs
}

public func * (lhs: Expression, rhs: Double) -> Sum {
    return Sum(lhs.sum.terms.mapValues { $0 * rhs })
}

public func / (lhs: Double, rhs: Expression) -> Sum {
    return rhs / lhs
}

public func / (lhs: Expression, rhs: Double) -> Sum {
    return lhs * (1 / rhs)
}

public func + (lhs: Expression, rhs: Expression) -> Sum {
    return Sum([lhs, rhs])
}

public func - (lhs: Expression, rhs: Expression) -> Sum {
    return lhs + -1 * rhs
}

public func <= (lhs: Expression, rhs: Expression) -> Constraint {
    return .lessThanOrEqual(lhs - rhs)
}

public func >= (lhs: Expression, rhs: Expression) -> Constraint {
    return .greaterThanOrEqual(lhs - rhs)
}

public func == (lhs: Expression, rhs: Expression) -> Constraint {
    return .equal(lhs - rhs)
}

public extension ClosedRange where Bound: BinaryFloatingPoint {
    func contains(_ expression: Expression) -> Constraint {
        return .range(expression, lowerBound: Double(lowerBound), upperBound: Double(upperBound))
    }
}

public extension ClosedRange where Bound: BinaryInteger {
    func contains(_ expression: Expression) -> Constraint {
        return .range(expression, lowerBound: Double(lowerBound), upperBound: Double(upperBound))
    }
}
