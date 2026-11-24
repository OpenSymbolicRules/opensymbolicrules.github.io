---
title: Findings registry
weight: 10
description: Every rule of the OSR v1 rule sets with its status, conditions of validity, counterexample and provenance.
bookToC: false
layout: wide
---

# Findings registry

This table lists the verification status of exported v1 rules and the reasons recorded for source rules considered but not migrated. Filter any column with the fields under the headers;
click a header to sort, and shift-click further headers to sort by several
columns. A filter accepts several words, all of which must match.

Statuses (see also the [Vocabulary](/vocabulary/)):

- **proved**: a Lean proof in every supported domain;
- **refuted**: a Lean counterexample in at least one domain;
- **refuted, corrected**: refuted, and a strengthened variant is proved;
- **strengthened**: a corrected variant: the converted conditions plus a
  non-degeneracy condition, proved (Specification V1-R-005e);
- **strengthened, unproved**: a corrected variant distributed before its
  proof, with the numerical evidence given in a `numerical:` finding;
- **generalized**: an independently proved derived variant whose conditions
  differ from the RUBI source; the source rule remains available;
- **unproved**, **unsupported**: no proof or counterexample yet, or a
  condition with no meaning in the domain;
- **not migrated**: considered, but not expressible in OSR v1 yet (the reason
  is given).

The domain columns read **certified** (proved, with a reviewed mapping of the
symbols), **proved**, **refuted**, **unproved** or **unsupported**.

Major findings have their own pages:

- [The power rule, refuted and corrected](power-rule/)
- [Strengthened variants of refuted RUBI rules](strengthened-variants/)
- [Residual integrals in RUBI rules](residual-integrals/)

{{< registry >}}
