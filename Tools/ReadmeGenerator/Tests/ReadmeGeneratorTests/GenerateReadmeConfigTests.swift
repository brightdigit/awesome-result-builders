import Configuration
import Testing

@testable import ReadmeGenerator

internal struct GenerateReadmeConfigTests {
  @Test internal func usesDefaultsWhenNothingIsSet() {
    let reader = ConfigReader(providers: [
      CommandLineArgumentsProvider(arguments: ["generate-readme"]),
      EnvironmentVariablesProvider(environmentVariables: [:]),
    ])
    let config = GenerateReadmeCommand.Config(configuration: reader, base: nil)
    #expect(
      config
        == GenerateReadmeCommand.Config(
          dataPath: "data/projects.yml",
          templatesPath: "Templates",
          outputPath: "README.md",
          fetchMetadata: false,
          githubToken: nil,
          githubAPIURL: "https://api.github.com"
        )
    )
  }

  @Test internal func readsFlagsAndTheGitHubToken() {
    let reader = ConfigReader(providers: [
      CommandLineArgumentsProvider(arguments: [
        "generate-readme", "--output", "/tmp/README.md", "--fetch-metadata",
      ]),
      EnvironmentVariablesProvider(environmentVariables: ["GITHUB_TOKEN": "secret"]),
    ])
    let config = GenerateReadmeCommand.Config(configuration: reader, base: nil)
    #expect(config.outputPath == "/tmp/README.md")
    #expect(config.fetchMetadata)
    #expect(config.githubToken == "secret")
    #expect(config.dataPath == "data/projects.yml")
  }
}
