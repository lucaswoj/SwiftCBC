# SwiftCBC

This package provides an idiomatic Swift interface to the [COIN-OR Branch-and-Cut MIP Solver](https://projects.coin-or.org/Cbc) (CBC).

CBC is a [constraint solver](https://en.wikipedia.org/wiki/Constraint_programming), like [Cassowary](https://github.com/compnerd/cassowary), but with support for a few additional types of constraints:

| | SwiftCBC | Cassowary |
|-|-|-|
| linear inequalities | ✔️ | ✔️ |
| discrete domains | ✔️ | |
| [special ordered sets](https://en.wikipedia.org/wiki/Special_ordered_set) | ✔️ | |
| optimization function | ✔️ | |
| constraint strength | | ✔️ |

## Example

The easiest way to understand what a constraint solver can do and introduce the SwiftCBC library is with an example.
Suppose you wanted to use SwiftCBC to solve this word problem:

> John is twice as old as his friend Peter. Peter is 5 years older than Alice. In 5 years, John will be three times as old as Alice. How old is Peter now?

You could convert the word problem into a series of variables and constraints and then let the solver determine everyone's ages

```swift
let solver = Solver()

let john = solver.variable("john", .integer)
let peter = solver.variable("john", .integer)
let alice = solver.variable("john", .integer)

solver.constraint(john == 2 * peter)
solver.constraint(peter == 5 + alice)
solver.constraint(john + 5 == 3 * (alice + 5))

XCTAssertEqual(solver.bestSolution()?[peter], 5)
```

## More Complex Example

If you need to construct constraints programmatically you can use the `Sum` class.

The `Sum` class has one constructor that takes an array of variables and sums them together
```swift
let solver = solver()
let variables = [
  solver.variable("a", .integer, lowerBound: 0, upperBound: 1),
  solver.variable("b", .integer, lowerBound: 0, upperBound: 1),
  solver.variable("c", .integer, lowerBound: 0, upperBound: 1)
]
solver.constraint(Sum(variables) == 3)
```

You can use a `Sum` in conjunction with other expression operators

```swift
let a = variables[0]
let b = variables[1]
let c = variables[2]

5 * Sum(variables) + 2 * c == 10 - Sum(variables)
```

You can assign coefficients to terms in the sum by passing a dictionary instead of an array
```swift
Sum([a: 5, c: 2]) // 5b + 2c
```

## Installation

This package can be installed using the Swift Package Manager.

## Production Readiness

This is alpha quality software. Specific issues that need attention:

 - building CBC from source rather than relying on a separate system library
 - iOS compatibility
 - test coverage
 - documentation
 - GrandDispatch multi-threading support
 
 There are also a number of features supported by CBC without an interface yet
 
  - allowable gap
  - fraction gap
  - percentage gap
  - max seconds
  - max nodes
  - max solutions
  - cutoff
