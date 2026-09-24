import Foundation
import Yams

/// The contents of `data/projects.yml`.
struct Catalog: Decodable, Sendable {
  /// Categories in the order their sections appear in the README.
  let categories: [Category]
  let projects: [Project]
  let resources: [ResourceGroup]

  private enum CodingKeys: String, CodingKey {
    case categories
    case projects
    case resources
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    categories = try container.decode([Category].self, forKey: .categories)
    projects = try container.decodeIfPresent([Project].self, forKey: .projects) ?? []
    resources = try container.decodeIfPresent([ResourceGroup].self, forKey: .resources) ?? []
  }

  static func load(from url: URL) throws -> Catalog {
    let yaml: String
    do {
      yaml = try String(contentsOf: url, encoding: .utf8)
    } catch {
      throw GeneratorError("Could not read \(url.path): \(error.localizedDescription)")
    }
    do {
      return try YAMLDecoder().decode(Catalog.self, from: yaml)
    } catch {
      throw GeneratorError("Could not parse \(url.path): \(describe(error))")
    }
  }

  /// Turns decoding errors into a short message pointing at the offending entry,
  /// such as `missing required key "url" at projects[3]`.
  private static func describe(_ error: any Error) -> String {
    guard let error = error as? DecodingError else {
      return "\(error)"
    }
    switch error {
    case .keyNotFound(let key, let context):
      return "missing required key \"\(key.stringValue)\" at \(path(context.codingPath))"
    case .dataCorrupted(let context):
      // YAML syntax errors carry the line and column in the underlying error.
      if let underlyingError = context.underlyingError {
        return "\(underlyingError)"
      }
      return "\(context.debugDescription) (at \(path(context.codingPath)))"
    case .typeMismatch(_, let context), .valueNotFound(_, let context):
      return "\(context.debugDescription) (at \(path(context.codingPath)))"
    @unknown default:
      return "\(error)"
    }
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

struct Category: Decodable, Sendable {
  let id: String
  let name: String
  let description: String?
}

struct Project: Decodable, Sendable {
  let name: String
  let url: String
  let description: String
  /// The `id` of a ``Category``.
  let category: String
  let platforms: [String]?
}

struct ResourceGroup: Decodable, Sendable {
  let name: String
  let items: [Resource]
}

struct Resource: Decodable, Sendable {
  let title: String
  let url: String
  let note: String?
}

/// An error whose description is shown to the user as-is.
struct GeneratorError: Error, CustomStringConvertible, LocalizedError {
  let description: String

  init(_ description: String) {
    self.description = description
  }

  var errorDescription: String? { description }
}
