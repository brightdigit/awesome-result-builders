# Contributing

Thanks for helping grow the list! Please read this before opening a pull request.

## Adding or editing an entry

`README.md` is generated. **Don't edit it by hand**; any changes to it are overwritten the next time it's generated. Instead:

1. Add or update the project in [`data/projects.yml`](data/projects.yml):

   ```yaml
   - name: MyBuilderKit
     url: https://github.com/you/MyBuilderKit
     description: One sentence about what the DSL builds.
     category: code-generation
     platforms: [iOS, macOS, Linux] # optional
   ```

   - `category` must be the `id` of one of the `categories` at the top of the file. If none fits, add a new category in the same pull request; categories appear in the README in the order they're listed.
   - Keep the description to one short sentence. A trailing period is added if you leave it off.
   - Each URL may appear only once in the file.
   - Projects are sorted by name within their category, so you can add yours anywhere in the list.

2. Learning resources (proposals, articles, talks) go under `resources`, in the group that fits best.

3. Open a pull request. The **README** workflow builds the generator and shows the rendered README in the run's summary so you can check the result. You don't need to commit a regenerated `README.md`; it's regenerated automatically after your change is merged.

## Inclusion criteria

A project is a good fit when it is:

- **Open source**, with its source publicly available.
- **Built around a result builder.** The result builder DSL should be a primary way to use the project, not an incidental helper or a single internal use.
- **Maintained or notable.** It's actively maintained, or it's influential or instructive enough to be worth knowing about even if it's no longer updated. Archived projects are marked as such in the README.

Please add one project per pull request and briefly say why it belongs.

## Running the generator locally

The generator is a Swift package in [`Tools/ReadmeGenerator`](Tools/ReadmeGenerator) that needs Swift 6.0 or later on macOS or Linux. From the repository root:

```sh
swift run --package-path Tools/ReadmeGenerator generate-readme
```

That validates `data/projects.yml` and writes `README.md`. Useful options:

| Option | Default | Purpose |
| --- | --- | --- |
| `--data <path>` | `data/projects.yml` | Project data to read. |
| `--templates <path>` | `Templates` | Directory containing `header.md` and `footer.md`. |
| `--output <path>` | `README.md` | Where to write the Markdown. |
| `--fetch-metadata` | off | Add GitHub stars, last update, and archived status. Needs `GITHUB_TOKEN`. |

To preview without touching `README.md`, write somewhere else:

```sh
swift run --package-path Tools/ReadmeGenerator generate-readme --output /tmp/README.md
```

To include GitHub metadata, provide a token (a fine-grained token with public read-only access is enough; `gh auth token` works too):

```sh
GITHUB_TOKEN=$(gh auth token) swift run --package-path Tools/ReadmeGenerator generate-readme --fetch-metadata
```

Repositories that can't be looked up, such as private ones, are listed without metadata.

If the generator reports a problem such as an unknown category or a duplicate URL, fix it in `data/projects.yml` and run it again.
