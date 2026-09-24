import Foundation

/// Renders a ``Catalog`` into the README's Markdown.
struct ReadmeRenderer {
  static let generatedNotice =
    "<!-- This file is generated from data/projects.yml and Templates/ by Tools/ReadmeGenerator. "
    + "Do not edit it by hand; see CONTRIBUTING.md. -->"

  static let contentsHeading = "Contents"
  static let resourcesHeading = "Learning Resources"

  /// Markdown placed after the generated notice and before the table of contents.
  let header: String
  /// Markdown placed after the generated sections.
  let footer: String
  /// GitHub metadata keyed by project URL. Projects without an entry render without it.
  var metadata: [String: RepositoryMetadata] = [:]

  func render(_ catalog: Catalog) -> String {
    let header = header.trimmingCharacters(in: .whitespacesAndNewlines)
    let footer = footer.trimmingCharacters(in: .whitespacesAndNewlines)

    // Anchors are assigned in document order so repeated headings get the
    // same suffixes GitHub gives them.
    var anchors = AnchorGenerator()
    for heading in MarkdownHeading.headings(in: header) {
      _ = anchors.anchor(for: heading.text)
    }
    _ = anchors.anchor(for: Self.contentsHeading)

    var tableOfContents: [String] = []
    var sections: [String] = []

    for category in catalog.categories {
      let projects = catalog.projects
        .filter { $0.category == category.id }
        .sorted(by: Self.caseInsensitiveOrder)
      guard !projects.isEmpty else {
        continue
      }
      let anchor = anchors.anchor(for: category.name)
      tableOfContents.append("- [\(category.name)](#\(anchor))")

      var blocks = ["## \(category.name)"]
      if let description = category.description?.trimmingCharacters(in: .whitespacesAndNewlines),
        !description.isEmpty
      {
        blocks.append(description)
      }
      blocks.append(projects.map(line(for:)).joined(separator: "\n"))
      sections.append(blocks.joined(separator: "\n\n"))
    }

    let resourceGroups = catalog.resources.filter { !$0.items.isEmpty }
    if !resourceGroups.isEmpty {
      let anchor = anchors.anchor(for: Self.resourcesHeading)
      tableOfContents.append("- [\(Self.resourcesHeading)](#\(anchor))")

      var blocks = ["## \(Self.resourcesHeading)"]
      for group in resourceGroups {
        let groupAnchor = anchors.anchor(for: group.name)
        tableOfContents.append("  - [\(group.name)](#\(groupAnchor))")
        blocks.append("### \(group.name)")
        blocks.append(group.items.map(line(for:)).joined(separator: "\n"))
      }
      sections.append(blocks.joined(separator: "\n\n"))
    }

    for heading in MarkdownHeading.headings(in: footer) {
      let anchor = anchors.anchor(for: heading.text)
      if heading.level == 2 {
        tableOfContents.append("- [\(heading.text)](#\(anchor))")
      }
    }

    var document = [Self.generatedNotice]
    if !header.isEmpty {
      document.append(header)
    }
    document.append("## \(Self.contentsHeading)\n\n" + tableOfContents.joined(separator: "\n"))
    document.append(contentsOf: sections)
    if !footer.isEmpty {
      document.append(footer)
    }
    return document.joined(separator: "\n\n") + "\n"
  }

  func line(for project: Project) -> String {
    var line = "- [\(project.name)](\(project.url)) - \(Self.sentence(project.description))"
    if let platforms = project.platforms, !platforms.isEmpty {
      line += " " + platforms.map { "`\($0)`" }.joined(separator: " ")
    }
    if let metadata = metadata[project.url] {
      var details = ["★ \(metadata.stars)"]
      if let pushedAt = metadata.pushedAt {
        details.append("updated \(Self.monthAndYear(pushedAt))")
      }
      if metadata.isArchived {
        details.append("**archived**")
      }
      line += " " + details.joined(separator: " · ")
    }
    return line
  }

  func line(for resource: Resource) -> String {
    var line = "- [\(resource.title)](\(resource.url))"
    if let note = resource.note?.trimmingCharacters(in: .whitespacesAndNewlines), !note.isEmpty {
      line += " - \(Self.sentence(note))"
    }
    return line
  }

  /// Orders projects by name ignoring case, falling back to exact name and URL
  /// so the output never depends on the order of the data file.
  static func caseInsensitiveOrder(_ lhs: Project, _ rhs: Project) -> Bool {
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

  /// Trims `text` and makes sure it ends with sentence punctuation.
  static func sentence(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let last = trimmed.last, !".!?".contains(last) else {
      return trimmed
    }
    return trimmed + "."
  }

  /// Formats a date as, for example, "Sep 2026" regardless of the machine's locale or time zone.
  static func monthAndYear(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "MMM yyyy"
    return formatter.string(from: date)
  }
}
