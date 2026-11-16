@testitem "registry built from a fixture repository" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        src = joinpath(root, "sources")
        mkpath(src)
        fixture_repo(src, "Integration", "integration", [
            fixture_rule("integration.b"; status = "counterexample",
                findings = ["counterexample: at b = 0 the result is undefined."],
                conditions = [oma(oms("relation1", "neq"), omv("m"), omi(-1))]),
            fixture_rule("integration.b_nondegenerate";
                findings = ["strengthened: the condition b ≠ 0 is appended."],
                conditions = [oma(oms("relation1", "neq"), omv("m"), omi(-1)),
                    oma(oms("relation1", "neq"), omv("b"), omi(0))])];
            not_migrated = [Dict("legacy_id" => "rubi:9 Y:1", "reason" => "uses Sqrt")])
        out = joinpath(root, "data")
        SiteGen.build(src, out; sets = ["integration" => "Integration"])
        reg = JSON.parsefile(joinpath(out, "registry.json"))
        @test length(reg) == 3
        byid = Dict(r["id"] => r for r in reg)
        b = byid["integration.b"]
        @test b["status"] == "refuted, corrected"
        @test b["counterexample"] == "at b = 0 the result is undefined."
        @test b["conditions"] == ["m ≠ -1"]
        @test b["variant"] == "integration.b_nondegenerate"
        @test b["domain"] == "Integration"
        @test b["residual"] == 0
        @test length(b["provenance"]["commit"]) == 40
        @test b["provenance"]["path"] == "v1/integration.osr.json"
        v = byid["integration.b_nondegenerate"]
        @test v["status"] == "strengthened"
        @test v["variant_of"] == "integration.b"
        @test v["added_conditions"] == ["b ≠ 0"]
        @test v["real"] == "certified"
        nm = byid["rubi:9 Y:1"]
        @test nm["status"] == "not migrated"
        @test nm["counterexample"] == ""
        stats = JSON.parsefile(joinpath(out, "stats.json"))
        @test stats["rules_distributed"] == 2
        @test stats["sets"]["integration"]["rules"] == 2
        @test stats["sets"]["integration"]["not_migrated"] == 1
        @test stats["sets"]["integration"]["legacy_rules"] == 2
        @test stats["sets"]["integration"]["strengthened"] == 1
        @test stats["sets"]["integration"]["residual"] == Dict()
        @test stats["sets"]["integration"]["profiles"] == Dict()
        @test stats["sets"]["integration"]["real"]["certified"] == 1
        repos = JSON.parsefile(joinpath(out, "repos.json"))
        @test repos["Integration"]["commits"] == 1
        @test repos["Integration"]["changelog"] == ["First change.", "Second change, continued."]
    end
end

@testitem "verification records without a theorem" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        src = joinpath(root, "sources")
        mkpath(src)
        r = fixture_rule("algebra.a")
        r["verification"] = [verif("real", "proved"),
            Dict("domain" => "complex", "status" => "unsupported", "certified" => false)]
        fixture_repo(src, "Algebra", "algebra", [r])
        out = joinpath(root, "data")
        SiteGen.build(src, out; sets = ["algebra" => "Algebra"])
        row = only(JSON.parsefile(joinpath(out, "registry.json")))
        @test row["theorems"] == ["OSR.T.real_proved"]
        @test row["complex"] == "unsupported"
        @test row["status"] == "proved"
    end
end

@testitem "size of the v0.1 source corpus" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        src = joinpath(root, "sources")
        mkpath(src)
        dir = fixture_repo(src, "Integration", "integration", [fixture_rule("integration.a")])
        mkpath(joinpath(dir, "rules", "1-algebraic"))
        write(joinpath(dir, "rules", "1-algebraic", "a.json"),
            JSON.json(Dict("identity" => "rubi:1", "rules" => [Dict("id" => 1), Dict("id" => 2)])))
        write(joinpath(dir, "rules", "b.json"), JSON.json(Dict("rules" => [Dict("id" => 1)])))
        write(joinpath(dir, "rules", "meta.json"), JSON.json(Dict("rules" => [Dict("id" => 9)])))
        out = joinpath(root, "data")
        SiteGen.build(src, out; sets = ["integration" => "Integration"])
        stats = JSON.parsefile(joinpath(out, "stats.json"))
        @test stats["sets"]["integration"]["corpus_rules"] == 3
        @test stats["sets"]["integration"]["corpus_path"] == "rules"
    end
end

@testitem "brand identity from the organization profile repository" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        src = joinpath(root, "sources")
        mkpath(src)
        fixture_repo(src, "Algebra", "algebra", [fixture_rule("algebra.a")])
        brand = joinpath(src, ".github")
        mkpath(joinpath(brand, "profile", "assets"))
        write(joinpath(brand, "profile", "assets", "banner.png"), "png")
        git!(brand, "init", "-q", "-b", "main")
        git!(brand, "add", ".")
        git!(brand, "commit", "-q", "-m", "brand")
        out = joinpath(root, "data")
        SiteGen.build(src, out; sets = ["algebra" => "Algebra"])
        repos = JSON.parsefile(joinpath(out, "repos.json"))
        @test !haskey(repos, ".github")
        stats = JSON.parsefile(joinpath(out, "stats.json"))
        @test stats["brand"]["path"] == "profile/assets/banner.png"
        @test stats["brand"]["repo"] == ".github"
        @test length(stats["brand"]["commit"]) == 40
        @test stats["repositories"] == 1
    end
end
