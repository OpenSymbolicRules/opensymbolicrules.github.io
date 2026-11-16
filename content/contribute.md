---
title: Contribute
weight: 50
description: How to contribute rules, proofs, engines or fixes to OpenSymbolicRules.
---

# Contribute

- **Report a wrong rule.** Open an issue in the domain repository with the
  rule `id`, the assignment that breaks it, and the system and version you
  checked it with.
- **Prove or refute a rule.** Lean statements live in the
  [Lean repository](https://github.com/OpenSymbolicRules/Lean); every
  unproved rule is a candidate. A proof or counterexample changes the
  published status once it is exported and published as a Verification
  report.
- **Propose a strengthened variant.** Follow Specification V1-R-005e: keep
  the converted conditions, append yours, declare them in a `strengthened:`
  finding, and keep the refuted rule.
- **Write an engine or client.** Load the `v1/` rule sets, map the OpenMath
  symbols, and run the [Conformance](https://github.com/OpenSymbolicRules/Conformance)
  suites.
- **Improve this site.** See the
  [site repository](https://github.com/OpenSymbolicRules/opensymbolicrules.github.io):
  data are generated, so fix the generator or the source repository rather
  than the page.
