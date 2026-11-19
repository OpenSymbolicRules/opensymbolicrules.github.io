# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- "Used by" page listing the projects that consume the OSR v1 files,
  starting with the computer algebra system benchmarks.
- "Progress over time" on the home page: rules exported and their status
  (proved, refuted, unproved) over ℝ and over ℂ for every Verification
  report, as two small multiples on one scale with a hover crosshair, direct
  labels and a table view. `sitegen` reads the series from the Verification
  history into `data/generated/history.json` (`verification_history`).

### Changed
- The home page tile on strengthened variants no longer says they are all
  proved: some are distributed unproved with numerical evidence.

- Registry status "strengthened, unproved" for corrected variants distributed
  with numerical evidence before their proof.
- Visual identity of the organization (OpenSymbolicRules/.github banner):
  banner on the home page, logo, favicon and social preview derived at build
  time by `scripts/brand-assets.py`, and an `osr` light/dark color theme
  (navy, teal, amber, cream) with accessible link contrast.
- Work-in-progress notice on every page and a "Work in progress" section in
  the disclaimer (coverage, pre-release format, provisional statuses, scope of
  the verified statements, tooling); the size of the v0.1 source corpus is
  generated from each repository's `rules/` tree.
- Hugo site with the vendored Hugo Book theme (v13): home page with key
  figures and the repository table, findings registry, pages on the refuted
  power rules, strengthened variants and residual integrals, the OSR v1
  format, one page per domain, the pipeline, contributing, disclaimer and
  provenance.
- `sitegen` (Julia): generates the registry, statistics, repository table
  and example rule from read-only checkouts of the public repositories, with
  the repository, commit and file of every record; OpenMath objects rendered
  as infix text; tests with TestItemRunner.
- Findings registry with column filters and multi-column sort in vanilla
  JavaScript, the state kept in the URL query.
- `llms.txt` and `llms-full.txt`, generated at every build.
- Internal link check of the built site, including the links of the
  `llms*.txt` files.
- Pages workflow: pinned, checksummed Hugo Extended 0.170.0 and Dart Sass
  1.108.2, generator tests, build without warnings, link check and
  deployment; daily rebuild. Dependabot for actions and the generator.
