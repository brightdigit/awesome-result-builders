import Testing

@testable import ReadmeGenerator

internal struct CatalogValidationTests {
  private let unknownCategory = """
    categories:
      - id: tools
        name: Tools
    projects:
      - name: Kit
        url: https://github.com/example/Kit
        description: A kit.
        category: missing
    resources: []
    """

  private let duplicateURLs = """
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
    resources: []
    """

  @Test internal func reportsUnknownCategory() throws {
    let catalog = try Catalog(yaml: unknownCategory)
    let problem =
      "Project \"Kit\" has unknown category \"missing\". Known categories: tools."
    #expect(throws: ReadmeGeneratorError.invalidCatalog(problems: [problem])) {
      try catalog.validate()
    }
  }

  @Test internal func reportsDuplicateURLs() throws {
    let catalog = try Catalog(yaml: duplicateURLs)
    #expect(
      catalog.problems == [
        "Duplicate URL https://github.com/example/Kit is used by "
          + "project \"Kit\" and project \"Kit Again\"."
      ]
    )
  }

  @Test internal func normalizesEquivalentURLs() {
    let plain = NormalizedURL("https://github.com/owner/repo")
    let noisy = NormalizedURL("http://www.GitHub.com/Owner/Repo.git/")
    #expect(plain != nil)
    #expect(plain == noisy)
    #expect(NormalizedURL("not a url") == nil)
  }

  @Test internal func reportsMissingKeysWithTheirPath() {
    let yaml = """
      categories: []
      projects:
        - name: Kit
          url: https://github.com/example/Kit
          category: tools
      resources: []
      """
    #expect(
      throws: ReadmeGeneratorError.invalidData(
        path: "projects.yml",
        reason: "missing required key \"description\" at projects[0]"
      )
    ) {
      try Catalog(yaml: yaml, path: "projects.yml")
    }
  }
}
