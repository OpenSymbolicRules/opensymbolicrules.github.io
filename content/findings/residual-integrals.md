---
title: Residual integrals in RUBI rules
weight: 3
description: How OSR v1 states and verifies RUBI rules whose result contains further integrals.
---

# Residual integrals in RUBI rules

Most RUBI rules do not produce a closed form: they rewrite an integral into
an expression that contains further integrals, which the rewriting continues
on. OSR v1 encodes such a residual integral as `int(λx. H)(x)` (the FMP form
of the OpenMath `calculus1#int` symbol) and states the rule for **every**
choice of antiderivatives of the residual integrands: whatever antiderivatives
a consumer finds later, the result is an antiderivative of the original
integrand (Specification V1-R-005c).

In the current Integration rule set, the rules with residual integrals have
the following statuses:

{{< residual >}}

## A proved rule with residual integrals

{{< rule id="integration.sin_add_square" >}}

## A refuted rule with a residual integral

Here the original integrand is defined, but a residual integrand is not:

{{< rule id="integration.log_power_log" >}}

## Consequence for engines

An engine must not apply a rule with residual integrals unless it can
continue rewriting inside them; the reference rewriters do not apply them.
The statement composes, which is what a rewriter that continues inside
residual integrals needs.
