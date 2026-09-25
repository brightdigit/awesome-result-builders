import Yams

@testable import ReadmeGenerator

extension Catalog {
  /// Decodes a catalog from an inline YAML fixture.
  internal static func decode(_ yaml: String) throws -> Catalog {
    try YAMLDecoder().decode(Catalog.self, from: yaml)
  }
}
