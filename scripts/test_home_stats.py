#!/usr/bin/env python3
"""Check that rendered homepage statistics use their generated data."""
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


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: test_home_stats.py BUILT_INDEX GENERATED_STATS")
    main(*sys.argv[1:])
