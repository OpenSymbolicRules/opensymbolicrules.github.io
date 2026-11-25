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

@testitem "generalization does not replace the refuted original" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        src = joinpath(root, "sources")
        mkpath(src)
        fixture_repo(src, "Integration", "integration", [
            fixture_rule("integration.b"; status = "counterexample"),
            fixture_rule("integration.b_nondegenerate";
                findings = ["strengthened: a denominator condition is added."]),
            fixture_rule("integration.b_order_free";
                findings = ["generalized: order assumptions are removed."])] )
        out = joinpath(root, "data")
        SiteGen.build(src, out; sets = ["integration" => "Integration"])
        byid = Dict(r["id"] => r for r in JSON.parsefile(joinpath(out, "registry.json")))
        @test byid["integration.b"]["status"] == "refuted, corrected"
        @test byid["integration.b"]["variant"] == "integration.b_nondegenerate"
        @test byid["integration.b_nondegenerate"]["variant_of"] == "integration.b"
        @test byid["integration.b_order_free"]["status"] == "generalized"
        @test byid["integration.b_order_free"]["variant"] == ""
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

@testitem "Default inventory counts only files selected by the manifest" begin
    using JSON, SiteGen
    mktempdir() do dir
        for (name, n) in [("loaded", 2), ("excluded", 3), ("empty", 0)]
            write(joinpath(dir, name * ".json"), JSON.json(Dict("rules" => fill(Dict(), n))))
        end
        manifest(files) = write(joinpath(dir, "meta.json"), JSON.json(Dict("load_order"=>files,"rule_count"=>99)))
        manifest(["empty.json","loaded.json"])
        @test SiteGen.source_counts(dir) == (all=5, loaded=2)
        manifest(["excluded.json"])
        @test SiteGen.source_counts(dir) == (all=5, loaded=3)
        manifest(["missing.json"])
        @test_throws ArgumentError SiteGen.source_counts(dir)
        manifest(["loaded.json","loaded.json"])
        @test_throws ArgumentError SiteGen.source_counts(dir)
    end
end

@testitem "LinearAlgebra pilot examples have searchable rows and separate counts" begin
    include("fixtures.jl")
    using SiteGen, JSON
    mktempdir() do root
        src, out = joinpath(root, "sources"), joinpath(root, "out")
        repo = fixture_repo(src, "LinearAlgebra", "unused", [])
        mkdir(joinpath(repo, "examples"))
        rule = Dict("id" => "linear_algebra.swap", "orientation" => "forward",
            "pattern" => omv("u"), "replacement" => omv("v"),
            "conditions" => [oma(oms("relation1", "neq"), omv("u"), omv("v"))],
            "context" => Dict("scalar_domains" => ["setname1#R"],
                "variables" => Dict("u" => Dict("kind" => "vector", "dimension" => 3)),
                "space" => Dict("orientation" => "right_handed")),
            "application_guard" => Dict("kind" => "strict_variable_name_order", "less" => "v", "greater" => "u"))
        path = "examples/vector-identities.json"
        write(joinpath(repo, path), JSON.json(Dict("profile" => "example/0.1", "rules" => [rule])))
        git!(repo, "add", "examples")
        git!(repo, "commit", "-qm", "pilot")
        rows = SiteGen.build(src, out)
        @test length(rows) == 1
        row = only(rows)
        @test (row["id"], row["domain"], row["status"]) == ("linear_algebra.swap", "LinearAlgebra", "pilot example")
        @test row["provenance"]["path"] == path
        @test row["provenance"]["commit"] == readchomp(`git -C $repo rev-parse HEAD`)
        @test row["real"] == row["complex"] == "—"
        @test row["pattern"] == "u" && row["replacement"] == "v"
        for token in ("ℝ", "vector", "3", "right_handed", "u ≠ v", "strict_variable_name_order")
            @test occursin(token, join(row["conditions"], " "))
        end
        stats = JSON.parsefile(joinpath(out, "stats.json"))
        @test stats["rules_distributed"] == stats["theorems"] == 0
        @test stats["pilot_examples"] == 1
    end
end
