//
//  DecodingError+ReadableDescription.swift
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

extension DecodingError {
  /// A short message pointing at the offending entry.
  ///
  /// For example: `missing required key "url" at projects[3]`.
  internal var readableDescription: String {
    switch self {
    case let .keyNotFound(key, context):
      let path = context.codingPath.readablePath
      return "missing required key \"\(key.stringValue)\" at \(path)"
    case let .dataCorrupted(context),
      let .typeMismatch(_, context),
      let .valueNotFound(_, context):
      return context.readableDescription
    @unknown default:
      return "\(self)"
    }
  }
}

extension DecodingError.Context {
  /// The context's message and where it happened.
  internal var readableDescription: String {
    // YAML syntax errors carry the line and column in the underlying error.
    if let underlyingError {
      return "\(underlyingError)"
    }
    return "\(debugDescription) (at \(codingPath.readablePath))"
  }
}
