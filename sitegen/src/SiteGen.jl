"""
    SiteGen

Generate the data files of the OpenSymbolicRules web site from read-only
checkouts of the project repositories.  Every number shown on the site comes
from these files, and every record carries the repository, commit and path it
was read from.  Nothing here is edited by hand: run `just sitegen`.
"""
module SiteGen

using Dates
using JSON
using TOML

export build

const ORG_URL = "https://github.com/OpenSymbolicRules"

"Rule sets distributed in `v1/` and the repository that distributes each."
const DEFAULT_SETS = [
    "integration" => "Integration",
    "calculus" => "Calculus",
    "algebra" => "Algebra",
    "trigonometry" => "Trigonometry",
    "logic" => "Logic",
]

# ---------------------------------------------------------------------------
# OpenMath (JSON encoding) to infix text

const INFIX = Dict(
    "arith1#plus" => (" + ", 1), "arith1#minus" => (" - ", 1),
    "arith1#times" => (" ", 2), "arith1#divide" => ("/", 2),
    "relation1#neq" => (" ≠ ", 0), "relation1#eq" => (" = ", 0),
    "relation1#gt" => (" > ", 0), "relation1#lt" => (" < ", 0),
    "relation1#geq" => (" ≥ ", 0), "relation1#leq" => (" ≤ ", 0),
    "set1#in" => (" ∈ ", 0),
    "logic1#and" => (" ∧ ", 0), "logic1#or" => (" ∨ ", 0),
    "logic1#implies" => (" ⇒ ", 0), "logic1#equivalent" => (" ⇔ ", 0),
    "logic1#xor" => (" ⊕ ", 0), "logic1#nand" => (" ⊼ ", 0),
    "logic1#nor" => (" ⊽ ", 0), "logic1#xnor" => (" ⊙ ", 0),
)

const CONSTANTS = Dict(
    "setname1#Z" => "ℤ", "setname1#R" => "ℝ", "setname1#C" => "ℂ",
    "setname1#N" => "ℕ", "setname1#Q" => "ℚ",
    "logic1#true" => "true", "logic1#false" => "false",
    "nums1#pi" => "π", "nums1#e" => "e", "nums1#i" => "i",
)

const BINDERS = Dict("fns1#lambda" => "λ", "quant1#forall" => "∀", "quant1#exists" => "∃")

symkey(o) = string(o["cd"], "#", o["name"])
kind(o) = get(o, "kind", "")
issym(o, key) = kind(o) == "OMS" && symkey(o) == key

isint_lambda(o) = kind(o) == "OMA" && issym(o["applicant"], "calculus1#int") &&
    length(o["arguments"]) == 1 && kind(o["arguments"][1]) == "OMBIND"

"Precedence of an object: 0 relations/connectives … 5 atoms and calls."
function prec(o)
    k = kind(o)
    k in ("OMV", "OMS") && return 5
    k == "OMI" && return o["integer"] < 0 ? 3 : 5
    k == "OMBIND" && return 0
    k == "OMA" || return 5
    f = o["applicant"]
    kind(f) == "OMS" || return 5
    key = symkey(f)
    haskey(INFIX, key) && return INFIX[key][2]
    key == "arith1#power" && return 4
    key == "arith1#unary_minus" && return 3
    key in ("calculus1#int", "limit1#limit") && return 1
    return 5
end

paren(o, need) = prec(o) < need ? "(" * om_text(o) * ")" : om_text(o)

