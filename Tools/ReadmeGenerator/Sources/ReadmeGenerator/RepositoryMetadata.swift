//
//  RepositoryMetadata.swift
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

/// Repository details shown next to a project when `--fetch-metadata` is used.
internal struct RepositoryMetadata: Codable, Equatable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case stars = "stargazers_count"
    case pushedAt = "pushed_at"
    case isArchived = "archived"
  }

  internal let stars: Int
  internal let pushedAt: Date?
  internal let isArchived: Bool

  /// `★ N · updated MMM yyyy`, or just the stars when the push date is unknown.
  internal var summary: String {
    var parts = ["★ \(stars)"]
    if let pushedAt {
      parts.append("updated \(pushedAt.monthAndYear)")
    }
    return parts.joined(separator: " · ")
  }
}
