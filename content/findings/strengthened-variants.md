---
title: Strengthened variants
weight: 2
description: Corrected variants of refuted RUBI rules, with the non-degeneracy condition they add and their Lean proofs.
---

# Strengthened variants of refuted RUBI rules

Most refutations in the Integration audit come from a degenerate coefficient:
at `b = 0`, `c = 0` or `m = -1` the integrand is defined everywhere while the
result divides by zero. RUBI handles these cases by rule order or by
evaluation; an OSR v1 rule is stated on its own, so the converted rule is
false.

A **strengthened rule** (Specification requirement V1-R-005e) is a corrected
variant:

- a new `id`, by convention the id of the rule as stated with the suffix
  `_nondegenerate`, and the same `legacy_id`;
- the same pattern and replacement as the converted RUBI rule;
- the converted conditions, **followed by** the added conditions, declared in
  a finding beginning with `strengthened:`;
- the refuted rule as stated stays in the rule set, with its counterexample.

The Integration faithfulness check accepts the added conditions only with the
`strengthened:` finding and counts strengthened rules separately.

The current rule set has {{< stat "sets.integration.strengthened" >}}
strengthened variants:

{{< variants >}}

They are a first batch. A numerical triage of the refuted rules, described in
the [Lean Integration documentation](https://github.com/OpenSymbolicRules/Lean/blob/main/docs/integration.md),
lists further candidate variants to be proved family by family.