"""
    om_text(o) -> String

Render an OpenMath object in the JSON encoding of OSR v1 as readable infix
text.  Unknown symbols are shown as `cd#name(…)`.
"""
function om_text(o)::String
    k = kind(o)
    k == "OMV" && return string(o["name"])
    k == "OMI" && return string(o["integer"])
    k == "OMS" && return get(CONSTANTS, symkey(o), symkey(o))
    if k == "OMBIND"
        b = symkey(o["binder"])
        vars = join((v["name"] for v in o["variables"]), ", ")
        return string(get(BINDERS, b, b * " "), vars, ". ", om_text(o["object"]))
    end
    k == "OMA" || return string(o)
    f, args = o["applicant"], o["arguments"]
    # A residual integral int(λx. H)(x) renders as the integral itself.
    isint_lambda(f) && return om_text(f)
    kind(f) == "OMS" || return string(paren(f, 5), "(", join(om_text.(args), ", "), ")")
    key = symkey(f)
    if haskey(INFIX, key) && length(args) >= 2
        op, p = INFIX[key]
        parts = String[]
        for (i, a) in enumerate(args)
            # Left-associative operators: the right operands of `-` and `/`
            # need parentheses at equal precedence.
            need = (i > 1 && key in ("arith1#minus", "arith1#divide")) ? p + 1 : p
            p == 0 && (need = 1)
            push!(parts, paren(a, need))
        end
        return join(parts, op)
    end
    if key == "arith1#power" && length(args) == 2
        base, ex = args
        exs = prec(ex) == 5 ? om_text(ex) : "(" * om_text(ex) * ")"
        return string(paren(base, 5), "^", exs)
    end
    key == "arith1#unary_minus" && return "-" * paren(args[1], 4)
    key == "logic1#not" && return "¬" * paren(args[1], 5)
    if key == "arith1#root" && length(args) == 2
        n = args[2]
        kind(n) == "OMI" && n["integer"] == 2 && return "√(" * om_text(args[1]) * ")"
        return string("root(", om_text(args[1]), ", ", om_text(n), ")")
    end
    if key == "calculus1#int" && length(args) == 1 && kind(args[1]) == "OMBIND"
        lam = args[1]
        v = lam["variables"][1]["name"]
        return string("∫ ", om_text(lam["object"]), " d", v)
    end
    if key == "calculus1#diff" && length(args) == 1 && kind(args[1]) == "OMBIND"
        lam = args[1]
        v = lam["variables"][1]["name"]
        return string("d/d", v, " ", paren(lam["object"], 5))
    end
    if key == "limit1#limit" && length(args) == 3 && kind(args[3]) == "OMBIND"
        lam = args[3]
        v = lam["variables"][1]["name"]
        return string("lim_{", v, "→", om_text(args[1]), "} ", paren(lam["object"], 2))
    end
    name = startswith(key, "transc1#") ? f["name"] : key
    return string(name, "(", join(om_text.(args), ", "), ")")
end

"Number of residual integrals `int(λx. H)(x)` in an object."
function residual_integrals(o)
    o isa AbstractDict || return o isa AbstractVector ? sum(residual_integrals, o; init = 0) : 0
    here = kind(o) == "OMA" && isint_lambda(o["applicant"]) ? 1 : 0
    return here + sum((residual_integrals(v) for v in values(o)); init = 0)
end

# ---------------------------------------------------------------------------
# Classification

statuses(rule) = [string(v["status"]) for v in get(rule, "verification", [])]
has_finding(rule, prefix) = any(f -> startswith(f, prefix), get(rule, "findings", []))
finding(rule, prefix) = (i = findfirst(f -> startswith(f, prefix), get(rule, "findings", []));
    i === nothing ? "" : strip(rule["findings"][i][length(prefix)+1:end]))

"""
    classify(rule, corrected) -> String

`"strengthened"` for a corrected variant (a `strengthened:` finding and a
proof), `"refuted, corrected"` for a refuted rule whose id is in `corrected`,
then `"refuted"`, `"proved"`, `"unsupported"` or `"unproved"`.
"""
function classify(rule, corrected)
    st = statuses(rule)
    has_finding(rule, "strengthened:") && "proved" in st && return "strengthened"
    if "counterexample" in st
        return rule["id"] in corrected ? "refuted, corrected" : "refuted"
    end
    "proved" in st && return "proved"
    !isempty(st) && all(==("unsupported"), st) && return "unsupported"
    return "unproved"
end

"Summary of the verification records of one domain: certified, proved, refuted, …"
function domain_status(rule, domain)
    for v in get(rule, "verification", [])
        v["domain"] == domain || continue
        s = v["status"]
        s == "proved" && return get(v, "certified", false) ? "certified" : "proved"
        s == "counterexample" && return "refuted"
        return string(s)
    end
    return "—"
end

# ---------------------------------------------------------------------------
# Repositories

gitout(dir, args...) = strip(read(`git -C $dir $args`, String))

