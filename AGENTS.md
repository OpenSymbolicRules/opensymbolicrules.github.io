# Conventions for contributors and coding agents

## Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/):
  `type(scope): summary`, with types `feat`, `fix`, `docs`, `test`, `ci`,
  `refactor`, `chore`. Scopes in use: `sitegen`, `content`, `layouts`,
  `theme`, `ci`.
- AI-assisted commits end with the trailer `Assisted-by: AI`: no model or
  tool name, no `Co-Authored-By` line for the assistant, and no
  "Generated with ..." banner anywhere.
- Do not commit or push unless asked; push to the `origin-bot` remote.
- Record notable changes in `CHANGELOG.md` (Keep a Changelog); the project
  follows Semantic Versioning.

## Repository rules

- **No number is typed by hand.** Every figure, status, condition,
  counterexample and commit on the site comes from `data/generated/`, written
  by `just sitegen` from read-only checkouts of the public repositories. Pages
  use the shortcodes (`stat`, `rule`, `domain`, `variants`, …); a wrong
  figure is fixed in the generator or in the source repository, never in a
  page.
- **Provenance.** Every generated record keeps `repo`, `commit`, `path` and
  `date`; keep that when adding data, and show it next to the figure.
- `data/generated/` is not committed and is never edited.
- **Tests first.** Change `sitegen/src/SiteGen.jl` only with a test in
  `sitegen/test/` (TestItemRunner); run `just test`.
- **No warnings.** `just build` runs Hugo with `--panicOnWarning` and the
  internal link check; both must pass before a commit.
- **Vendored theme.** `themes/hugo-book/` is unmodified upstream code;
  override in `layouts/` and record the override in `themes/VENDORED.md`.
- **Pinned tools.** Hugo and Dart Sass versions live in `hugo-version` and
  `dart-sass-version`, with checksums verified by `scripts/install-tools.sh`
  (`scripts/dart-sass.sha256` for Dart Sass). Bump them together with a
  build.
- **Independence.** Keep the disclaimer: the project is not affiliated with
  Wolfram Research, the RUBI authors, the Lean FRO, Mathlib or the OpenMath
  Society. Imitate the patterns of other sites, never their content.
- **Visual identity.** It is defined by the banner of
  `OpenSymbolicRules/.github`; derive assets with `scripts/brand-assets.py`
  (tested by `scripts/test_brand_assets.py`) and keep the `theme-osr`
  palette, never a hand-copied image.
- Content is in English.
- `llms.txt` and `llms-full.txt` are output formats of the home page
  (`layouts/home.llms.txt`, `layouts/home.llmsfull.txt`); a new page appears
  in them automatically. Check them after changing the page tree.

## Layout

See `README.md` for the layout, the build, and how to add a finding page or
a domain.
