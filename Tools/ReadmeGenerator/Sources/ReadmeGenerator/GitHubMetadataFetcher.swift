//
//  GitHubMetadataFetcher.swift
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

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Looks up ``RepositoryMetadata`` from the GitHub REST API.
internal struct GitHubMetadataFetcher: Sendable {
  internal let token: String

  /// Fetches metadata for every GitHub URL concurrently, keyed by the URL as given.
  ///
  /// URLs that aren't GitHub repositories, and requests that fail for any
  /// reason (most often a private repository the token can't see), are left out.
  internal func metadata(forURLs urls: [String]) async -> [String: RepositoryMetadata] {
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

  internal func metadata(for repository: GitHubRepository) async throws
    -> RepositoryMetadata
  {
    let path = "repos/\(repository.owner)/\(repository.name)"
    guard let url = URL(string: "https://api.github.com/\(path)") else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: url, timeoutInterval: 30)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    request.setValue(
      "awesome-result-builders-generate-readme",
      forHTTPHeaderField: "User-Agent"
    )

    let (data, statusCode) = try await URLSession.shared.responseData(for: request)
    guard statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(RepositoryMetadata.self, from: data)
  }
}
