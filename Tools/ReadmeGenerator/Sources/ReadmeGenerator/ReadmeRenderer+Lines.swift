//
//  ReadmeRenderer+Lines.swift
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

/// Formatting for the individual list items in the README.
extension ReadmeRenderer {
  /// Trims `text` and makes sure it ends with sentence punctuation.
  private static func sentence(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let last = trimmed.last, !".!?".contains(last) else {
      return trimmed
    }
    return trimmed + "."
  }

  /// Formats a date as, for example, "Sep 2026" in any locale or time zone.
  private static func monthAndYear(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "MMM yyyy"
    return formatter.string(from: date)
  }

  /// The `★ N · updated MMM yyyy` suffix for a project line.
  private static func details(for metadata: RepositoryMetadata) -> String {
    var details = ["★ \(metadata.stars)"]
    if let pushedAt = metadata.pushedAt {
      details.append("updated \(monthAndYear(pushedAt))")
    }
    if metadata.isArchived {
      details.append("**archived**")
    }
    return details.joined(separator: " · ")
  }

  internal func line(for project: Project) -> String {
    let description = Self.sentence(project.description)
    var line = "- [\(project.name)](\(project.url)) - \(description)"
    if let platforms = project.platforms, !platforms.isEmpty {
      line += " " + platforms.map { "`\($0)`" }.joined(separator: " ")
    }
    if let metadata = metadata[project.url] {
      line += " " + Self.details(for: metadata)
    }
    return line
  }

  internal func line(for resource: Resource) -> String {
    var line = "- [\(resource.title)](\(resource.url))"
    if let note = Self.trimmed(resource.note) {
      line += " - \(Self.sentence(note))"
    }
    return line
  }
}
