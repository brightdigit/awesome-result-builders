//
//  CatalogValidator.swift
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

/// Checks a ``Catalog`` for mistakes that would produce a broken or misleading README.
internal enum CatalogValidator {
  /// Throws a ``GeneratorError`` listing every problem found.
  internal static func validate(_ catalog: Catalog) throws {
    let problems = categoryProblems(in: catalog) + urlProblems(in: catalog)
    guard !problems.isEmpty else {
      return
    }
    let noun = problems.count == 1 ? "problem" : "problems"
    let list = problems.map { "  - \($0)" }.joined(separator: "\n")
    throw GeneratorError(
      "Found \(problems.count) \(noun) in the project data:\n\(list)"
    )
  }

  /// Reduces a URL to a comparable form, or returns `nil` if it isn't http(s).
  ///
  /// Trivially different spellings (scheme, `www.`, letter case, a trailing
  /// slash, `.git`) produce the same result.
  internal static func normalizedURL(_ string: String) -> String? {
    guard
      let components = URLComponents(
        string: string.trimmingCharacters(in: .whitespaces)
      ),
      let scheme = components.scheme?.lowercased(),
      ["http", "https"].contains(scheme),
      let host = components.host?.lowercased(),
      !host.isEmpty
    else {
      return nil
    }
    let bareHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    return bareHost + normalizedPath(components.path) + normalizedSuffix(components)
  }

  private static func categoryProblems(in catalog: Catalog) -> [String] {
    var problems: [String] = []

    var categoryIDs: Set<String> = []
    for category in catalog.categories
    where !categoryIDs.insert(category.id).inserted {
      problems.append("Category id \"\(category.id)\" is defined more than once.")
    }

    let knownIDs = catalog.categories.map(\.id).joined(separator: ", ")
    for project in catalog.projects where !categoryIDs.contains(project.category) {
      problems.append(
        "Project \"\(project.name)\" has unknown category \"\(project.category)\". "
          + "Known categories: \(knownIDs)."
      )
    }
    return problems
  }

  private static func urlProblems(in catalog: Catalog) -> [String] {
    var problems: [String] = []
    // Normalized URL → the first spelling seen and every entry using it.
    var usesByURL: [String: (url: String, labels: [String])] = [:]
    var urlOrder: [String] = []
    for entry in linkedEntries(in: catalog) {
      guard let key = normalizedURL(entry.url) else {
        problems.append(
          "The URL of \(entry.label) is not a valid http(s) URL: \(entry.url)"
        )
        continue
      }
      if usesByURL[key] == nil {
        urlOrder.append(key)
        usesByURL[key] = (entry.url, [])
      }
      usesByURL[key]?.labels.append(entry.label)
    }
    for key in urlOrder {
      guard let uses = usesByURL[key], uses.labels.count > 1 else {
        continue
      }
      let users = uses.labels.joined(separator: " and ")
      problems.append("Duplicate URL \(uses.url) is used by \(users).")
    }
    return problems
  }

  /// Every linked entry, in file order, so duplicates are reported predictably.
  private static func linkedEntries(
    in catalog: Catalog
  ) -> [(label: String, url: String)] {
    let projects = catalog.projects.map { ("project \"\($0.name)\"", $0.url) }
    let resources = catalog.resources.flatMap { group in
      group.items.map { ("resource \"\($0.title)\"", $0.url) }
    }
    return projects + resources
  }

  private static func normalizedPath(_ path: String) -> String {
    var path = path.lowercased()
    while path.hasSuffix("/") {
      path.removeLast()
    }
    if path.hasSuffix(".git") {
      path.removeLast(4)
    }
    return path
  }

  private static func normalizedSuffix(_ components: URLComponents) -> String {
    var suffix = ""
    if let query = components.query, !query.isEmpty {
      suffix += "?" + query
    }
    if let fragment = components.fragment, !fragment.isEmpty {
      suffix += "#" + fragment
    }
    return suffix.lowercased()
  }
}
