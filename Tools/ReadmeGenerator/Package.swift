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
  // ConfigKeyKit requires macOS 15.
  platforms: [.macOS(.v15)],
  products: [
    .executable(name: "generate-readme", targets: ["generate-readme"]),
    .library(name: "ReadmeGenerator", targets: ["ReadmeGenerator"]),
  ],
  dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.0"),
    .package(
      url: "https://github.com/apple/swift-configuration.git",
      from: "1.2.0",
      traits: [.defaults, "CommandLineArguments"]
    ),
    .package(url: "https://github.com/brightdigit/ConfigKeyKit.git", exact: "1.0.0-beta.3"),
    .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.9.0"),
    .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.36.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.100.0"),
  ],
  targets: [
    .executableTarget(
      name: "generate-readme",
      dependencies: [
        "ReadmeGenerator",
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
      ],
      swiftSettings: swiftSettings
    ),
    .target(
      name: "ReadmeGenerator",
      dependencies: [
        .product(name: "Yams", package: "Yams"),
        .product(name: "Configuration", package: "swift-configuration"),
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
        .product(name: "Markdown", package: "swift-markdown"),
        .product(name: "AsyncHTTPClient", package: "async-http-client"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOFoundationCompat", package: "swift-nio"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "ReadmeGeneratorTests",
      dependencies: [
        "ReadmeGenerator",
        .product(name: "Configuration", package: "swift-configuration"),
      ],
      swiftSettings: swiftSettings
    ),
  ]
)
