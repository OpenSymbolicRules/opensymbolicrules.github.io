---
title: OpenSymbolicRules
description: Open, language-neutral rewrite rules for computer algebra, with explicit validity conditions and Lean proofs or counterexamples.
cascade:
  type: docs
bookToC: false
---

<div class="osr-hero"><img src="/generated/brand/banner.png" width="2170" height="725" alt="OpenSymbolicRules: an expression tree a × b + 0 rewritten to a × b. Open, interoperable rules for symbolic mathematics."></div>

# OpenSymbolicRules

<p class="osr-tagline">Open, interoperable rules for symbolic mathematics.</p>

OpenSymbolicRules publishes rewrite rules for computer algebra as plain JSON
data, validated by JSON Schema and written with OpenMath symbols, so that any
system can load them. Every rule states its conditions of validity, and each
verified rule set records, per domain, a Lean 4 proof or a Lean
counterexample. Classical rules that turn out to be false as stated are kept
with their counterexample, and corrected variants are published next to them:
rules become auditable objects instead of opaque system code.

{{< stats >}}

## Progress over time

{{< history >}}

## Repositories

{{< repos >}}

The figures on this site are generated from the repositories at the commits
shown; see [Provenance](/provenance/) for how each one is traced. This is an
independent project; see the [disclaimer](/disclaimer/).
