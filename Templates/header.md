# Awesome Result Builders

> A curated list of Swift libraries and tools built around result builder DSLs.

[Result builders](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0289-result-builders.md) arrived in Swift 5.4 and are the feature behind SwiftUI's `@ViewBuilder`. A type marked `@resultBuilder` tells the compiler how to combine the statements in a closure (plain expressions, `if`/`else`, `switch`, and `for` loops) into a single value. That lets a library offer a declarative, type-checked DSL that still reads like ordinary Swift:

```swift
@resultBuilder
enum ListBuilder {
  static func buildBlock(_ items: String...) -> [String] { items }
}

func list(@ListBuilder _ content: () -> [String]) -> [String] { content() }

let fruits = list {
  "Apple"
  "Banana"
}
// ["Apple", "Banana"]
```

This list collects projects where a result builder is a primary part of the API, from generating code and packages to documents, music, and 3D models.
