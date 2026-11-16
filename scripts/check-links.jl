# Check the internal links of a built site.  Usage:
#   julia --project=sitegen scripts/check-links.jl PUBLIC [BASEURL]
using SiteGen

site = get(ARGS, 1, "public")
base = get(ARGS, 2, "https://opensymbolicrules.github.io/")
broken = SiteGen.check_links(site; base)
foreach(println, broken)
println("check-links: $(length(broken)) broken internal links in $site")
exit(isempty(broken) ? 0 : 1)
