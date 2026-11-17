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
    end
end
