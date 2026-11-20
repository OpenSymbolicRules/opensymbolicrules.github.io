---
title: The power rule, refuted and corrected
weight: 1
description: The textbook derivative and antiderivative power rules, stated on their own, fail at degenerate parameters; Lean counterexamples and a proved corrected variant.
---

# The power rule, refuted and corrected

A rule that a computer algebra system applies inside a long rewriting
strategy can rely on earlier rules having handled the degenerate cases. A rule
published on its own cannot: OSR v1 states each rule as a theorem, for every
assignment of its metavariables that satisfies its conditions. Stated this
way, two classical forms of the power rule are false.

## The derivative power rule

The Calculus v0.1 rule `d/dx xⁿ = n xⁿ⁻¹` had no condition besides
independence of `n` from `x`. At `n = 0` and `x = 0`, `x⁰` is defined around
`0` but `0 · x⁻¹` is not defined at `0`, so the rule produces an undefined
expression from a defined one. Lean establishes the counterexample:

{{< rule id="calculus.derivative.power" >}}

With the condition `n ≠ 0`, the rule holds over ℝ and over ℂ; the corrected
variant is proved, and an engine applies it whenever `n` is a number other
than `0`, so `d/dx x³ = 3 x²` is rewritten while `x⁰` and `xⁿ` are left alone:

{{< rule id="calculus.derivative.power_nonzero" >}}

## The antiderivative of a power of a linear function

RUBI 4.16.1 rule 1.1.1.1 #4 integrates `(a + b x)^m` under the single
condition `m ≠ -1`. At `b = 0` the integrand is a constant, defined
everywhere, while the result divides by `b (m + 1) = 0`. RUBI excludes this
case by its rule order or by evaluation; the rule stated on its own is
refuted:

{{< rule id="integration.linear_power" >}}

The **strengthened variant** appends the missing non-degeneracy condition to
the converted RUBI conditions, keeps the same pattern, replacement and
`legacy_id`, and is proved over ℝ and ℂ:

{{< rule id="integration.linear_power_nondegenerate" >}}

The plain power rule `∫ x^m dx = x^(m+1)/(m+1)` for `m ≠ -1` has no such
degenerate case and is proved as stated:

{{< rule id="integration.power" >}}

## Why the refuted rule stays

The refuted rule is not deleted or silently repaired: it remains in the rule
set with its counterexample, so a consumer who imports RUBI's rule as
written learns exactly where it fails. The corrected variant is a separate,
clearly labelled rule (see [strengthened variants](../strengthened-variants/)).
