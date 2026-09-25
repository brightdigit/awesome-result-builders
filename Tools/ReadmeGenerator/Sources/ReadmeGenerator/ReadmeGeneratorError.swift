//
//  ReadmeGeneratorError.swift
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

public import Foundation

/// An error that stops the README from being generated.
///
/// Each ``description`` is written for the person running the tool.
public enum ReadmeGeneratorError: Error, Equatable, CustomStringConvertible,
  LocalizedError
{
  /// The project data file couldn't be read.
  case unreadableData(path: String, reason: String)
  /// The project data file isn't a valid catalog.
  case invalidData(path: String, reason: String)
  /// The project data has mistakes, such as unknown categories or duplicate URLs.
  case invalidCatalog(problems: [String])
  /// A Markdown template couldn't be read.
  case unreadableTemplate(path: String, reason: String)
  /// The generated README couldn't be written.
  case unwritableOutput(path: String, reason: String)

  public var description: String {
    switch self {
    case let .unreadableData(path, reason):
      return "Could not read \(path): \(reason)"
    case let .invalidData(path, reason):
      return "Could not parse \(path): \(reason)"
    case let .invalidCatalog(problems):
      let noun = problems.count == 1 ? "problem" : "problems"
      let list = problems.map { "  - \($0)" }.joined(separator: "\n")
      return "Found \(problems.count) \(noun) in the project data:\n\(list)"
    case let .unreadableTemplate(path, reason):
      return "Could not read template \(path): \(reason)"
    case let .unwritableOutput(path, reason):
      return "Could not write \(path): \(reason)"
    }
  }

  public var errorDescription: String? { description }
}
