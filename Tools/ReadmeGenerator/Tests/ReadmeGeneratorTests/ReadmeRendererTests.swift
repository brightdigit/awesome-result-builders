import Foundation
import Testing

@testable import ReadmeGenerator

internal struct ReadmeRendererTests {
  private let catalogYAML = """
    categories:
      - id: media
        name: Media & Documents
      - id: empty
        name: Empty
    projects:
      - name: zeta
        url: https://github.com/example/zeta
        description: Sorted last
        category: media
      - name: Alpha
        url: https://github.com/example/alpha
        description: Sorted first.
        category: media
    resources:
      - name: Talks
        items:
          - title: A Talk
            url: https://example.com/talk
    """

  private let metadataJSON = """
    {"stargazers_count": 42, "pushed_at": "2026-09-01T12:00:00Z", "archived": true}
    """

  private let renderer = ReadmeRenderer(
    header: MarkdownTemplate(markdown: "# Title\n\n```swift\n# not a heading\n```"),
    footer: MarkdownTemplate(markdown: "## Contributing\n\nWelcome.")
  )

  @Test internal func rendersContentsForNonEmptySections() throws {
    let readme = renderer.render(try Catalog(yaml: catalogYAML))
    #expect(readme.contains("- [Media & Documents](#media--documents)"))
    #expect(readme.contains("  - [Talks](#talks)"))
    #expect(readme.contains("- [Contributing](#contributing)"))
    #expect(!readme.contains("Empty"))
  }

  @Test internal func ignoresHeadingsInCodeBlocks() {
    #expect(renderer.header.headings == [TemplateHeading(level: 1, text: "Title")])
  }

  @Test internal func sortsProjectsIgnoringCase() throws {
    let readme = renderer.render(try Catalog(yaml: catalogYAML))
    let alpha = try #require(readme.range(of: "- [Alpha]"))
    let zeta = try #require(readme.range(of: "- [zeta]"))
    #expect(alpha.lowerBound < zeta.lowerBound)
    #expect(readme.contains("- Sorted last."))
  }

  @Test internal func appendsRepositoryMetadata() throws {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    var renderer = renderer
    renderer.metadata = [
      "https://github.com/example/alpha": try decoder.decode(
        RepositoryMetadata.self,
        from: Data(metadataJSON.utf8)
      )
    ]
    let readme = renderer.render(try Catalog(yaml: catalogYAML))
    #expect(readme.contains("Sorted first. ★ 42 · updated Sep 2026 · **archived**"))
  }
}
