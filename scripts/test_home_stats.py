#!/usr/bin/env python3
"""Check that rendered homepage, Integration and findings statistics use their generated data."""
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import sys


class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def main(html_path, stats_path):
    stats = json.loads(Path(stats_path).read_text())
    parser = Text()
    parser.feed(Path(html_path).read_text())
    page = re.sub(r"\s+", " ", " ".join(parser.parts))
    assert re.search(rf"\b{stats['rules_distributed']}\s+rules distributed in\s+v1/", page)
    corpus = stats["sets"]["integration"]["corpus_rules"]
    assert re.search(rf"\b{corpus}\s+Integration v0\.1 rule entries", page)
    assert "Includes duplicates and files outside the default load order" in page
    root = Path(html_path).parent
    integration = stats["sets"]["integration"]
    def page_text(path):
        page_parser = Text()
        page_parser.feed(path.read_text())
        return re.sub(r"\s+", " ", " ".join(page_parser.parts))
    domain = page_text(root / "domains/integration/index.html")
    findings = page_text(root / "findings/index.html")
    for rendered in (page, domain):
        assert f"{integration['default_rules']} Integration v0.1 entries in the default load order" in rendered
    assert f"{integration['rules']} v1 rule entries in" in domain
    exported = stats["rules_distributed"]
    omissions = sum(s["not_migrated"] for s in stats["sets"].values())
    assert f"{exported} exported v1 entries across all domains and {omissions} audit records" in findings
    assert f"{exported + omissions} of {exported + omissions} registry rows shown" in findings
    assert f"contains {integration['default_rules']} entries" in findings



if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: test_home_stats.py BUILT_INDEX GENERATED_STATS")
    main(*sys.argv[1:])
