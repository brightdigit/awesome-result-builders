//
//  AnchorGenerator.swift
//  ReadmeGenerator
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

/// Produces heading anchors the way GitHub does when it renders Markdown.
///
/// Repeated headings get `-1`, `-2`, … suffixes in document order, which is why
/// every heading on the page must be passed through the same generator.
internal struct AnchorGenerator: Codable, Equatable, Sendable {
  private var occurrences: [String: Int] = [:]

  /// Returns the anchor for the next heading with this text.
  internal mutating func anchor(for heading: String) -> String {
    let slug = heading.gitHubSlug
    let previousOccurrences = occurrences[slug, default: 0]
    occurrences[slug] = previousOccurrences + 1
    return previousOccurrences > 0 ? "\(slug)-\(previousOccurrences)" : slug
  }
}
