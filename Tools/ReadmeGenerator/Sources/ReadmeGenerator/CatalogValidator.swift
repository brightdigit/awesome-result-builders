import Foundation

/// Checks a ``Catalog`` for mistakes that would produce a broken or misleading README.
enum CatalogValidator {
  /// Throws a ``GeneratorError`` listing every problem found, or returns if there are none.
  static func validate(_ catalog: Catalog) throws {
    let problems = problems(in: catalog)
    guard !problems.isEmpty else {
      return
    }
    let noun = problems.count == 1 ? "problem" : "problems"
    let list = problems.map { "  - \($0)" }.joined(separator: "\n")
    throw GeneratorError("Found \(problems.count) \(noun) in the project data:\n\(list)")
  }

  static func problems(in catalog: Catalog) -> [String] {
    var problems: [String] = []

    var categoryIDs: Set<String> = []
    for category in catalog.categories where !categoryIDs.insert(category.id).inserted {
      problems.append("Category id \"\(category.id)\" is defined more than once.")
    }

    let knownIDs = catalog.categories.map(\.id).joined(separator: ", ")
    for project in catalog.projects where !categoryIDs.contains(project.category) {
      problems.append(
        "Project \"\(project.name)\" has unknown category \"\(project.category)\". "
          + "Known categories: \(knownIDs)."
      )
    }

    // Every linked entry, in file order, so duplicates are reported predictably.
    let entries: [(label: String, url: String)] =
      catalog.projects.map { ("project \"\($0.name)\"", $0.url) }
      + catalog.resources.flatMap { group in
        group.items.map { ("resource \"\($0.title)\"", $0.url) }
      }

    // Normalized URL → the first spelling seen and every entry using it.
    var usesByURL: [String: (url: String, labels: [String])] = [:]
    var urlOrder: [String] = []
    for entry in entries {
      guard let key = normalizedURL(entry.url) else {
        problems.append("The URL of \(entry.label) is not a valid http(s) URL: \(entry.url)")
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
      problems.append(
        "Duplicate URL \(uses.url) is used by \(uses.labels.joined(separator: " and "))."
      )
    }

    return problems
  }

  /// Reduces a URL to a comparable form so that trivially different spellings
  /// (scheme, `www.`, letter case, trailing slash, `.git`) count as the same link.
  /// Returns `nil` for anything that isn't an absolute http(s) URL.
  static func normalizedURL(_ string: String) -> String? {
    guard
      let components = URLComponents(string: string.trimmingCharacters(in: .whitespaces)),
      let scheme = components.scheme?.lowercased(),
      scheme == "http" || scheme == "https",
      var host = components.host?.lowercased(),
      !host.isEmpty
    else {
      return nil
    }
    if host.hasPrefix("www.") {
      host.removeFirst(4)
    }
    var path = components.path.lowercased()
    while path.hasSuffix("/") {
      path.removeLast()
    }
    if path.hasSuffix(".git") {
      path.removeLast(4)
    }
    var result = host + path
    if let query = components.query, !query.isEmpty {
      result += "?" + query.lowercased()
    }
    if let fragment = components.fragment, !fragment.isEmpty {
      result += "#" + fragment.lowercased()
    }
    return result
  }
}
