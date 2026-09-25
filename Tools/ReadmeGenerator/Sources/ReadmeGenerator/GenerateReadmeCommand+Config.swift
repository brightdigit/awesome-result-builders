//
//  GenerateReadmeCommand+Config.swift
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
public import Configuration

extension GenerateReadmeCommand {
  /// Options for ``GenerateReadmeCommand``.
  ///
  /// Each value comes from its command-line flag (such as `--output`), then
  /// the matching environment variable (such as `OUTPUT`), then the default.
  /// The GitHub token is read from `GITHUB_TOKEN`.
  public struct Config: ConfigurationParseable, Codable, Equatable {
    public typealias ConfigReader = Configuration.ConfigReader
    public typealias BaseConfig = Never

    private static let dataKey = ConfigKey<String>("data", default: "data/projects.yml")
    private static let templatesKey = ConfigKey<String>("templates", default: "Templates")
    private static let outputKey = ConfigKey<String>("output", default: "README.md")
    private static let fetchMetadataKey = ConfigKey<Bool>("fetch.metadata")
    private static let githubTokenKey = OptionalConfigKey<String>(
      cli: "github.token",
      env: "GITHUB_TOKEN",
      isSecret: true
    )
    private static let githubAPIURLKey = ConfigKey<String>(
      "github.api.url",
      default: "https://api.github.com"
    )

    public let dataPath: String
    public let templatesPath: String
    public let outputPath: String
    public let fetchMetadata: Bool
    public let githubToken: String?
    /// The GitHub REST API root; only changed to test against another server.
    public let githubAPIURL: String

    public init(
      dataPath: String,
      templatesPath: String,
      outputPath: String,
      fetchMetadata: Bool,
      githubToken: String?,
      githubAPIURL: String
    ) {
      self.dataPath = dataPath
      self.templatesPath = templatesPath
      self.outputPath = outputPath
      self.fetchMetadata = fetchMetadata
      self.githubToken = githubToken
      self.githubAPIURL = githubAPIURL
    }

    public init(configuration reader: ConfigReader, base _: Never?) {
      self.init(
        dataPath: reader.read(Self.dataKey),
        templatesPath: reader.read(Self.templatesKey),
        outputPath: reader.read(Self.outputKey),
        fetchMetadata: reader.read(Self.fetchMetadataKey),
        githubToken: reader.read(Self.githubTokenKey),
        githubAPIURL: reader.read(Self.githubAPIURLKey)
      )
    }
  }
}
