---
title: OpenSymbolicRules
description: Open, language-neutral rewrite rules for computer algebra, with explicit validity conditions and Lean proofs or counterexamples.
cascade:
  type: docs
bookToC: false
---

# OpenSymbolicRules

OpenSymbolicRules publishes rewrite rules for computer algebra as plain JSON
data, validated by JSON Schema and written with OpenMath symbols, so that any
system can load them. Every rule states its conditions of validity, and each
verified rule set records, per domain, a Lean 4 proof or a Lean
counterexample. Classical rules that turn out to be false as stated are kept
with their counterexample, and corrected variants are published next to them:
rules become auditable objects instead of opaque system code.

{{< stats >}}

## Repositories

{{< repos >}}

The figures on this site are generated from the repositories at the commits
shown; see [Provenance](/provenance/) for how each one is traced. This is an
independent project; see the [disclaimer](/disclaimer/).
