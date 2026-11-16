@testitem "rule status classification" begin
    include("fixtures.jl")
    using SiteGen: classify
    proved = fixture_rule("integration.a")
    refuted = fixture_rule("integration.b"; status = "counterexample",
        findings = ["counterexample: at b = 0 the result is undefined."])
    variant = fixture_rule("integration.b_nondegenerate";
        findings = ["strengthened: the condition b ≠ 0 is appended."])
    open_ = fixture_rule("integration.c"; status = "unproved")
    corrected = Set(["integration.b"])
    @test classify(proved, corrected) == "proved"
    @test classify(refuted, Set{String}()) == "refuted"
    @test classify(refuted, corrected) == "refuted, corrected"
    @test classify(variant, corrected) == "strengthened"
    @test classify(open_, corrected) == "unproved"
end
