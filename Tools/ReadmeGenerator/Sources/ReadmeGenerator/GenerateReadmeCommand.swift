//
//  GenerateReadmeCommand.swift
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

public import ConfigKeyKit
import Configuration
import Foundation

/// Generates `README.md` from the project data and Markdown templates.
public struct GenerateReadmeCommand: Command {
  public static let commandName = "generate-readme"
  public static let abstract =
    "Generate README.md from the project data and Markdown templates."
  public static let helpText = """
    OVERVIEW: \(abstract)

    USAGE: generate-readme [options]

    OPTIONS:
      --data <path>       The project data YAML file. (default: data/projects.yml)
      --templates <path>  The folder with header.md and footer.md. (default: Templates)
      --output <path>     Where to write the README. (default: README.md)
      --fetch-metadata    Add GitHub stars, last update, and archived status.
      -h, --help          Show help information.

    --fetch-metadata reads the token from the GITHUB_TOKEN environment variable.
    Each option can also be set with an environment variable, such as OUTPUT.
    """

  private let config: Config

  public init(config: Config) {
    self.config = config
  }

  /// Reads the configuration from the command line, then the environment.
  public static func createInstance() async -> Self {
    let reader = ConfigReader(providers: [
      CommandLineArgumentsProvider(),
      EnvironmentVariablesProvider(),
    ])
    return Self(config: Config(configuration: reader, base: nil))
  }

  public func execute() async throws(ReadmeGeneratorError) {
    let catalog = try Catalog(contentsOf: URL(fileURLWithPath: config.dataPath))
    try catalog.validate()

    let templates = URL(fileURLWithPath: config.templatesPath, isDirectory: true)
    let headerURL = templates.appendingPathComponent("header.md")
    let footerURL = templates.appendingPathComponent("footer.md")
    var renderer = ReadmeRenderer(
      header: try MarkdownTemplate(contentsOf: headerURL),
      footer: try MarkdownTemplate(contentsOf: footerURL)
    )
    if config.fetchMetadata {
      renderer.metadata = await metadata(for: catalog.projects)
    }

    let readme = renderer.render(catalog)
    do {
      try readme.write(
        to: URL(fileURLWithPath: config.outputPath),
        atomically: true,
        encoding: .utf8
      )
    } catch {
      throw .unwritableOutput(path: config.outputPath, reason: error.localizedDescription)
    }
    print("Wrote \(config.outputPath) with \(catalog.projects.count) projects.")
  }

  private func metadata(for projects: [Project]) async -> [String: RepositoryMetadata] {
    guard let token = config.githubToken, !token.isEmpty else {
      printError("GITHUB_TOKEN is not set; generating without GitHub metadata.")
      return [:]
    }
    let urls = projects.map(\.url)
    let fetcher = GitHubMetadataFetcher(token: token, apiURL: config.githubAPIURL)
    let metadata = await fetcher.metadata(forURLs: urls)
    let repositoryCount = Set(urls.compactMap(GitHubRepository.init(url:))).count
    printError(
      "Fetched GitHub metadata for \(metadata.count) of \(repositoryCount) repositories."
    )
    return metadata
  }

  private func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
  }
}
