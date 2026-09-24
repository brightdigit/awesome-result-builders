import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Repository details shown next to a project when `--fetch-metadata` is used.
struct RepositoryMetadata: Decodable, Sendable {
  let stars: Int
  let pushedAt: Date?
  let isArchived: Bool

  private enum CodingKeys: String, CodingKey {
    case stars = "stargazers_count"
    case pushedAt = "pushed_at"
    case isArchived = "archived"
  }
}

/// The owner and name of a repository linked as `https://github.com/<owner>/<name>`.
struct GitHubRepository: Hashable, Sendable {
  let owner: String
  let name: String

  /// Returns `nil` unless `url` points at the root of a GitHub repository.
  init?(url: String) {
    guard
      let components = URLComponents(string: url),
      let host = components.host?.lowercased(),
      host == "github.com" || host == "www.github.com"
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

/// Looks up ``RepositoryMetadata`` from the GitHub REST API.
struct GitHubMetadataFetcher: Sendable {
  let token: String

  /// Fetches metadata for every GitHub URL concurrently.
  ///
  /// The result is keyed by the URL as given. URLs that aren't GitHub
  /// repositories, and requests that fail for any reason (most often a private
  /// repository the token can't see), are left out.
  func metadata(forURLs urls: [String]) async -> [String: RepositoryMetadata] {
    await withTaskGroup(of: (String, RepositoryMetadata?).self) { group in
      for url in Set(urls) {
        guard let repository = GitHubRepository(url: url) else {
          continue
        }
        group.addTask {
          (url, try? await metadata(for: repository))
        }
      }
      var results: [String: RepositoryMetadata] = [:]
      for await (url, metadata) in group {
        results[url] = metadata
      }
      return results
    }
  }

  func metadata(for repository: GitHubRepository) async throws -> RepositoryMetadata {
    guard
      let url = URL(string: "https://api.github.com/repos/\(repository.owner)/\(repository.name)")
    else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: url, timeoutInterval: 30)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    request.setValue("awesome-result-builders-generate-readme", forHTTPHeaderField: "User-Agent")

    let (data, statusCode) = try await URLSession.shared.responseData(for: request)
    guard statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(RepositoryMetadata.self, from: data)
  }
}

extension URLSession {
  /// Performs `request` and returns the body and HTTP status code.
  ///
  /// Wraps the completion-handler API in a continuation because the async
  /// `URLSession` methods aren't available in every Linux Foundation release.
  func responseData(for request: URLRequest) async throws -> (data: Data, statusCode: Int) {
    try await withCheckedThrowingContinuation { continuation in
      let task = dataTask(with: request) { data, response, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let data, let response = response as? HTTPURLResponse {
          continuation.resume(returning: (data, response.statusCode))
        } else {
          continuation.resume(throwing: URLError(.badServerResponse))
        }
      }
      task.resume()
    }
  }
}
