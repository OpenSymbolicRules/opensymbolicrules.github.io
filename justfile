# Entry points for the OpenSymbolicRules web site.

tools := ".tools"
sources := ".sources"
out := "public"

# Install the pinned Hugo Extended and Dart Sass into .tools.
setup:
	scripts/install-tools.sh {{tools}}
	julia --project=sitegen -e 'using Pkg; Pkg.instantiate()'

# Clone or update the public repositories the site is generated from.
sources:
	scripts/fetch-sources.sh {{sources}}

# Generate data/generated/ from the checkouts.
sitegen:
	julia --project=sitegen scripts/sitegen.jl {{sources}} data/generated

# Run the generator tests.
test:
	julia --project=sitegen -e 'using Pkg; Pkg.test()'

# Build the site into public/ (no warning allowed), then check its internal links.
build: sitegen
	PATH="$PWD/{{tools}}/dart-sass:$PATH" {{tools}}/hugo --minify --panicOnWarning --cleanDestinationDir -d {{out}}
	julia --project=sitegen scripts/check-links.jl {{out}}

# Serve the site locally with live reload.
serve: sitegen
	PATH="$PWD/{{tools}}/dart-sass:$PATH" {{tools}}/hugo server --panicOnWarning

# Everything CI runs, from fresh sources.
ci: setup sources test build
