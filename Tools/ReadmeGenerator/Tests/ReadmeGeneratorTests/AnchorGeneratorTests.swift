import Testing

@testable import ReadmeGenerator

internal struct AnchorGeneratorTests {
  @Test internal func slugMatchesGitHub() {
    #expect(AnchorGenerator.slug(for: "Media & Documents") == "media--documents")
    #expect(AnchorGenerator.slug(for: "3D & CAD") == "3d--cad")
    #expect(AnchorGenerator.slug(for: "Learning Resources") == "learning-resources")
  }

  @Test internal func repeatedHeadingsGetSuffixes() {
    var anchors = AnchorGenerator()
    #expect(anchors.anchor(for: "Talks") == "talks")
    #expect(anchors.anchor(for: "Talks") == "talks-1")
    #expect(anchors.anchor(for: "Talks") == "talks-2")
  }
}
