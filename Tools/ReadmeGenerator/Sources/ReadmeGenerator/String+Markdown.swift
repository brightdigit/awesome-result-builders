//
//  String+Markdown.swift
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

extension String {
  /// The anchor GitHub gives a heading with this text.
  ///
  /// GitHub lowercases the heading, drops punctuation and symbols, and turns
  /// spaces into hyphens, so "Media & Documents" becomes `media--documents`.
  internal var gitHubSlug: String {
    var slug = ""
    for character in lowercased() {
      if character == " " {
        slug.append("-")
      } else if character.isLetter || character.isNumber || "-_".contains(character) {
        slug.append(character)
      }
    }
    return slug
  }

  /// The string trimmed, or `nil` if nothing is left.
  internal var trimmedNonEmpty: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  /// The string trimmed and ending with sentence punctuation.
  internal var sentence: String {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    guard let last = trimmed.last, !".!?".contains(last) else {
      return trimmed
    }
    return trimmed + "."
  }
}
