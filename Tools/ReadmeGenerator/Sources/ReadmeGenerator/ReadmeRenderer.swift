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

import Foundation

/// Renders a ``Catalog`` into the README's Markdown.
internal struct ReadmeRenderer {
  internal static let generatedNotice =
    "<!-- This file is generated from data/projects.yml and Templates/ by "
    + "Tools/ReadmeGenerator. Do not edit it by hand; see CONTRIBUTING.md. -->"

  internal static let contentsHeading = "Contents"
  internal static let resourcesHeading = "Learning Resources"

  /// Markdown placed after the generated notice and before the table of contents.
  internal let header: String
  /// Markdown placed after the generated sections.
  internal let footer: String
  /// GitHub metadata keyed by project URL.
  ///
  /// Projects without an entry render without metadata.
  internal var metadata: [String: RepositoryMetadata] = [:]

  /// Orders projects by name ignoring case, then by exact name and URL.
  ///
  /// The fallbacks keep the output independent of the data file's order.
  private static func caseInsensitiveOrder(_ lhs: Project, _ rhs: Project) -> Bool {
    let lhsKey = lhs.name.lowercased()
    let rhsKey = rhs.name.lowercased()
    if lhsKey != rhsKey {
      return lhsKey < rhsKey
    }
    if lhs.name != rhs.name {
      return lhs.name < rhs.name
    }
    return lhs.url < rhs.url
  }

  /// Returns `text` without surrounding whitespace, or `nil` if nothing is left.
  internal static func trimmed(_ text: String?) -> String? {
    let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? nil : trimmed
  }

  private static func contentsEntry(
    _ heading: String,
    level: Int,
    anchor: String
  ) -> String {
    let indent = String(repeating: "  ", count: max(level - 2, 0))
    return "\(indent)- [\(heading)](#\(anchor))"
  }

  internal func render(_ catalog: Catalog) -> String {
    let header = Self.trimmed(header) ?? ""
    let footer = Self.trimmed(footer) ?? ""
    let sections = categorySections(for: catalog) + resourceSections(for: catalog)

    // Anchors are assigned in document order so repeated headings get the
    // same suffixes GitHub gives them.
    var anchors = AnchorGenerator()
    for heading in MarkdownHeading.headings(in: header) {
      _ = anchors.anchor(for: heading.text)
    }
    _ = anchors.anchor(for: Self.contentsHeading)
    var contents = sections.map { section in
      Self.contentsEntry(
        section.heading,
        level: section.level,
        anchor: anchors.anchor(for: section.heading)
      )
    }
    // Only the footer's top-level sections belong in the table of contents.
    for heading in MarkdownHeading.headings(in: footer) {
      let anchor = anchors.anchor(for: heading.text)
      if heading.level == 2 {
        contents.append(Self.contentsEntry(heading.text, level: 2, anchor: anchor))
      }
    }

    let contentsBlock =
      "## \(Self.contentsHeading)\n\n" + contents.joined(separator: "\n")
    let document =
      [Self.generatedNotice, header, contentsBlock]
      + sections.map(\.markdown)
      + [footer]
    return document.filter { !$0.isEmpty }.joined(separator: "\n\n") + "\n"
  }

  /// One section per category that has projects, in category order.
  private func categorySections(for catalog: Catalog) -> [ReadmeSection] {
    catalog.categories.compactMap { category in
      let projects = catalog.projects
        .filter { $0.category == category.id }
        .sorted(by: Self.caseInsensitiveOrder)
      guard !projects.isEmpty else {
        return nil
      }
      let list = projects.map(line(for:)).joined(separator: "\n")
      let blocks = [Self.trimmed(category.description), list].compactMap { $0 }
      return ReadmeSection(heading: category.name, level: 2, blocks: blocks)
    }
  }

  /// The learning resources heading plus one subsection per non-empty group.
  private func resourceSections(for catalog: Catalog) -> [ReadmeSection] {
    let groups = catalog.resources.filter { !$0.items.isEmpty }
    guard !groups.isEmpty else {
      return []
    }
    let groupSections = groups.map { group in
      ReadmeSection(
        heading: group.name,
        level: 3,
        blocks: [group.items.map(line(for:)).joined(separator: "\n")]
      )
    }
    let heading = ReadmeSection(heading: Self.resourcesHeading, level: 2, blocks: [])
    return [heading] + groupSections
  }
}
