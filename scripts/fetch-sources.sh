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

# These repositories may exist before their first commit. A missing branch is
# expected; network, permission and other Git errors still fail the build.
for r in LinearAlgebra TensorAlgebra DifferentialGeometry; do
  url="https://github.com/OpenSymbolicRules/$r.git"
  if git ls-remote --exit-code --heads "$url" >/dev/null; then
    if [ -d "$dir/$r/.git" ]; then
      git -C "$dir/$r" fetch -q origin
      git -C "$dir/$r" reset -q --hard origin/HEAD
    else
      git clone -q "$url" "$dir/$r"
    fi
    echo "$r $(git -C "$dir/$r" rev-parse --short HEAD)"
  else
    status=$?
    if [ "$status" -ne 2 ]; then
      echo "Cannot inspect $r (git exit $status)" >&2
      exit "$status"
    fi
    if [ -d "$dir/$r/.git" ]; then
      echo "Stale checkout for empty repository $r: $dir/$r" >&2
      exit 1
    fi
    echo "$r has no branch yet; documentation is pending"
  fi
done
