import ArgumentParser
import Foundation

@main
struct GenerateReadme: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "generate-readme",
    abstract: "Generate README.md from the project data and Markdown templates."
  )

  @Option(help: "The YAML file listing categories, projects, and resources.")
  var data = "data/projects.yml"

  @Option(help: "The directory containing header.md and footer.md.")
  var templates = "Templates"

  @Option(help: "Where to write the generated Markdown.")
  var output = "README.md"

  @Flag(
    help: """
      Add stars, last push date, and archived status from the GitHub API. \
      Requires the GITHUB_TOKEN environment variable.
      """
  )
  var fetchMetadata = false

  func run() async throws {
    let catalog = try Catalog.load(from: URL(fileURLWithPath: data))
    try CatalogValidator.validate(catalog)

    let templatesURL = URL(fileURLWithPath: templates, isDirectory: true)
    var renderer = ReadmeRenderer(
      header: try template(named: "header.md", in: templatesURL),
      footer: try template(named: "footer.md", in: templatesURL)
    )
    if fetchMetadata {
      renderer.metadata = await fetchMetadata(for: catalog.projects)
    }

    let readme = renderer.render(catalog)
    do {
      try readme.write(to: URL(fileURLWithPath: output), atomically: true, encoding: .utf8)
    } catch {
      throw GeneratorError("Could not write \(output): \(error.localizedDescription)")
    }
    print("Wrote \(output) with \(catalog.projects.count) projects.")
  }

  private func template(named name: String, in directory: URL) throws -> String {
    let url = directory.appendingPathComponent(name)
    do {
      return try String(contentsOf: url, encoding: .utf8)
    } catch {
      throw GeneratorError("Could not read template \(url.path): \(error.localizedDescription)")
    }
  }

  private func fetchMetadata(for projects: [Project]) async -> [String: RepositoryMetadata] {
    let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] ?? ""
    guard !token.isEmpty else {
      printError("GITHUB_TOKEN is not set; generating without GitHub metadata.")
      return [:]
    }
    let urls = projects.map(\.url)
    let metadata = await GitHubMetadataFetcher(token: token).metadata(forURLs: urls)
    let repositoryCount = Set(urls.compactMap(GitHubRepository.init(url:))).count
    printError("Fetched GitHub metadata for \(metadata.count) of \(repositoryCount) repositories.")
    return metadata
  }

  private func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
  }
}
