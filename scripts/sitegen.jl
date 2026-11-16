# Generate data/generated/ from the checkouts in SOURCES (default .sources).
# Usage: julia --project=sitegen scripts/sitegen.jl [SOURCES] [OUT]
using SiteGen

sources = get(ARGS, 1, ".sources")
out = get(ARGS, 2, joinpath("data", "generated"))
rows = SiteGen.build(sources, out; config = joinpath(@__DIR__, "..", "sitegen", "repos.toml"))
println("sitegen: $(length(rows)) registry rows written to $out")
