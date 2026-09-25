import Testing

@testable import ReadmeGenerator

internal struct AnchorGeneratorTests {
  @Test internal func slugMatchesGitHub() {
    #expect("Media & Documents".gitHubSlug == "media--documents")
    #expect("3D & CAD".gitHubSlug == "3d--cad")
    #expect("Learning Resources".gitHubSlug == "learning-resources")
  }

  @Test internal func repeatedHeadingsGetSuffixes() {
    var anchors = AnchorGenerator()
    #expect(anchors.anchor(for: "Talks") == "talks")
    #expect(anchors.anchor(for: "Talks") == "talks-1")
    #expect(anchors.anchor(for: "Talks") == "talks-2")
  }
}
