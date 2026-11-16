---
title: Disclaimer
weight: 60
description: OpenSymbolicRules is an independent project.
---

# Disclaimer

## Work in progress

OpenSymbolicRules is a **long-term, ongoing research effort**, not a
finished product. Everything on this site describes the state of the
repositories at the commits shown, and that state changes often.

**Coverage is partial.** The Integration audit has considered
{{< stat "sets.integration.legacy_rules" >}} of the
{{< stat "sets.integration.corpus_rules" >}} RUBI 4.16.1 rules of the
Integration repository; {{< stat "sets.integration.not_migrated" >}} of those
cannot be stated in OSR v1 yet, and the others are not yet considered at all.
Most of them rewrite into further integrals, use constructs the format does
not yet express (square roots and other non-integer powers, special
functions, RUBI's own helper functions), or carry conditions that have no
counterpart yet. The Calculus, Algebra, Trigonometry and Logic rule sets are
small, curated sets.

**The format is a pre-release.** OSR v1 is at version
`{{< stat "sets.integration.osr_format" >}}`. Requirements are still being
added (strengthened rules, V1-R-005e, are recent), and a later version may
change the encoding of rules, conditions or verification records. Breaking
changes will follow Semantic Versioning, but no stability is promised before
1.0.0.

**Statuses are provisional.** A rule listed as *unproved* or *unsupported*
may be proved or refuted later; a *refuted* rule may receive a corrected
variant; a new counterexample may refute a rule that was not yet examined in
a domain. Over ℂ, {{< stat "sets.integration.complex.unproved" >}} Integration
rule(s) are still unproved and several symbol mappings are not certified.

**The verified statement is OSR's, not RUBI's.** A Lean proof or
counterexample is about the rule as OSR v1 states it on its own, within the
current fragment (for example, powers are interpreted for integer exponents
only). It says nothing about RUBI applied with its rule order, nor about a
particular computer algebra system.

**Tooling is incomplete.** The reference rewriters do not yet apply rules
with residual integrals, and apply conditional rules only when their
conditions can be decided exactly; engines and clients are prototypes.

Use the rules for research and experimentation, check the conditions and
verification records of each rule before relying on it, and report problems
(see [Contribute](/contribute/)).

## Independence

OpenSymbolicRules is an independent, non-commercial project. It is not
affiliated with, endorsed by or sponsored by Wolfram Research (Mathematica),
the authors of RUBI, the Lean FRO, the Mathlib community or the OpenMath
Society. Product and project names belong to their owners and are used only
to identify the sources and tools involved.

RUBI rules are used under the license recorded in their `provenance` (MIT
for RUBI 4.16.1) and keep their
attribution in each rule's `provenance`. A rule's status on this site reflects
the Lean verification at the commit shown, for the statement OSR v1 gives to
the rule on its own; a refutation does not mean that RUBI, applied with its
rule order and evaluation, computes a wrong antiderivative.

The rule sets are provided as they are, without warranty; check the
conditions and the verification records before relying on a rule.
