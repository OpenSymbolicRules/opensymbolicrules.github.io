---
title: Vocabulary
weight: 25
description: The terms used on this site and in the OSR v1 specification, in one place.
---

# Vocabulary

The terms used on this site, in the rule sets and in the
[OSR v1 specification](https://github.com/OpenSymbolicRules/Specification/blob/main/docs/osr-v1.md),
in alphabetical order. A reference such as V1-R-005 points to the
requirement of the specification that defines the term.

**Antiderivative rule.** A rule `int(λx. F) → λx. G`: where `F` is defined on
a neighbourhood of a point, `G` is defined there and has derivative `F`
(V1-R-005c). Its Lean statement is `AntiderivHoldsUnder`, `AntiderivRecHolds`
when the result has residual integrals, or `AntiderivSubstHolds` when some of
them are evaluated at a substitution.

**Assurance.** How closely the Lean interpretation of an OpenMath symbol in a
domain matches its content dictionary: `formally_related` (a CMP of the CD is
proved in Lean), `reviewed` (checked by hand against the CD), `provisional`, or
`unsupported` (no interpretation in that domain) (V1-S-001). A rule's
`mapping_assurance` is the weakest assurance among its symbols.

**Certified.** A rule is certified in a domain when it is proved there and
every symbol it uses has a `reviewed` or `formally_related` interpretation in
that domain (V1-V-003). Certification is per domain: a rule can be certified
over ℝ and not over ℂ. By default, an engine applies only certified rules
(V1-C-002).

**CMP.** A *commented mathematical property* of an OpenMath content
dictionary, for example `a>b and b>c implies a>c` for `relation1#gt`. The
registry lists, for each symbol and domain, the CMPs proved in Lean.

**Condition.** An explicit side condition of a rule, on its metavariables
only: `relation1#neq`, `eq`, `gt`, `geq`, membership in the integers
(`set1#in` with `setname1#Z`), and `logic1#or` of two conditions (V1-R-005).
Its operands must be defined. A condition with no meaning in a domain (an
order over ℂ) makes the rule *unsupported* there. RUBI's compound conditions
(`And`, `Or`, `Not`) are put in conjunctive normal form before they are
stated.

**Content dictionary (CD).** An OpenMath document defining a family of
symbols, such as `transc1` (elementary transcendental functions). The CDs used
are pinned by version and hash.

**Counterexample.** A Lean theorem refuting a rule as stated: an assignment
of its metavariables for which the conditions hold and the pattern is defined
near a point, while the replacement is not defined there, or does not have the
required value or derivative. Its finding gives the assignment in words.

**Defined.** Every operation of the fragment has a domain of definition:
division by a nonzero value, `ln` on the positive reals (over ℝ), a power for
an integer exponent, `√` of a nonnegative value, and so on. A rule says
nothing where its pattern is undefined, and must not produce an undefined
expression from a defined one.

**Domain.** The carrier in which a rule is interpreted and checked: ℝ (`real`),
ℂ (`complex`), or the Booleans (`boolean`, for the Logic rules).

**Finding.** A sentence attached to a rule that records something a reader
should know: the counterexample, a condition added or translated, a variable
declared independent, why a domain is not covered. Findings start with a
fixed prefix (`counterexample:`, `strengthened:`, `numerical:`,
`independence:`, `complex:`, …); the faithfulness check reads `strengthened:`
and `independence:`.

**Fragment.** The part of OpenMath that OSR v1 interprets: integers,
variables, the registered symbols with a fixed arity, lambdas and residual
integrals (V1-E-002). Floats, strings and attributions are outside it. A rule
that needs something outside the fragment is *not migrated*.

**Independent.** A metavariable whose match must not mention the bound
variable of the input, RUBI's `FreeQ` (V1-R-005b). It is a matching
constraint, not a mathematical condition.

**Lean.** The proof assistant in which every rule statement, proof and
counterexample is written and checked, with Mathlib. The proofs are rebuilt
and checked by the [pipeline](/pipeline/).

**Legacy id.** The identifier of the rule a v1 rule was migrated from (for
example a RUBI file and rule number). A strengthened variant shares the legacy
id of the rule it corrects.

**Metavariable.** A variable of a rule's pattern that matches a subterm of the
input (`a`, `b`, `n`, …), as opposed to the bound variable `x`.

**Not migrated.** A rule that was considered but cannot be stated in OSR v1
yet, with the reason (for example an integrand that is nowhere defined in the
fragment). It is listed, never dropped silently (V1-R-005a).

**OpenMath.** The standard for representing mathematical objects that OSR v1
uses for patterns, replacements and conditions, in its JSON encoding.

**Pattern, replacement.** The two sides of a rule: an input that matches the
pattern is rewritten to the replacement, with the matched subterms
substituted.

**Proved.** A Lean proof that the rule, as stated, holds in a domain: for
every assignment satisfying its conditions, wherever the pattern is defined
the replacement is defined and has the same value (or, for calculus rules,
the required derivative, limit or antiderivative). A proof is about the rule
in the fragment, not about any computer algebra system.

**Refuted.** A rule with a counterexample in at least one domain. For a
migrated RUBI rule, this is usually a degenerate case (a coefficient equal to
zero, a logarithm of a negative number, a pole) that RUBI excludes by its rule
order or by evaluation, rather than a wrong table entry. **Refuted,
corrected** means a strengthened variant is proved.

**Residual integral.** An integral left in the result of an antiderivative
rule, `int(λx. H)(x)`, or `int(λx. H)(g)` when RUBI writes
`Subst[Int[H, x], x, g]` (V1-E-002b). The rule holds for every choice of
antiderivatives of the residual integrands; an engine must be able to rewrite
inside them before applying such a rule.

**RUBI.** Rule-based integration, a large set of integration rules written for
Mathematica. Its v0.1 transcription is the source of the Integration rule set.

**Rule set.** A file `v1/<name>.osr.json` of one repository (Trigonometry,
Algebra, Logic, Calculus, Integration), with its rules, symbol table, profiles
and verification records.

**Source digest.** The SHA-256 of the Lean sources a report was built from.
Rebuilding at that digest reproduces the report byte for byte (V1-V-005); the
[History](/history/) page lists the reports.

**Strengthened variant.** A corrected copy of a refuted rule: the converted
conditions plus one or more non-degeneracy conditions, under a new id with the
same legacy id and a `strengthened:` finding (V1-R-005e). The refuted rule is
kept as stated. A variant may be distributed **unproved**, with numerical
evidence in a `numerical:` finding.

**Unproved, unsupported.** *Unproved*: neither a proof nor a counterexample
yet in that domain. *Unsupported*: the rule has no meaning in that domain, for
example a condition with an order over ℂ.

**v0.1, v1.** v0.1 is the earlier, informal format of the rule sets
(Mathematica-like heads and string constraints); v1 is the current OpenMath
format with typed conditions, provenance and Lean verification records.
