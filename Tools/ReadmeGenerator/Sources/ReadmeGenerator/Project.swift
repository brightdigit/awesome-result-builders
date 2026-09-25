//
//  Project.swift
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

/// A library or tool listed in the README.
internal struct Project: Codable, Equatable, Sendable {
  internal let name: String
  internal let url: String
  internal let description: String
  /// The `id` of a ``Category``.
  internal let category: String
  internal let platforms: [String]?

  /// Whether this project is listed before `other`.
  ///
  /// Projects are ordered by name ignoring case, then by exact name and URL, so
  /// the README never depends on the order of the data file.
  internal func precedes(_ other: Project) -> Bool {
    let key = name.lowercased()
    let otherKey = other.name.lowercased()
    if key != otherKey {
      return key < otherKey
    }
    if name != other.name {
      return name < other.name
    }
    return url < other.url
  }
}
