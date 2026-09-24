import Foundation

/// Produces heading anchors the way GitHub does when it renders Markdown.
///
/// GitHub lowercases the heading, drops punctuation and symbols, and turns
/// spaces into hyphens, so "Media & Documents" becomes `media--documents`.
/// Repeated headings get `-1`, `-2`, … suffixes in document order, which is why
/// every heading on the page must be passed through the same generator.
struct AnchorGenerator {
  private var occurrences: [String: Int] = [:]

  static func slug(for heading: String) -> String {
    var slug = ""
    for character in heading.lowercased() {
      if character.isLetter || character.isNumber || character == "-" || character == "_" {
        slug.append(character)
      } else if character == " " {
        slug.append("-")
      }
    }
    return slug
  }

  /// Returns the anchor for the next heading with this text.
  mutating func anchor(for heading: String) -> String {
    let slug = Self.slug(for: heading)
    let count = occurrences[slug, default: 0]
    occurrences[slug] = count + 1
    return count == 0 ? slug : "\(slug)-\(count)"
  }
}

/// A Markdown ATX heading (`## Title`) found in a template.
struct MarkdownHeading: Equatable {
  let level: Int
  let text: String

  /// The headings in `markdown`, in order, skipping fenced code blocks.
  static func headings(in markdown: String) -> [MarkdownHeading] {
    var headings: [MarkdownHeading] = []
    var fence: Substring?
    for rawLine in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = rawLine.drop { $0 == " " }
      if let openFence = fence {
        if line.hasPrefix(openFence) {
          fence = nil
        }
        continue
      }
      if line.hasPrefix("```") || line.hasPrefix("~~~") {
        fence = line.prefix(3)
        continue
      }
      let level = line.prefix { $0 == "#" }.count
      guard (1...6).contains(level), line.dropFirst(level).first == " " else {
        continue
      }
      var text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
      // Optional closing sequence: "## Title ##"
      while text.hasSuffix("#") {
        text.removeLast()
      }
      headings.append(MarkdownHeading(level: level, text: text.trimmingCharacters(in: .whitespaces)))
    }
    return headings
  }
}
