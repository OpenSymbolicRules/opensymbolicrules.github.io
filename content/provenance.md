---
title: Provenance
weight: 70
description: How every figure on this site is traced to a repository, a commit and a file.
---

# Provenance

No figure on this site is typed by hand. At build time,
`scripts/fetch-sources.sh` clones the public repositories read-only and
`sitegen` (Julia) reads:

| Data | Read from |
|---|---|
| Rules, conditions, findings, statuses | `v1/<set>.osr.json` of each domain repository |
| Rules not migrated, metrics | `v1/<set>.report.json` |
| Size of the source corpus (v0.1 rules) | the `rules/` tree of each domain repository |
| Lean toolchain, Mathlib revision, source digest | the `build` record of each rule set |
| Repository descriptions | `Specification/ecosystem.json`, then the site's `sitegen/repos.toml` for repositories it does not list |
| Changelog entries | the first section of each `CHANGELOG.md` |
| Requirements | `Specification/docs/osr-v1.md` |
| Conformance cases | `Conformance/suites/<set>/<set>.cases.json` |
| Verification reports | the directories of `Verification/reports/` |
| Commits | `git rev-parse`, `git log` and `git rev-list --count` of each checkout |
| Visual identity (banner, logo, favicon, preview image) | `profile/assets/banner.png` of the organization repository `OpenSymbolicRules/.github`, derived by `scripts/brand-assets.py` |

Every registry row and every figure links to `repository@commit` and the file
it was read from, and the date of that commit. A rule's verification record
also carries the Lean source digest, which names the
[Verification](https://github.com/OpenSymbolicRules/Verification) report
that reproduces it.

This build read:

{{< repos >}}
