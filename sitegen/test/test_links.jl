@testitem "internal link check" begin
    using SiteGen: check_links
    mktempdir() do site
        mkpath(joinpath(site, "a"))
        write(joinpath(site, "index.html"),
            """<a href=/a/>a</a> <a href="a/#top">top</a> <a href=https://opensymbolicrules.github.io/a/>abs</a>
               <a href="https://example.org/x">ext</a> <a href="#here">self</a> <p id=here></p>
               <script src="/app.js"></script> <a href="mailto:x@example.org">m</a>""")
        write(joinpath(site, "app.js"), "")
        write(joinpath(site, "a", "index.html"), """<h1 id="top">A</h1><a href="../index.html">up</a>""")
        @test isempty(check_links(site; base = "https://opensymbolicrules.github.io/"))
        write(joinpath(site, "a", "index.html"),
            """<h1 id="top">A</h1><a href="/missing/">x</a><a href="/#nowhere">y</a>""")
        broken = check_links(site; base = "https://opensymbolicrules.github.io/")
        @test length(broken) == 2
        @test any(b -> occursin("/missing/", b), broken)
        @test any(b -> occursin("#nowhere", b), broken)
    end
end

@testitem "links in llms.txt are checked" begin
    using SiteGen: check_links
    mktempdir() do site
        mkpath(joinpath(site, "a"))
        write(joinpath(site, "a", "index.html"), "<p id=x></p>")
        write(joinpath(site, "llms.txt"), "- [A](https://opensymbolicrules.github.io/a/): page\n- [GitHub](https://github.com/x)\n")
        @test isempty(check_links(site; base = "https://opensymbolicrules.github.io/"))
        write(joinpath(site, "llms-full.txt"), "see [B](https://opensymbolicrules.github.io/b/)\n")
        broken = check_links(site; base = "https://opensymbolicrules.github.io/")
        @test broken == ["llms-full.txt: https://opensymbolicrules.github.io/b/"]
    end
end