"Commit, date, number of commits and recent changelog entries of a checkout."
function repo_info(dir; changelog_items = 6)
    info = Dict{String,Any}(
        "commit" => gitout(dir, "rev-parse", "HEAD"),
        "date" => gitout(dir, "log", "-1", "--format=%cs"),
        "commits" => parse(Int, gitout(dir, "rev-list", "--count", "HEAD")),
    )
    info["short"] = info["commit"][1:7]
    cl = joinpath(dir, "CHANGELOG.md")
    info["changelog"] = isfile(cl) ? changelog_head(read(cl, String), changelog_items) : String[]
    return info
end

"The first bullets of the first section of a Keep a Changelog file."
function changelog_head(text, n)
    items = String[]
    insection = false
    for line in split(text, '\n')
        if startswith(line, "## ")
            insection && break
            insection = true
            continue
        end
        insection || continue
        if startswith(line, "- ")
            length(items) >= n && break
            push!(items, strip(line[3:end]))
        elseif startswith(line, "  ") && !isempty(items) && !isempty(strip(line))
            items[end] *= " " * strip(line)
        end
    end
    return items
end

# ---------------------------------------------------------------------------
# Build

blob_url(repo, commit, path) = "$ORG_URL/$repo/blob/$commit/$path"

provenance(repo, info, path, digest) = Dict(
    "repo" => repo, "commit" => info["commit"], "short" => info["short"],
    "date" => info["date"], "path" => path, "url" => blob_url(repo, info["commit"], path),
    "source_digest" => digest)

function rubi_locator(rule)
    for s in get(get(rule, "provenance", Dict()), "sources", [])
        s["name"] == "Rubi" && return string(s["locator"], " (RUBI ", get(s, "revision", "?"), ")")
    end
    return ""
end

function count_by(rows, key)
    c = Dict{String,Int}()
    for r in rows
        c[r[key]] = get(c, r[key], 0) + 1
    end
    return c
end

