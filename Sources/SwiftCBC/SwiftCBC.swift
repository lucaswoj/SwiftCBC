import cbc

class Model {
    let model: UnsafeMutableRawPointer
    var variables = [Variable]()

    init(name: String = "") {
        self.model = Cbc_newModel()
        Cbc_setProblemName(model, name)
        Cbc_setLogLevel(model, 0)
        objective(.ignore)
    }

    func variable(
        _ name: String,
        _ type: VariableType,
        lowerBound: Double = -.infinity,
        upperBound: Double = .infinity
    ) -> Variable {

        Cbc_addCol(
            model,
            name,
            lowerBound, // lower bound
            upperBound, // upper bound
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

    func constraint(_ constraint: Constraint, name: String = "") {
        switch constraint {
        case .lessThanOrEqual(let expression):
            self.constraint(expression, "L", name)

        case .greaterThanOrEqual(let expression):
            self.constraint(expression, "G", name)

        case .equal(let expression):
            self.constraint(expression, "E", name)
        }
    }

    private func constraint(_ expression: Expression, _ sense: String, _ name: String) {
        let additionExpression = expression.sum
        let coefficients = additionExpression.terms.filter { $0.key != nil }
        let constant = -1 * (additionExpression.terms[nil] ?? 0)

        Cbc_addRow(
            model,
            name,
            Int32(coefficients.count), // variable count
            coefficients.map { $0.key!.index }, // variable indicies
            coefficients.map { $0.value }, // variable coefficients
            sense.utf8CString[0], // L if <=, G if >=, E if =, R if ranged and N if free
            constant // constant rhs value
        )
    }

    func objective(_ objective: Objective) {
        switch objective {
        case .maximize(let expression):
            Cbc_setObjSense(model, -1)
            self.objective(expression.sum)

        case .minimize(let expressionable):
            Cbc_setObjSense(model, 1)
            self.objective(expressionable.sum)

        case .ignore:
            Cbc_setObjSense(model, 0)
        }
    }

    private func objective(_ expression: Sum) {
        for variable in variables {
            Cbc_setObjCoeff(model, variable.index, 0)
        }

        for (variable, coefficient) in expression.terms {
            if let variable = variable {
                Cbc_setObjCoeff(model, variable.index, coefficient)
            }
        }
    }

    func specialOrderedSet1(_ variables: [Variable]) {
        Cbc_addSOS(
            model,
            1, // numRows
            [0, Int32(variables.count)], // rowStarts
            variables.map(\.index), // colIndices
            variables.enumerated().map({_ in 0}), // weights
            1 // type
        )
    }

    func bestSolution() -> Solution? {
        Cbc_solve(model)
        return solution(Cbc_bestSolution(model))
    }

    func solutions() -> SolutionsIterable {
        Cbc_solve(model)
        return SolutionsIterable(model: self)
    }

    func solution(_ solutionPointer: UnsafePointer<Double>?) -> Solution? {
        guard solutionPointer != nil else { return nil }

        let solutionArray = Array(UnsafeBufferPointer(
            start: solutionPointer,
            count: variables.count
        ))

        return solutionArray.enumerated().reduce(into: [:]) { (solution, value) in
            solution[variables[value.0]] = value.1
        }
    }

    deinit {
        Cbc_deleteModel(model)
    }

    // TODO support allowable gap
    // TODO support fraction gap
    // TODO support percentage gap
    // TODO support max seconds
    // TODO support max nodes
    // TODO support max solutions
    // TODO support customizable log level
    // TODO support cutoff
}

struct SolutionsIterable: Sequence {
    let model: Model

    func makeIterator() -> SolutionsIterator {
        return SolutionsIterator(model)
    }
}

struct SolutionsIterator: IteratorProtocol {
    typealias Element = Solution

    var index: Int32
    let count: Int32
    let model: Model

    init(_ model: Model) {
        self.index = 0
        self.count = Cbc_numberSavedSolutions(model.model)
        self.model = model
    }

    mutating func next() -> Solution? {
        guard index < count else { return nil }

        let solution = model.solution(Cbc_savedSolution(model.model, index))
        index += 1
        return solution
    }
}

typealias Solution = [Variable: Double]

struct Variable: Hashable, Expression, CustomDebugStringConvertible {
    let index: Int32
    let name: String

    init(index: Int32, name: String) {
        self.index = index
        self.name = name
    }

    static func == (lhs: Variable, rhs: Variable) -> Bool {
        lhs.index == rhs.index
    }

    var sum: Sum {
        Sum([self: 1])
    }

    var debugDescription: String {
        return name
    }
}

enum VariableType {
    case integer
    case double
}

struct Sum: Expression, CustomDebugStringConvertible {
    var debugDescription: String {
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

    let terms: [Variable?: Double]

    init() {
        self.terms = [:]
    }

    init(_ variables: [Variable]) {
        self.terms = variables.reduce(into: [:]) { $0[$1] = 1 }
    }

    init(_ terms: [Variable?: Double]) {
        self.terms = terms
    }

    var sum: Sum {
        self
    }
}

extension Double: Expression {
    var sum: Sum {
        Sum([nil: self])
    }
}

enum Constraint {
    case lessThanOrEqual(Expression)
    case greaterThanOrEqual(Expression)
    case equal(Expression)
    // TODO add ranged and free types
}

enum Objective {
    case minimize(Expression)
    case maximize(Expression)
    case ignore
}

protocol Expression {
    var sum: Sum { get }
}

func * (lhs: Double, rhs: Expression) -> Sum {
    return rhs * lhs
}

func * (lhsExpression: Expression, rhs: Double) -> Sum {
    let lhs = lhsExpression.sum
    return Sum(lhs.terms.mapValues { $0 * rhs })
}

func + (lhs: Expression, rhs: Expression) -> Sum {
    return Sum(lhs.sum.terms.merging(rhs.sum.terms) { $0 + $1 })
}

func - (lhs: Expression, rhs: Expression) -> Sum {
    return lhs + -1 * rhs
}

func <= (lhs: Expression, rhs: Expression) -> Constraint {
    return .lessThanOrEqual(lhs - rhs)
}

func >= (lhs: Expression, rhs: Expression) -> Constraint {
    return .greaterThanOrEqual(lhs - rhs)
}

func == (lhs: Expression, rhs: Expression) -> Constraint {
    return .equal(lhs - rhs)
}
