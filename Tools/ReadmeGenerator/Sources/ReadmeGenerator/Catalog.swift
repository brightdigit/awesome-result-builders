//
//  Catalog.swift
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
import Yams

/// The contents of `data/projects.yml`.
internal struct Catalog: Decodable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case categories
    case projects
    case resources
  }

  /// Categories in the order their sections appear in the README.
  internal let categories: [Category]
  internal let projects: [Project]
  internal let resources: [ResourceGroup]

  internal init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    categories = try container.decode([Category].self, forKey: .categories)
    projects = try container.decodeIfPresent([Project].self, forKey: .projects) ?? []
    resources =
      try container.decodeIfPresent([ResourceGroup].self, forKey: .resources) ?? []
  }

  internal static func load(from url: URL) throws -> Catalog {
    let yaml: String
    do {
      yaml = try String(contentsOf: url, encoding: .utf8)
    } catch {
      throw GeneratorError(
        "Could not read \(url.path): \(error.localizedDescription)"
      )
    }
    do {
      return try YAMLDecoder().decode(Catalog.self, from: yaml)
    } catch {
      throw GeneratorError("Could not parse \(url.path): \(describe(error))")
    }
  }

  /// Turns decoding errors into a short message pointing at the offending entry.
  ///
  /// For example: `missing required key "url" at projects[3]`.
  private static func describe(_ error: any Error) -> String {
    guard let error = error as? DecodingError else {
      return "\(error)"
    }
    switch error {
    case let .keyNotFound(key, context):
      return "missing required key \"\(key.stringValue)\" at \(path(context.codingPath))"
    case .dataCorrupted(let context),
      .typeMismatch(_, let context),
      .valueNotFound(_, let context):
      return describe(context)
    @unknown default:
      return "\(error)"
    }
  }

  private static func describe(_ context: DecodingError.Context) -> String {
    // YAML syntax errors carry the line and column in the underlying error.
    if let underlyingError = context.underlyingError {
      return "\(underlyingError)"
    }
    return "\(context.debugDescription) (at \(path(context.codingPath)))"
  }

  private static func path(_ codingPath: [any CodingKey]) -> String {
    guard !codingPath.isEmpty else {
      return "the top level"
    }
    return codingPath.reduce(into: "") { path, key in
      if let index = key.intValue {
        path += "[\(index)]"
      } else {
        path += path.isEmpty ? key.stringValue : ".\(key.stringValue)"
      }
    }
  }
}
