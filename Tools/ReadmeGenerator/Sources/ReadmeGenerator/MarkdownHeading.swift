//
//  MarkdownHeading.swift
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

import Foundation

/// A Markdown ATX heading (`## Title`) found in a template.
internal struct MarkdownHeading {
  internal let level: Int
  internal let text: String

  /// Parses `line` as an ATX heading, or returns `nil` if it isn't one.
  internal init?(line: Substring) {
    let level = line.prefix { $0 == "#" }.count
    guard (1...6).contains(level), line.dropFirst(level).first == " " else {
      return nil
    }
    var text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
    // Optional closing sequence: "## Title ##"
    while text.hasSuffix("#") {
      text.removeLast()
    }
    self.level = level
    self.text = text.trimmingCharacters(in: .whitespaces)
  }

  /// The headings in `markdown`, in order, skipping fenced code blocks.
  internal static func headings(in markdown: String) -> [MarkdownHeading] {
    var headings: [MarkdownHeading] = []
    var fence: Substring?
    for rawLine in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = rawLine.drop { $0 == " " }
      if let openFence = fence {
        fence = line.hasPrefix(openFence) ? nil : openFence
      } else if line.hasPrefix("```") || line.hasPrefix("~~~") {
        fence = line.prefix(3)
      } else if let heading = MarkdownHeading(line: line) {
        headings.append(heading)
      }
    }
    return headings
  }
}
