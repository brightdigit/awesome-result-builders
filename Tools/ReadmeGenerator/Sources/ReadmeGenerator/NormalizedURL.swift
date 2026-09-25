//
//  NormalizedURL.swift
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

/// A URL reduced to a comparable form.
///
/// Trivially different spellings (scheme, `www.`, letter case, a trailing
/// slash, `.git`) produce the same value.
internal struct NormalizedURL: Codable, Hashable, Sendable {
  internal let value: String

  /// Returns `nil` for anything that isn't an absolute http(s) URL.
  internal init?(_ string: String) {
    guard
      let components = URLComponents(string: string.trimmingCharacters(in: .whitespaces)),
      let scheme = components.scheme?.lowercased(),
      ["http", "https"].contains(scheme),
      let host = components.host?.lowercased(),
      !host.isEmpty
    else {
      return nil
    }
    let bareHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    value = bareHost + components.normalizedPath + components.normalizedSuffix
  }
}
