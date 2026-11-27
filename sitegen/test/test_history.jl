@testitem "history read from the Verification reports" begin
    include("fixtures.jl")
    using SiteGen, JSON
    metrics(n, rp, rc, ru, cp, cc, cu, ccert) = Dict("metrics" => Dict(
        "rules_exported" => n,
        "real" => Dict("proved" => rp, "counterexample" => rc, "unproved" => ru, "certified" => rp),
        "complex" => Dict("proved" => cp, "counterexample" => cc, "unproved" => cu, "certified" => ccert)))
    mktempdir() do root
        dir = joinpath(root, "Verification")
        mkpath(dir)
        git!(dir, "init", "-q", "-b", "main")
        function add_report(digest, date, sets)
            d = joinpath(dir, "reports", digest)
            mkpath(d)
            for (set, m) in sets
                write(joinpath(d, "$set.report.json"), JSON.json(m))
            end
            write(joinpath(d, "notes.md"), "not a report")
            git!(dir, "add", ".")
            withenv("GIT_AUTHOR_DATE" => date, "GIT_COMMITTER_DATE" => date) do
                git!(dir, "commit", "-q", "-m", "report $digest")
            end
        end
        add_report("bb"^32, "2026-03-02T10:00:00+00:00",
            ["integration" => metrics(10, 4, 5, 1, 3, 6, 1, 2),
             "logic" => Dict("ruleset" => "logic")])
        add_report("aa"^32, "2026-01-05T09:00:00+00:00",
            ["integration" => metrics(8, 2, 6, 0, 2, 6, 0, 1),
             "trigonometry" => metrics(4, 4, 0, 0, 4, 0, 0, 4)])
        hist = SiteGen.verification_history(dir)
        @test length(hist) == 2
        # Ordered by the date of the commit that added each report.
        @test [h["date"] for h in hist] == ["2026-01-05", "2026-03-02"]
        first_, second = hist
        @test first_["report"] == "aa"^32
        @test first_["rules"] == 12
        @test first_["real"] == Dict("proved" => 6, "counterexample" => 6, "unproved" => 0, "certified" => 6)
        @test first_["complex"]["certified"] == 5
        @test first_["sets"] == Dict("integration" => 8, "trigonometry" => 4)
        # A report file without metrics contributes nothing.
        @test second["rules"] == 10
        @test second["sets"] == Dict("integration" => 10)
        @test second["real"]["unproved"] == 1
        @test length(second["commit"]) == 40
        @test occursin("/Verification/tree/$(second["commit"])/reports/$("bb"^32)", second["url"])
    end
end

@testitem "history written by build" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        src = joinpath(root, "sources")
        mkpath(src)
        fixture_repo(src, "Integration", "integration", [fixture_rule("integration.a")])
        out = joinpath(root, "data")
        SiteGen.build(src, out; sets = ["integration" => "Integration"])
        # Without a Verification checkout the history is empty, not missing.
        @test JSON.parsefile(joinpath(out, "history.json")) == []
        # Without a rules/ directory the v0.1 history is empty as well.
        @test JSON.parsefile(joinpath(out, "source_history.json")) == []
    end
end

@testitem "corrections counted per report" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        dir = joinpath(root, "Verification")
        d = joinpath(dir, "reports", "cc"^32)
        mkpath(d)
        m = Dict("metrics" => Dict("rules_exported" => 4,
            "real" => Dict("proved" => 2, "counterexample" => 1, "unproved" => 1, "certified" => 2),
            "complex" => Dict("proved" => 1, "counterexample" => 1, "unproved" => 2, "certified" => 1)))
        write(joinpath(d, "integration.report.json"), JSON.json(m))
        rules = [fixture_rule("integration.a"),
            fixture_rule("integration.a_nondegenerate"; findings = ["strengthened: adds b ≠ 0"]),
            fixture_rule("integration.b_nondegenerate"; status = "unproved",
                findings = ["strengthened: adds c ≠ 0", "numerical: sampled"]),
            fixture_rule("integration.b"; status = "counterexample")]
        write(joinpath(d, "integration.osr.json"), JSON.json(Dict("ruleset" => "integration", "rules" => rules)))
        git!(dir, "init", "-q", "-b", "main")
        git!(dir, "add", ".")
        git!(dir, "commit", "-q", "-m", "report")
        (p,) = SiteGen.verification_history(dir)
        # Strengthened variants: all of them, and those proved in some domain.
        @test p["corrections"] == Dict("total" => 2, "proved" => 1)
    end
end

@testitem "v0.1 source rules over time" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        function commit!(dir, date, files)
            for (path, n) in files
                mkpath(dirname(joinpath(dir, path)))
                body = path == "rules/meta.json" ? Dict("load_order" => n) :
                    Dict("rules" => [Dict("id" => "r$i") for i in 1:n])
                write(joinpath(dir, path), JSON.json(body))
            end
            git!(dir, "add", ".")
            withenv("GIT_AUTHOR_DATE" => date, "GIT_COMMITTER_DATE" => date) do
                git!(dir, "commit", "-q", "-m", "rules")
            end
        end
        a = joinpath(root, "Alpha"); mkpath(a); git!(a, "init", "-q", "-b", "main")
        b = joinpath(root, "Beta"); mkpath(b); git!(b, "init", "-q", "-b", "main")
        commit!(a, "2026-01-01T10:00:00+00:00", ["rules/x.json" => 2])
        commit!(b, "2026-01-02T10:00:00+00:00", ["rules/y.json" => 5, "rules/z.json" => 1,
            "rules/meta.json" => ["y.json"]])
        commit!(a, "2026-01-03T10:00:00+00:00", ["rules/x.json" => 3])
        # A commit that leaves the counts unchanged is not a point either.
        write(joinpath(b, "rules", "y.json"), JSON.json(Dict("rules" => [Dict("id" => "s$i") for i in 1:5])))
        git!(b, "add", "."); git!(b, "commit", "-q", "-m", "rename ids")
        # A commit outside rules/ is not a point.
        write(joinpath(a, "README.md"), "x"); git!(a, "add", "."); git!(a, "commit", "-q", "-m", "doc")
        h = SiteGen.source_history(root, ["alpha" => "Alpha", "beta" => "Beta", "gamma" => "Gamma"])
        @test [p["date"] for p in h] == ["2026-01-01", "2026-01-02", "2026-01-03"]
        @test [p["total"] for p in h] == [2, 8, 9]
        # Without a load manifest every entry is loaded.
        @test [p["loaded"] for p in h] == [2, 7, 8]
        @test h[2]["sets"] == Dict("Alpha" => 2, "Beta" => 6)
        @test h[3]["repo"] == "Alpha"
        @test length(h[3]["commit"]) == 40
        @test occursin("/Alpha/tree/$(h[3]["commit"])/rules", h[3]["url"])
    end
end