"""
    build(sources, out; sets = DEFAULT_SETS, example = "integration.linear_power_nondegenerate")

Read the checkouts under `sources` (one directory per repository, named as on
GitHub) and write `registry.json`, `stats.json`, `repos.json` and
`example_rule.json` to `out`.
"""
function build(sources, out; sets = DEFAULT_SETS,
        example = "integration.linear_power_nondegenerate", config = nothing)
    mkpath(out)
    repos = Dict{String,Any}()
    for name in sort(readdir(sources))
        dir = joinpath(sources, name)
        isdir(joinpath(dir, ".git")) || continue
        repos[name] = repo_info(dir)
        repos[name]["url"] = "$ORG_URL/$name"
    end
    describe_repos!(repos, sources, config)

    rows = Dict{String,Any}[]
    stats = Dict{String,Any}("sets" => Dict{String,Any}())
    example_rule = nothing
    for (set, repo) in sets
        path = "v1/$set.osr.json"
        file = joinpath(sources, repo, path)
        isfile(file) || continue
        info = repos[repo]
        doc = JSON.parsefile(file)
        rep_path = joinpath(sources, repo, "v1", "$set.report.json")
        report = isfile(rep_path) ? JSON.parsefile(rep_path) : Dict()
        digest = get(get(doc, "build", Dict()), "source_digest", "")
        rules = doc["rules"]
        # Corrected variants and the refuted rules they correct share a legacy id.
        variants = Dict{String,Any}()
        for r in rules
            has_finding(r, "strengthened:") && (variants[string(get(r, "legacy_id", ""))] = r)
        end
        originals = Dict{String,Any}()
        for r in rules
            lid = string(get(r, "legacy_id", ""))
            haskey(variants, lid) && variants[lid] !== r && (originals[lid] = r)
        end
        corrected = Set(r["id"] for r in values(originals))
        prov = provenance(repo, info, path, digest)
        setrows = Dict{String,Any}[]
        for r in rules
            r["id"] == example && (example_rule = r)
            lid = string(get(r, "legacy_id", ""))
            conds = [om_text(c) for c in get(r, "conditions", [])]
            row = Dict{String,Any}(
                "id" => r["id"], "title" => string(get(r, "description", "")),
                "domain" => repo, "set" => set, "status" => classify(r, corrected),
                "pattern" => om_text(r["pattern"]), "replacement" => om_text(r["replacement"]),
                "conditions" => conds, "residual" => residual_integrals(r["replacement"]),
                "counterexample" => finding(r, "counterexample:"),
                "strengthened" => finding(r, "strengthened:"),
                "findings" => collect(String, get(r, "findings", [])),
                "real" => domain_status(r, "real"), "complex" => domain_status(r, "complex"),
                "boolean" => domain_status(r, "boolean"),
                "theorems" => [string(v["theorem"]) for v in get(r, "verification", []) if haskey(v, "theorem")],
                "legacy_id" => lid, "rubi" => rubi_locator(r),
                "variant" => "", "variant_of" => "", "added_conditions" => String[],
                "provenance" => prov)
            if r["id"] in corrected
                row["variant"] = variants[lid]["id"]
            elseif haskey(variants, lid) && variants[lid] === r && haskey(originals, lid)
                o = originals[lid]
                row["variant_of"] = o["id"]
                row["added_conditions"] = conds[length(get(o, "conditions", []))+1:end]
            end
            push!(setrows, row)
        end
        nm = get(report, "not_migrated", [])
        rep_prov = provenance(repo, info, "v1/$set.report.json", digest)
        for n in nm
            push!(setrows, Dict{String,Any}(
                "id" => string(n["legacy_id"]), "title" => "", "domain" => repo, "set" => set,
                "status" => "not migrated", "pattern" => "", "replacement" => "",
                "conditions" => String[], "residual" => 0, "counterexample" => "", "strengthened" => "",
                "findings" => [string(get(n, "reason", ""))], "note" => string(get(n, "reason", "")),
                "real" => "—", "complex" => "—", "boolean" => "—", "theorems" => String[],
                "legacy_id" => string(n["legacy_id"]), "rubi" => "",
                "variant" => "", "variant_of" => "", "added_conditions" => String[],
                "provenance" => rep_prov))
        end
        migrated = filter(r -> r["status"] != "not migrated", setrows)
        legacy = Set(r["legacy_id"] for r in setrows if !isempty(r["legacy_id"]))
        stats["sets"][set] = Dict{String,Any}(
            "repo" => repo, "rules" => length(rules), "not_migrated" => length(nm),
            "legacy_rules" => length(legacy), "strengthened" => length(variants),
            "status" => count_by(migrated, "status"),
            "residual" => count_by(filter(r -> r["residual"] > 0, migrated), "status"),
            "real" => count_by(migrated, "real"), "complex" => count_by(migrated, "complex"),
            "boolean" => count_by(migrated, "boolean"),
            "metrics" => get(report, "metrics", Dict()),
            "osr_format" => get(doc, "osr_format", ""),
            "profiles" => Dict(string(k) => length(get(v, "rules", [])) for (k, v) in get(doc, "profiles", Dict())),
            "build" => get(doc, "build", Dict()), "provenance" => prov)
        append!(rows, setrows)
    end
    stats["rules_distributed"] = sum((s["rules"] for s in values(stats["sets"])); init = 0)
    stats["theorems"] = sum((length(r["theorems"]) for r in rows); init = 0)
    stats["repositories"] = length(repos)
    stats["generated"] = string(Dates.today())
    extra_stats!(stats, sources, repos)

    write_json(joinpath(out, "registry.json"), rows)
    write_json(joinpath(out, "stats.json"), stats)
    write_json(joinpath(out, "repos.json"), repos)
    write_json(joinpath(out, "example_rule.json"),
        example_rule === nothing ? Dict() :
        Dict("rule" => example_rule, "provenance" => first(r["provenance"] for r in rows if r["id"] == example)))
    return rows
end

write_json(path, x) = open(io -> JSON.json(io, x; pretty = 2), path, "w")

"Descriptions: `Specification/ecosystem.json`, then the site configuration."
function describe_repos!(repos, sources, config)
    eco = joinpath(sources, "Specification", "ecosystem.json")
    if isfile(eco) && haskey(repos, "Specification")
        for e in JSON.parsefile(eco)["repositories"]
            name = string(e["name"])
            haskey(repos, name) || continue
            repos[name]["description"] = string(e["description"])
            repos[name]["kind"] = string(e["kind"])
            repos[name]["description_source"] = Dict(
                "repo" => "Specification", "path" => "ecosystem.json",
                "commit" => repos["Specification"]["commit"],
                "url" => blob_url("Specification", repos["Specification"]["commit"], "ecosystem.json"))
        end
    end
    config === nothing && return repos
    cfg = TOML.parsefile(config)
    for (name, c) in get(cfg, "repositories", Dict())
        haskey(repos, name) || continue
        repos[name]["order"] = get(c, "order", 99)
        haskey(repos[name], "description") && continue
        repos[name]["description"] = c["description"]
        repos[name]["kind"] = get(c, "kind", "")
        repos[name]["description_source"] = Dict("repo" => "opensymbolicrules.github.io",
            "path" => "sitegen/repos.toml", "commit" => "", "url" => "")
    end
    return repos
