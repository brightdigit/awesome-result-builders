// swift-tools-version: 6.4
import PackageDescription

let swiftSettings: [SwiftSetting] = [
  // SE-0409: Access-level modifiers on import declarations
  .enableUpcomingFeature("InternalImportsByDefault"),
  // SE-0461: Run nonisolated async functions on the caller's actor by default
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  // SE-0458: Opt-in strict memory safety checking
  .strictMemorySafety(),
]

let package = Package(
  name: "ReadmeGenerator",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "generate-readme", targets: ["ReadmeGenerator"])
  ],
  dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
  ],
  targets: [
    .executableTarget(
      name: "ReadmeGenerator",
      dependencies: [
        .product(name: "Yams", package: "Yams"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "ReadmeGeneratorTests",
      dependencies: [
        "ReadmeGenerator",
        .product(name: "Yams", package: "Yams"),
      ],
      swiftSettings: swiftSettings
    ),
  ]
)
