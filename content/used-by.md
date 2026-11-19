---
title: Used by
weight: 55
description: Projects that consume the OpenSymbolicRules rule sets.
---

# Used by

Projects that read the OSR v1 files. To be listed, open an issue or a pull
request on this site's repository.

## OpenSymbolicRules.jl

[OpenSymbolicRules.jl](https://github.com/OpenSymbolicRules/OpenSymbolicRules.jl)
([documentation](https://OpenSymbolicRules.github.io/OpenSymbolicRules.jl/dev),
MIT) is a Julia rewrite engine built on
[SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl). It
loads OSR v1 files at macro-expansion time (`@load_osr`), combines rules from
several domains into one engine and can trace every rewrite with its stable
OSR rule `id`; its test fixtures are refreshed from each Verification report.
It is a client of the rule sets, not part of them: OSR is the format and the
rules, the package is one engine that applies them, and its name may change
to make that distinction clearer.

## Computer algebra system benchmarks

[Computer algebra system benchmarks](https://s-celles.github.io/computer_algebra_system_benchmarks/)
([source](https://github.com/s-celles/computer_algebra_system_benchmarks),
MIT) pins the [Integration](https://github.com/OpenSymbolicRules/Integration)
repository as a git submodule and turns its v1 file into a benchmark of
indefinite integrals ("OSR rules"). The integrand of each rule's pattern is
sent to every system the benchmark runs (Giac, SymPy, Symbolics.jl, Maxima,
FriCAS, SageMath, …), and each answer is checked by numerical
differentiation; for rules proved over ℝ it is also compared with the
rule's own result. The rule conditions select the parameter values.

A verdict on this site is about the rule as stated in the fragment, not
about the systems: a rule refuted over ℝ fails under the fragment's
semantics (for example `ln` defined on the positive reals only, or a
degenerate coefficient that RUBI excludes by its rule order), which is often
a domain subtlety rather than a wrong table entry.
