import Testing

@testable import ReadmeGenerator

internal struct CatalogValidatorTests {
  private static let unknownCategory = """
    categories:
      - id: tools
        name: Tools
    projects:
      - name: Kit
        url: https://github.com/example/Kit
        description: A kit.
        category: missing
    """

  private static let duplicateURLs = """
    categories:
      - id: tools
        name: Tools
    projects:
      - name: Kit
        url: https://github.com/example/Kit
        description: A kit.
        category: tools
      - name: Kit Again
        url: https://www.github.com/Example/kit.git/
        description: The same kit.
        category: tools
    """

  @Test internal func reportsUnknownCategory() throws {
    let catalog = try Catalog.decode(Self.unknownCategory)
    let error = #expect(throws: GeneratorError.self) {
      try CatalogValidator.validate(catalog)
    }
    #expect(error?.description.contains("unknown category \"missing\"") == true)
  }

  @Test internal func reportsDuplicateURLs() throws {
    let catalog = try Catalog.decode(Self.duplicateURLs)
    let error = #expect(throws: GeneratorError.self) {
      try CatalogValidator.validate(catalog)
    }
    #expect(error?.description.contains("Duplicate URL") == true)
  }

  @Test internal func normalizesEquivalentURLs() {
    let plain = CatalogValidator.normalizedURL("https://github.com/owner/repo")
    let noisy = CatalogValidator.normalizedURL("http://www.GitHub.com/Owner/Repo.git/")
    #expect(plain != nil)
    #expect(plain == noisy)
    #expect(CatalogValidator.normalizedURL("not a url") == nil)
  }
}
