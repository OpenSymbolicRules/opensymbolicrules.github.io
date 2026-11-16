---
title: The OSR format
weight: 20
description: The OSR v1 interchange format, with a complete rule record as distributed.
---

# The OSR v1 format

An OSR v1 rule set is a JSON document validated by the
[rule-set schema](https://github.com/OpenSymbolicRules/Specification/blob/main/schemas/v1/ruleset.schema.json).
Expressions are OpenMath objects in a JSON encoding (`OMA` applications,
`OMS` symbols from standard content dictionaries, `OMV` variables, `OMI`
integers, `OMBIND` bindings such as `fns1#lambda`), so a rule means the same
thing in every system that maps those symbols.

A rule record has:

- `id` and `legacy_id`: a stable identifier and the identity of the source
  rule (here, a RUBI rule);
- `pattern` and `replacement`: OpenMath objects; an antiderivative rule
  rewrites `int(λx. F)` into `λx. G`;
- `conditions`: explicit side conditions (`relation1#neq`, `relation1#eq`,
  `relation1#gt`, `set1#in` with `setname1#Z`), read semantically on defined
  values; an engine must not apply a rule whose conditions it cannot decide;
- `independent`: matching constraints, the v0.1 `FreeQ`;
- `provenance`: the method and the original sources, with their licenses;
- `verification`: one record per domain, naming the Lean theorem (a proof or
  a counterexample), the toolchain, the Mathlib revision and the source
  digest of the Lean checkout;
- `findings`: migration notes, such as a counterexample or the conditions a
  strengthened variant adds.

The specification currently defines {{< stat "specification.requirements" >}}
numbered requirements (`V1-…`); read them in
[docs/osr-v1.md](https://github.com/OpenSymbolicRules/Specification/blob/main/docs/osr-v1.md).

## A complete rule

{{< example-rule >}}
