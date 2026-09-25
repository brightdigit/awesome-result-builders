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
internal struct Catalog: Codable, Equatable, Sendable {
  /// Categories in the order their sections appear in the README.
  internal let categories: [Category]
  internal let projects: [Project]
  internal let resources: [ResourceGroup]

  internal init(categories: [Category], projects: [Project], resources: [ResourceGroup]) {
    self.categories = categories
    self.projects = projects
    self.resources = resources
  }

  /// Decodes a catalog from YAML; `path` names the source in error messages.
  internal init(yaml: String, path: String = "the project data")
    throws(ReadmeGeneratorError)
  {
    do {
      self = try YAMLDecoder().decode(Catalog.self, from: yaml)
    } catch let error as DecodingError {
      throw .invalidData(path: path, reason: error.readableDescription)
    } catch {
      throw .invalidData(path: path, reason: "\(error)")
    }
  }

  /// Reads and decodes the catalog at `url`.
  internal init(contentsOf url: URL) throws(ReadmeGeneratorError) {
    let yaml: String
    do {
      yaml = try String(contentsOf: url, encoding: .utf8)
    } catch {
      throw .unreadableData(path: url.path, reason: error.localizedDescription)
    }
    try self.init(yaml: yaml, path: url.path)
  }
}
