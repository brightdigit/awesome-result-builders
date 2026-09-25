//
//  GenerateReadme.swift
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

import ArgumentParser
import Foundation

@main
internal struct GenerateReadme: AsyncParsableCommand {
  internal static let configuration = CommandConfiguration(
    commandName: "generate-readme",
    abstract: "Generate README.md from the project data and Markdown templates."
  )

  @Option(help: "The YAML file listing categories, projects, and resources.")
  internal var data = "data/projects.yml"

  @Option(help: "The directory containing header.md and footer.md.")
  internal var templates = "Templates"

  @Option(help: "Where to write the generated Markdown.")
  internal var output = "README.md"

  @Flag(
    help: """
      Add stars, last push date, and archived status from the GitHub API. \
      Requires the GITHUB_TOKEN environment variable.
      """
  )
  internal var fetchMetadata = false

  private static func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
  }

  private static func template(named name: String, in directory: URL) throws -> String {
    let url = directory.appendingPathComponent(name)
    do {
      return try String(contentsOf: url, encoding: .utf8)
    } catch {
      throw GeneratorError(
        "Could not read template \(url.path): \(error.localizedDescription)"
      )
    }
  }

  private static func fetchRepositoryMetadata(
    for projects: [Project]
  ) async -> [String: RepositoryMetadata] {
    let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] ?? ""
    guard !token.isEmpty else {
      printError("GITHUB_TOKEN is not set; generating without GitHub metadata.")
      return [:]
    }
    let urls = projects.map(\.url)
    let metadata = await GitHubMetadataFetcher(token: token).metadata(forURLs: urls)
    let repositoryCount = Set(urls.compactMap(GitHubRepository.init(url:))).count
    printError(
      "Fetched GitHub metadata for \(metadata.count) of \(repositoryCount) repositories."
    )
    return metadata
  }

  internal func run() async throws {
    let catalog = try Catalog.load(from: URL(fileURLWithPath: data))
    try CatalogValidator.validate(catalog)

    let templatesURL = URL(fileURLWithPath: templates, isDirectory: true)
    var renderer = ReadmeRenderer(
      header: try Self.template(named: "header.md", in: templatesURL),
      footer: try Self.template(named: "footer.md", in: templatesURL)
    )
    if fetchMetadata {
      renderer.metadata = await Self.fetchRepositoryMetadata(for: catalog.projects)
    }

    let readme = renderer.render(catalog)
    do {
      try readme.write(
        to: URL(fileURLWithPath: output),
        atomically: true,
        encoding: .utf8
      )
    } catch {
      throw GeneratorError("Could not write \(output): \(error.localizedDescription)")
    }
    print("Wrote \(output) with \(catalog.projects.count) projects.")
  }
}
