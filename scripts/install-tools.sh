#!/usr/bin/env bash
# Install the pinned Hugo Extended and Dart Sass into DIR (default .tools),
# verifying their SHA-256 checksums.  Linux x86-64 only.
set -euo pipefail
dir=${1:-.tools}
here=$(cd "$(dirname "$0")/.." && pwd)
hugo_version=$(cat "$here/hugo-version")
sass_version=$(cat "$here/dart-sass-version")
mkdir -p "$dir"
cd "$dir"

hugo_tar="hugo_extended_${hugo_version}_linux-amd64.tar.gz"
if [ ! -x hugo ] || ! ./hugo version | grep -q "v${hugo_version}-"; then
  curl -sSLO "https://github.com/gohugoio/hugo/releases/download/v${hugo_version}/${hugo_tar}"
  curl -sSLO "https://github.com/gohugoio/hugo/releases/download/v${hugo_version}/hugo_${hugo_version}_checksums.txt"
  grep " ${hugo_tar}\$" "hugo_${hugo_version}_checksums.txt" | sha256sum -c -
  tar xzf "$hugo_tar" hugo
  rm -f "$hugo_tar" "hugo_${hugo_version}_checksums.txt"
fi

sass_tar="dart-sass-${sass_version}-linux-x64.tar.gz"
if [ ! -x dart-sass/sass ] || [ "$(dart-sass/sass --version)" != "$sass_version" ]; then
  curl -sSLO "https://github.com/sass/dart-sass/releases/download/${sass_version}/${sass_tar}"
  # Dart Sass publishes no checksum file; the expected digest is pinned here.
  grep -q "^${sass_version} " "$here/scripts/dart-sass.sha256" ||
    { echo "no pinned checksum for Dart Sass ${sass_version} in scripts/dart-sass.sha256" >&2; exit 1; }
  echo "$(grep "^${sass_version} " "$here/scripts/dart-sass.sha256" | cut -d' ' -f2)  ${sass_tar}" | sha256sum -c -
  rm -rf dart-sass
  tar xzf "$sass_tar"
  rm -f "$sass_tar"
fi
./hugo version
echo "dart-sass $(dart-sass/sass --version)"
