//
//  ReadmeRenderer.swift
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

import Markdown

/// Renders a ``Catalog`` into the README's Markdown.
internal struct ReadmeRenderer: Codable, Equatable, Sendable {
  /// Markdown placed after the generated notice and before the table of contents.
  internal let header: MarkdownTemplate
  /// Markdown placed after the generated sections.
  internal let footer: MarkdownTemplate
  /// GitHub metadata keyed by project URL.
  ///
  /// Projects without an entry render without metadata.
  internal var metadata: [String: RepositoryMetadata] = [:]

  /// The HTML comment at the top of the generated file.
  internal var generatedNotice: String {
    "<!-- This file is generated from data/projects.yml and Templates/ by "
      + "Tools/ReadmeGenerator. Do not edit it by hand; see CONTRIBUTING.md. -->"
  }

  internal func render(_ catalog: Catalog) -> String {
    let sections = catalog.readmeSections(metadata: metadata)
    let tableOfContents: [any BlockMarkup] = [
      Heading(level: 2, Text("Contents")),
      UnorderedList(contents(for: sections).map(\.listItem)),
    ]
    let generated = Document(tableOfContents + sections.flatMap(\.blocks)).format()
    return [generatedNotice, header.markdown, generated, footer.markdown]
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n") + "\n"
  }

  /// The table of contents for `sections` and the footer's top-level headings.
  ///
  /// Anchors are assigned in document order so repeated headings get the same
  /// suffixes GitHub gives them.
  internal func contents(for sections: [ReadmeSection]) -> [ContentsEntry] {
    var anchors = AnchorGenerator()
    for heading in header.headings {
      _ = anchors.anchor(for: heading.text)
    }
    _ = anchors.anchor(for: "Contents")

    var entries: [ContentsEntry] = []
    for section in sections {
      let anchor = anchors.anchor(for: section.heading)
      let entry = ContentsEntry(title: section.heading, anchor: anchor)
      if section.level > 2, !entries.isEmpty {
        entries[entries.count - 1].children.append(entry)
      } else {
        entries.append(entry)
      }
    }
    for heading in footer.headings {
      let anchor = anchors.anchor(for: heading.text)
      if heading.level == 2 {
        entries.append(ContentsEntry(title: heading.text, anchor: anchor))
      }
    }
    return entries
  }
}
