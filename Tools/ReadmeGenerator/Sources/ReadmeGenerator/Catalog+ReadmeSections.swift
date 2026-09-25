//
//  Catalog+ReadmeSections.swift
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

extension Catalog {
  /// The resources heading, followed by one subsection per non-empty group.
  private var resourceSections: [ReadmeSection] {
    let groups = resources.filter { !$0.items.isEmpty }
    guard !groups.isEmpty else {
      return []
    }
    let groupSections = groups.map { group in
      ReadmeSection(
        heading: group.name,
        level: 3,
        introduction: nil,
        entries: group.items.map(ReadmeEntry.init(resource:))
      )
    }
    let heading = ReadmeSection(
      heading: "Learning Resources",
      level: 2,
      introduction: nil,
      entries: []
    )
    return [heading] + groupSections
  }

  /// The generated README sections in order: one per category with projects,
  /// then the learning resources.
  internal func readmeSections(metadata: [String: RepositoryMetadata]) -> [ReadmeSection]
  {
    categorySections(metadata: metadata) + resourceSections
  }

  private func categorySections(metadata: [String: RepositoryMetadata]) -> [ReadmeSection]
  {
    categories.compactMap { category in
      let entries =
        projects
        .filter { $0.category == category.id }
        .sorted { $0.precedes($1) }
        .map { ReadmeEntry(project: $0, metadata: metadata[$0.url]) }
      guard !entries.isEmpty else {
        return nil
      }
      return ReadmeSection(
        heading: category.name,
        level: 2,
        introduction: category.description?.trimmedNonEmpty,
        entries: entries
      )
    }
  }
}
