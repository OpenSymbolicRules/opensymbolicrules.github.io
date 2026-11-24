---
title: Pipeline
weight: 40
description: How rules go from source data to verified, distributed artifacts.
---

# Pipeline

{{< workflow >}}

1. **Conversion.** The Integration converter turns RUBI rules into the v0.1
   JSON format; the faithfulness check compares every v1 rule with its source
   rule.
2. **Statement and proof.** For each selected rule, Lean states a theorem with explicit
   hypotheses for a mathematical domain. The kernel checks completed proofs
   and counterexamples. Open cases keep their verification status.
3. **Export.** The exporter writes the v1 rule sets, the verification
   reports and the conformance cases; two exports must be byte-identical.
4. **Publication.** Each export becomes a Verification report named after the
   source digest of the Lean checkout, and `scripts/recheck.sh` reproduces it
   byte for byte. Currently: {{< repo-head "Verification" >}}, with
   {{< stat "verification.reports" >}} reports.
5. **Distribution.** The domain repositories, the Conformance suites
   ({{< stat "conformance.total" >}} cases, {{< repo-head "Conformance" >}})
   and the client fixtures are copied from a published report and checked
   against it.
