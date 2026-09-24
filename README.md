<!-- This file is generated from data/projects.yml and Templates/ by Tools/ReadmeGenerator. Do not edit it by hand; see CONTRIBUTING.md. -->

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

## Contents

- [Code Generation](#code-generation)
- [Package Management](#package-management)
- [Media & Documents](#media--documents)
- [Music & Audio](#music--audio)
- [3D & CAD](#3d--cad)
- [Learning Resources](#learning-resources)
  - [Official](#official)
  - [Talks](#talks)
- [Contributing](#contributing)

## Code Generation

Build source code, such as Swift syntax trees, from declarative descriptions.

- [SyntaxKit](https://github.com/brightdigit/SyntaxKit) - Generate Swift code programmatically with declarative syntax.

## Package Management

Describe Swift packages and their manifests declaratively.

- [PackageDSL](https://github.com/brightdigit/PackageDSL) - Type-safe, modular DSL for managing your Package.swift file.

## Media & Documents

Create and work with presentations, video projects, and other documents.

- [DeckUI](https://github.com/joshdholtz/DeckUI) - Write presentations in Swift with a SwiftUI-powered result builder DSL.
- [FCPKit](https://github.com/brightdigit/FCPKit) - Swift package for working with Final Cut Pro FCPXML documents.
- [KeynoteKit](https://github.com/brightdigit/KeynoteKit) - Swift package for working with Apple Keynote documents.

## Music & Audio

Compose music and sound with Swift.

- [MusicPlaygournd](https://github.com/1amageek/MusicPlaygournd) - Native macOS live music editor powered by the SwiftMusic DSL.

## 3D & CAD

Model 3D geometry and parts for printing and fabrication.

- [Cadova](https://github.com/tomasf/Cadova) - Swift DSL for parametric 3D modeling.

## Learning Resources

### Official

- [SE-0289: Result Builders](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0289-result-builders.md) - The Swift Evolution proposal that introduced result builders in Swift 5.4.
- [SE-0348: buildPartialBlock for Result Builders](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0348-buildpartialblock.md) - Lets builders combine components pairwise, available since Swift 5.7.
- [The Swift Programming Language: Result Builders](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders) - The language guide's walkthrough of the builder methods and how the compiler applies them.

### Talks

- [Write a DSL in Swift using result builders](https://developer.apple.com/videos/play/wwdc2021/10253/) - WWDC21 session on designing and building a DSL with a result builder.

## Contributing

Contributions are welcome! Please read the [contribution guidelines](CONTRIBUTING.md) first. New entries go in [`data/projects.yml`](data/projects.yml); this README is generated from it, so please don't edit `README.md` directly.
