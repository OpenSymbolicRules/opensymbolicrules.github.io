"""Check the published status diagram and the links to its explanation."""
from html.parser import HTMLParser
from pathlib import Path
import sys


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.diagrams = []
        self.ids = set()
        self.links = set()
        self.in_diagram = False
        self.feed(path.read_text())

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'a':
            self.links.add(attrs.get('href', ''))
        if tag == 'pre' and 'mermaid' in attrs.get('class', '').split():
            self.diagrams.append('')
            self.in_diagram = True

    def handle_data(self, text):
        if self.in_diagram:
            self.diagrams[-1] += text

    def handle_endtag(self, tag):
        if tag == 'pre':
            self.in_diagram = False


if __name__ == '__main__':
    public = Path(sys.argv[1])
    pipeline = Page(public / 'pipeline/index.html')
    assert 'rule-status' in pipeline.ids
    diagram, = (text for text in pipeline.diagrams if 'stateDiagram-v2' in text)
    for state in ('proved', 'unproved', 'counterexample', 'unsupported'):
        assert f'"{state}"' in diagram, state
    for page in ('index.html', 'findings/index.html'):
        assert '/pipeline/#rule-status' in Page(public / page).links, page
