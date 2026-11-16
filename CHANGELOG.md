# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
