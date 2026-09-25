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

import AsyncHTTPClient
import Foundation
import NIOCore
import NIOFoundationCompat

/// Looks up ``RepositoryMetadata`` from the GitHub REST API.
internal struct GitHubMetadataFetcher: Sendable {
  /// The largest response body accepted, far above a repository's JSON.
  private let maximumBodySize = 1 << 20
  private let userAgent = "awesome-result-builders-generate-readme"

  internal let token: String
  /// The API root: `https://api.github.com`, or another server for testing.
  internal let apiURL: String
  internal let client: HTTPClient

  internal init(token: String, apiURL: String, client: HTTPClient = .shared) {
    self.token = token
    self.apiURL = apiURL
    self.client = client
  }

  /// Fetches metadata for every GitHub URL concurrently, keyed by the URL as given.
  ///
  /// URLs that aren't GitHub repositories, and requests that fail for any
  /// reason (most often a private repository the token can't see), are left out.
  internal func metadata(forURLs urls: [String]) async -> [String: RepositoryMetadata] {
    await withTaskGroup(of: RepositoryLookup.self) { group in
      for url in Set(urls) {
        guard let repository = GitHubRepository(url: url) else {
          continue
        }
        group.addTask {
          RepositoryLookup(url: url, metadata: try? await metadata(for: repository))
        }
      }
      var results: [String: RepositoryMetadata] = [:]
      for await lookup in group {
        results[lookup.url] = lookup.metadata
      }
      return results
    }
  }

  internal func metadata(
    for repository: GitHubRepository
  ) async throws(GitHubMetadataError) -> RepositoryMetadata {
    var request = HTTPClientRequest(url: "\(apiURL)/\(repository.apiPath)")
    request.headers.add(name: "Authorization", value: "Bearer \(token)")
    request.headers.add(name: "Accept", value: "application/vnd.github+json")
    request.headers.add(name: "X-GitHub-Api-Version", value: "2022-11-28")
    request.headers.add(name: "User-Agent", value: userAgent)

    let body: ByteBuffer
    do {
      let response = try await client.execute(request, timeout: .seconds(30))
      guard response.status == .ok else {
        throw GitHubMetadataError.unexpectedStatus(response.status.code)
      }
      body = try await response.body.collect(upTo: maximumBodySize)
    } catch let error as GitHubMetadataError {
      throw error
    } catch {
      throw .requestFailed("\(error)")
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do {
      return try decoder.decode(RepositoryMetadata.self, from: body)
    } catch {
      throw .invalidResponse("\(error)")
    }
  }
}