end

"Counts read from the Specification, Lean, Conformance and Verification checkouts."
function extra_stats!(stats, sources, repos)
    spec = joinpath(sources, "Specification", "docs", "osr-v1.md")
    if isfile(spec)
        ids = Set(m.match for m in eachmatch(r"V1-[A-Z]+-\d+[a-z]?(?=\.\*\*)", read(spec, String)))
        stats["specification"] = Dict("requirements" => length(ids),
            "provenance" => provenance("Specification", repos["Specification"], "docs/osr-v1.md", ""))
    end
    lean = joinpath(sources, "Lean", "OSR")
    if isdir(lean)
        mods = count(f -> endswith(f, ".lean"), readdir(lean))
        stats["lean"] = Dict("modules" => mods,
            "provenance" => provenance("Lean", repos["Lean"], "OSR", ""))
    end
    suites = joinpath(sources, "Conformance", "suites")
    if isdir(suites)
        cases = Dict{String,Int}()
        for s in readdir(suites)
            f = joinpath(suites, s, "$s.cases.json")
            isfile(f) && (cases[s] = length(JSON.parsefile(f)["cases"]))
        end
        stats["conformance"] = Dict("cases" => cases, "total" => sum(values(cases); init = 0),
            "provenance" => provenance("Conformance", repos["Conformance"], "suites", ""))
    end
    reports = joinpath(sources, "Verification", "reports")
    if isdir(reports)
        stats["verification"] = Dict("reports" => count(d -> isdir(joinpath(reports, d)), readdir(reports)),
            "provenance" => provenance("Verification", repos["Verification"], "reports", ""))
    end
    return stats
end

# ---------------------------------------------------------------------------
# Internal link check of the built site

const LINK_RE = r"(?:href|src)=(?:\"([^\"]*)\"|'([^']*)'|([^\s>]+))"

ids_of(html) = Set(something(m[1], m[2], m[3]) for m in
    eachmatch(r"\bid=(?:\"([^\"]*)\"|'([^']*)'|([^\s>]+))", html))

"""
    check_links(site; base) -> Vector{String}

Every internal link of the HTML files under `site`, and every Markdown link
of its `.txt` files (`llms.txt`, `llms-full.txt`), that is relative,
root-relative or absolute under `base` must reach a file, and its fragment an `id` of the
target page.  Returns the broken links as `"page: link"`.
"""
function check_links(site; base = "")
    broken = String[]
    idcache = Dict{String,Set{String}}()
    pages = String[]
    for (root, _, files) in walkdir(site), f in files
        (endswith(f, ".html") || endswith(f, ".txt")) && push!(pages, joinpath(root, f))
    end
    for page in pages
        html = read(page, String)
        # HTML attributes, or Markdown links in the llms*.txt files.
        links = endswith(page, ".txt") ?
            [String(m[1]) for m in eachmatch(r"\]\(([^)\s]+)\)", html)] :
            [String(something(m[1], m[2], m[3])) for m in eachmatch(LINK_RE, html)]
        for link in links
            target = link
            if !isempty(base) && startswith(target, base)
                target = "/" * target[length(base)+1:end]
            end
            occursin(r"^[a-z][a-z0-9+.-]*:"i, target) && continue   # external, mailto:, data:
            startswith(target, "//") && continue
            path, frag = occursin('#', target) ? split(target, '#'; limit = 2) : (target, "")
            path = split(path, '?')[1]
            file = if isempty(path)
                page
            else
                p = startswith(path, "/") ? joinpath(site, lstrip(path, '/')) : joinpath(dirname(page), path)
                p = normpath(p)
                (endswith(path, "/") || isdir(p)) ? joinpath(p, "index.html") : p
            end
            if !isfile(file)
                push!(broken, "$(relpath(page, site)): $link")
            elseif !isempty(frag) && endswith(file, ".html")
                ids = get!(() -> ids_of(read(file, String)), idcache, file)
                frag in ids || push!(broken, "$(relpath(page, site)): $link")
            end
        end
    end
    return broken
end

end # module
