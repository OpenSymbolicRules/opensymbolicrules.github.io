---
title: Pipeline
weight: 40
description: How rules go from source data to verified, distributed artifacts.
---

# Pipeline

```mermaid
flowchart LR
  A["Source rules<br/>RUBI 4.16.1 (Mathematica),<br/>v0.1 JSON rule files"] --> B["Integration converter (Julia)<br/>JSON + JSON Schema"]
  B --> C["Lean 4 + Mathlib<br/>statements, proofs,<br/>counterexamples"]
  C --> D["Export<br/>v1 rule sets, reports,<br/>conformance cases"]
  D --> E["Verification<br/>report per source digest,<br/>rechecked byte for byte"]
  E --> F["Domain repositories<br/>v1/ artifacts"]
  E --> G["Conformance suites"]
  F --> H["Engines and clients<br/>OpenSymbolicRules.jl, any CAS"]
  G --> H
```

1. **Conversion.** The Integration converter turns RUBI rules into the v0.1
   JSON format; the faithfulness check compares every v1 rule with its source
   rule.
2. **Statement and proof.** The Lean repository states each rule as a
   theorem per domain and proves it or proves a counterexample; the kernel
   replays every module.
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
