# opensymbolicrules.github.io

Source of the OpenSymbolicRules web site, <https://opensymbolicrules.github.io/>:
a Hugo site (vendored [Hugo Book](themes/VENDORED.md) theme) whose figures and
findings registry are **generated** from the public OpenSymbolicRules
repositories at every build, each with the repository, commit and file it was
read from.

## Build

Requirements: Linux x86-64, [just](https://github.com/casey/just),
[Julia](https://julialang.org) ≥ 1.10, git and curl. Hugo Extended and Dart
Sass are installed, pinned and checksummed, by `just setup`.

```bash
just setup     # Hugo Extended (hugo-version) and Dart Sass (dart-sass-version) into .tools/
just sources   # clone or update the public repositories into .sources/ (read-only)
just test      # generator tests (TestItemRunner)
just build     # sitegen, then hugo --minify --panicOnWarning, then the link check
just serve     # local server with live reload
```

`just ci` runs everything CI runs. The build fails on any Hugo warning and on
any broken internal link (pages, anchors, and the links of `llms.txt` and
`llms-full.txt`).

## How the site is generated

1. `scripts/fetch-sources.sh` clones Specification, Integration, Lean,
   Verification, Conformance, Calculus, Algebra, Trigonometry, Logic and
   OpenSymbolicRules.jl into `.sources/`.
2. `scripts/sitegen.jl` (package `sitegen/`, module `SiteGen`) reads the
   `v1/*.osr.json` rule sets, their `v1/*.report.json` reports, the
   changelogs, `Specification/ecosystem.json` and `docs/osr-v1.md`, the
   Conformance suites and the Verification reports, and writes
   `data/generated/{registry,stats,repos,example_rule}.json`. Every record
   carries its provenance (`repo`, `commit`, `path`, `date`).
3. Hugo renders the pages in `content/`; the shortcodes in
   `layouts/_shortcodes/` read only `data/generated/`, so no number is typed
   in a page. `llms.txt` and `llms-full.txt` are Hugo output formats of the
   home page (`layouts/home.llms.txt`, `layouts/home.llmsfull.txt`), built
   from the same pages and data.
4. `scripts/check-links.jl` checks the internal links of the output.

`data/generated/` is not committed and must not be edited: fix the generator
or the source repository.

The Pages workflow (`.github/workflows/pages.yml`) runs on pushes to `main`,
on pull requests (build only), daily (to pick up new commits in the source
repositories) and on demand, and deploys `public/` to GitHub Pages.

## Regenerate the registry

```bash
just sources && just build
```

The registry lists every rule of the five `v1/` rule sets and the rules the
Integration audit reports as not migrated. Its statuses are computed by
`SiteGen.classify` from the `verification` records and the `findings`
(`counterexample:`, `strengthened:`) of each rule.

## Add a finding page

A finding page explains a notable rule; its data come from the registry.

1. Write `content/findings/<slug>.md` with `title`, `weight` and
   `description` front matter.
2. Tell the story in prose, without numbers typed by hand: show rules with
   `{{< rule id="<rule id>" >}}` and figures with `{{< stat "<path>" >}}`
   (a path in `stats.json`, such as `sets.integration.strengthened`).
3. Link it from `content/findings/_index.md`.
4. `just build`: an unknown rule id or statistic fails the build.

## Add a domain

1. Add the repository to `scripts/fetch-sources.sh`, and its rule set to
   `SiteGen.DEFAULT_SETS` (set name and repository), with a test.
2. Describe it in `Specification/ecosystem.json` upstream, or in
   `sitegen/repos.toml` while it is not listed there (with its `order`).
3. Write `content/domains/<set>.md` with `{{< domain set="<set>" >}}` and
   link it from `content/domains/_index.md`.

## Layout

| Path | Content |
|---|---|
| `content/` | pages (Markdown, English) |
| `layouts/_shortcodes/` | `stats`, `repos`, `registry`, `rule`, `domain`, `variants`, `residual`, `example-rule`, `stat`, `repo-head` |
| `layouts/_partials/osr/` | data access and provenance links |
| `layouts/_partials/docs/` | overrides of three theme partials (Hugo ≥ 0.158 API, Sass options, home title) |
| `layouts/home.llms*.txt`, `layouts/_partials/llms/` | `llms.txt` and `llms-full.txt` |
| `assets/js/registry.js` | column filters and multi-column sort (vanilla JS) |
| `assets/_custom.scss` | site styles |
| `sitegen/` | the generator (Julia) and its tests |
| `scripts/` | tool installation, source checkout, generation, link check |
| `themes/hugo-book/` | vendored theme, unmodified |

## License

[MIT](LICENSE.md). The vendored theme keeps its own MIT license
(`themes/hugo-book/LICENSE`).
