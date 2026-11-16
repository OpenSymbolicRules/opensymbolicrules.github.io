@testitem "OpenMath objects render as infix text" begin
    include("fixtures.jl")
    using SiteGen: om_text
    @test om_text(omv("x")) == "x"
    @test om_text(omi(-1)) == "-1"
    @test om_text(oma(oms("arith1", "plus"), omv("a"), oma(oms("arith1", "times"), omv("b"), omv("x")))) == "a + b x"
    @test om_text(oma(oms("arith1", "power"), oma(oms("arith1", "plus"), omv("a"), omv("x")), omv("m"))) == "(a + x)^m"
    @test om_text(oma(oms("arith1", "power"), omv("x"), omi(-1))) == "x^(-1)"
    @test om_text(oma(oms("relation1", "neq"), omv("m"), omi(-1))) == "m ≠ -1"
    @test om_text(oma(oms("transc1", "sin"), omv("x"))) == "sin(x)"
    @test om_text(oma(oms("calculus1", "int"), lam("x", omv("x")))) == "∫ x dx"
    # A residual integral int(λx. H)(x) is an OMA whose applicant is an OMA.
    resid = oma(oma(oms("calculus1", "int"), lam("x", omv("x"))), omv("x"))
    @test om_text(resid) == "∫ x dx"
    @test om_text(lam("x", omv("x"))) == "λx. x"
    @test om_text(oma(oms("set1", "in"), omv("n"), oms("setname1", "Z"))) == "n ∈ ℤ"
    @test om_text(oma(oms("logic1", "and"), omv("p"), oms("logic1", "true"))) == "p ∧ true"
    @test om_text(oma(oms("arith1", "minus"), omv("a"), oma(oms("arith1", "plus"), omv("b"), omv("c")))) == "a - (b + c)"
end

@testitem "residual integrals are counted" begin
    include("fixtures.jl")
    using SiteGen: residual_integrals
    resid = oma(oma(oms("calculus1", "int"), lam("x", omv("x"))), omv("x"))
    @test residual_integrals(lam("x", oma(oms("arith1", "plus"), resid, resid))) == 2
    @test residual_integrals(lam("x", omv("x"))) == 0
end
