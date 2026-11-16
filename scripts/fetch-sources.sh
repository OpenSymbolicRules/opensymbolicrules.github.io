#!/usr/bin/env bash
# Clone the public OpenSymbolicRules repositories read-only into DIR (default
# .sources), or update existing clones.  The site is generated from these
# checkouts only, so every number it shows is tied to a commit.
set -euo pipefail
dir=${1:-.sources}
repos=(.github Specification Integration Lean Verification Conformance Calculus Algebra Trigonometry Logic OpenSymbolicRules.jl)
mkdir -p "$dir"
for r in "${repos[@]}"; do
  if [ -d "$dir/$r/.git" ]; then
    git -C "$dir/$r" fetch -q origin
    git -C "$dir/$r" reset -q --hard origin/HEAD
  else
    git clone -q "https://github.com/OpenSymbolicRules/$r.git" "$dir/$r"
  fi
  echo "$r $(git -C "$dir/$r" rev-parse --short HEAD)"
done
