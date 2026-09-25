//
//  MarkdownTemplate.swift
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
import Markdown

/// A Markdown file inserted into the README as-is, such as `Templates/header.md`.
internal struct MarkdownTemplate: Codable, Equatable, Sendable {
  /// The template's Markdown without surrounding whitespace.
  internal let markdown: String

  /// The template's headings in document order; code blocks are skipped.
  internal var headings: [TemplateHeading] {
    var collector = HeadingCollector()
    collector.visit(Document(parsing: markdown))
    return collector.headings
  }

  internal init(markdown: String) {
    self.markdown = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Reads the template at `url`.
  internal init(contentsOf url: URL) throws(ReadmeGeneratorError) {
    let markdown: String
    do {
      markdown = try String(contentsOf: url, encoding: .utf8)
    } catch {
      throw .unreadableTemplate(path: url.path, reason: error.localizedDescription)
    }
    self.init(markdown: markdown)
  }
}
