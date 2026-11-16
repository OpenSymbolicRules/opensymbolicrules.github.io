# Helpers shared by the test items: a tiny git repository with a v1 rule set.
using JSON

omv(n) = Dict("kind" => "OMV", "name" => n)
omi(i) = Dict("kind" => "OMI", "integer" => i)
oms(cd, n) = Dict("kind" => "OMS", "cd" => cd, "name" => n)
oma(f, args...) = Dict("kind" => "OMA", "applicant" => f, "arguments" => collect(args))
lam(v, body) = Dict("kind" => "OMBIND", "binder" => oms("fns1", "lambda"),
    "variables" => [omv(v)], "object" => body)

verif(domain, status; certified = status == "proved") = Dict(
    "domain" => domain, "status" => status, "certified" => certified,
    "theorem" => "OSR.T.$(domain)_$(status)", "prover" => "lean4")

function fixture_rule(id; status = "proved", findings = String[], conditions = Any[],
        legacy = "rubi:1 X/1.1.1.1 (a+b x)^m:4")
    Dict("id" => id, "legacy_id" => legacy, "description" => "Rule $id",
        "pattern" => oma(oms("calculus1", "int"), lam("x", omv("x"))),
        "replacement" => lam("x", oma(oms("arith1", "power"), omv("x"), omi(2))),
        "conditions" => conditions, "findings" => findings,
        "verification" => [verif("real", status), verif("complex", status)],
        "provenance" => Dict("method" => "derived", "sources" => [
            Dict("name" => "Rubi", "locator" => "1 X.m#4", "revision" => "4.16.1")]))
end

function git!(dir, args...)
    run(pipeline(`git -C $dir -c user.name=t -c user.email=t@example.org $args`;
        stdout = devnull, stderr = devnull))
end

"""Create `root/name` as a git repository holding `v1/<set>.osr.json` and its report."""
function fixture_repo(root, name, set, rules; not_migrated = Any[])
    dir = joinpath(root, name)
    mkpath(joinpath(dir, "v1"))
    doc = Dict("ruleset" => set, "osr_format" => "1.0.0-alpha.1", "rules" => rules,
        "build" => Dict("source_digest" => "sha256:" * "ab"^32,
            "lean_toolchain" => "leanprover/lean4:v4.35.0",
            "mathlib_revision" => "56a005855ea17e0b0958f73ec801ae140b0a1679"))
    write(joinpath(dir, "v1", "$set.osr.json"), JSON.json(doc))
    write(joinpath(dir, "v1", "$set.report.json"),
        JSON.json(Dict("ruleset" => set, "not_migrated" => not_migrated)))
    write(joinpath(dir, "CHANGELOG.md"), """
        # Changelog

        ## [Unreleased]

        ### Added
        - First change.
        - Second change,
          continued.

        ## [0.1.0] - 2026-01-01
        - Old change.
        """)
    git!(dir, "init", "-q", "-b", "main")
    git!(dir, "add", ".")
    git!(dir, "commit", "-q", "-m", "init")
    dir
end
