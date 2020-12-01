# SwiftCBC

This package provides an idiomatic Swift interface to the [COIN-OR Branch-and-Cut MIP Solver](https://projects.coin-or.org/Cbc) (CBC).

CBC is a [constraint solver](https://en.wikipedia.org/wiki/Constraint_programming), like [Cassowary](https://github.com/compnerd/cassowary), but with support for a few additional types of constraints:

| | SwiftCBC | Cassowary |
|-|-|-|
| linear inequalities | ✔️ | ✔️ |
| discrete domains | ✔️ | |
| [special ordered sets](https://en.wikipedia.org/wiki/Special_ordered_set) | ✔️ | |

## Example

The easiest way to understand what a constraint solver can do and introduce the SwiftCBC library is with an example.
Suppose you wanted to use SwiftCBC to solve this word problem:

> John is twice as old as his friend Peter. Peter is 5 years older than Alice. In 5 years, John will be three times as old as Alice. How old is Peter now?

You could convert the word problem into a series of variables and constraints and then let the solver determine everyone's ages

```swift
let model = Model()

let john = model.variable("john", .integer)
let peter = model.variable("john", .integer)
let alice = model.variable("john", .integer)

model.constraint(john == 2 * peter)
model.constraint(peter == 5 + alice)
model.constraint(john + 5 == 3 * (alice + 5))

XCTAssertEqual(model.bestSolution()?[peter], 5)
```

## More Complex Example

If you need a more programmatic way to construct constraints you can use the `Sum` class.

The `Sum` class has one constructor that takes an array of variables and sums them together
```swift
let model = Model()
let variables = (0..<50).map {
  model.variable("v\($0)", .integer, lowerBound: 0, upperBound: 1)
}
model.constraint(Sum(variables) == 50)
```

You can use a `Sum` in conjunction with other expression operators

```swift
5 * Sum(variables) + 2 * variables[2] == 10 - Sum(variables)
```

You can assign coefficients to individual terms in the sum by passing a dictionary instead of an array
```swift
Sum([variables[1]: 5, variables[2]: 2])
```

## Installation

This package can be installed using the Swift Package Manager.

## Production Readiness

This is alpha quality software. Specific issues that need attention:

 - building CBC from source rather than relying on a separate system library
 - test coverage
 - documentation
