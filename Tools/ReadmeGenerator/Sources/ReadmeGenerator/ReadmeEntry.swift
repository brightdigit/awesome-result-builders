//
//  ReadmeEntry.swift
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

/// One `- [Name](url) - Description.` item in the README.
internal struct ReadmeEntry: Codable, Equatable, Sendable {
  internal let title: String
  internal let url: String
  internal let summary: String?
  internal let platforms: [String]
  internal let metadata: RepositoryMetadata?

  /// The entry as a Markdown list item.
  internal var listItem: ListItem {
    var content: [any InlineMarkup] = [Link(destination: url, Text(title))]
    if let summary {
      content.append(Text(" - \(summary)"))
    }
    for platform in platforms {
      content.append(Text(" "))
      content.append(InlineCode(platform))
    }
    if let metadata {
      content.append(Text(" \(metadata.summary)"))
      if metadata.isArchived {
        content.append(Text(" · "))
        content.append(Strong(Text("archived")))
      }
    }
    return ListItem(Paragraph(content))
  }

  internal init(project: Project, metadata: RepositoryMetadata?) {
    title = project.name
    url = project.url
    summary = project.description.sentence
    platforms = project.platforms ?? []
    self.metadata = metadata
  }

  internal init(resource: Resource) {
    title = resource.title
    url = resource.url
    summary = resource.note?.trimmedNonEmpty?.sentence
    platforms = []
    metadata = nil
  }
}
