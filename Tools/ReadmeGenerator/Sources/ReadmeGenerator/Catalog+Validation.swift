//
//  Catalog+Validation.swift
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
  /// Mistakes that would produce a broken or misleading README, in file order.
  internal var problems: [String] {
    categoryProblems + urlProblems
  }

  /// Every linked entry, in file order, so duplicates are reported predictably.
  internal var links: [CatalogLink] {
    let projectLinks = projects.map { project in
      CatalogLink(label: "project \"\(project.name)\"", url: project.url)
    }
    let resourceLinks = resources.flatMap { group in
      group.items.map { item in
        CatalogLink(label: "resource \"\(item.title)\"", url: item.url)
      }
    }
    return projectLinks + resourceLinks
  }

  private var categoryProblems: [String] {
    var problems: [String] = []

    var categoryIDs: Set<String> = []
    for category in categories where !categoryIDs.insert(category.id).inserted {
      problems.append("Category id \"\(category.id)\" is defined more than once.")
    }

    let knownIDs = categories.map(\.id).joined(separator: ", ")
    for project in projects where !categoryIDs.contains(project.category) {
      problems.append(
        "Project \"\(project.name)\" has unknown category \"\(project.category)\". "
          + "Known categories: \(knownIDs)."
      )
    }
    return problems
  }

  private var urlProblems: [String] {
    var problems: [String] = []
    var usages: [NormalizedURL: URLUsage] = [:]
    var order: [NormalizedURL] = []
    for link in links {
      guard let normalized = NormalizedURL(link.url) else {
        let url = link.url
        problems.append("The URL of \(link.label) is not a valid http(s) URL: \(url)")
        continue
      }
      if usages[normalized] == nil {
        order.append(normalized)
        usages[normalized] = URLUsage(url: link.url)
      }
      usages[normalized]?.labels.append(link.label)
    }
    for normalized in order {
      guard let usage = usages[normalized], usage.labels.count > 1 else {
        continue
      }
      let users = usage.labels.joined(separator: " and ")
      problems.append("Duplicate URL \(usage.url) is used by \(users).")
    }
    return problems
  }

  /// Throws ``ReadmeGeneratorError/invalidCatalog(problems:)`` listing every problem.
  internal func validate() throws(ReadmeGeneratorError) {
    let found = problems
    guard found.isEmpty else {
      throw .invalidCatalog(problems: found)
    }
  }
}
