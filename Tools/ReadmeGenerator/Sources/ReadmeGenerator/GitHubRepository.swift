//
//  GitHubRepository.swift
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

/// The owner and name of a repository linked as `https://github.com/<owner>/<name>`.
internal struct GitHubRepository: Hashable, Sendable {
  internal let owner: String
  internal let name: String

  /// Returns `nil` unless `url` points at the root of a GitHub repository.
  internal init?(url: String) {
    guard
      let components = URLComponents(string: url),
      let host = components.host?.lowercased(),
      ["github.com", "www.github.com"].contains(host)
    else {
      return nil
    }
    let parts = components.path.split(separator: "/")
    guard parts.count == 2 else {
      return nil
    }
    var name = String(parts[1])
    if name.hasSuffix(".git") {
      name.removeLast(4)
    }
    owner = String(parts[0])
    self.name = name
  }
}
