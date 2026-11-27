"""Tests for collection of optional mathematical-domain documentation."""

import os
import importlib.util
import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('collect_domain_docs', Path(__file__).with_name('collect_domain_docs.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
collect = module.collect


def git(repo, *args):
    env = dict(os.environ, GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.org',
               GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.org')
    return subprocess.check_output(['git', '-C', str(repo), *args], env=env, text=True).strip()


class DomainDocsTests(unittest.TestCase):
    def test_each_domain_links_to_its_filtered_rules(self):
        root = Path(__file__).resolve().parent.parent
        for name in module.DOMAINS:
            with self.subTest(domain=name):
                page = (root / 'content' / 'domains' / name.lower() / '_index.md').read_text()
                self.assertIn(f'](/findings/?c2={name})', page)

    def test_empty_repositories_get_honest_placeholder_pages(self):
        with tempfile.TemporaryDirectory() as root:
            source, dest = Path(root) / 'sources', Path(root) / 'out'
            source.mkdir()
            collect(source, dest)
            for name in ('Integration', 'Calculus', 'Algebra', 'Trigonometry',
                         'Logic', 'LinearAlgebra', 'TensorAlgebra', 'DifferentialGeometry'):
                page = (dest / name.lower() / 'documentation' / '_index.md').read_text()
                self.assertIn('not yet available', page)
                self.assertIn(f'github.com/OpenSymbolicRules/{name}', page)

    def test_wrapped_link_label_keeps_its_source_revision(self):
        link = "[status\nreport](../reports/status.md)"
        expected = "[status\nreport](https://github.com/OpenSymbolicRules/LinearAlgebra/blob/abc/reports/status.md)"
        self.assertEqual(module.rewrite_links(link, "LinearAlgebra", "abc", "docs/matrix-examples.md"), expected)

    def test_collects_markdown_at_commit_and_rewrites_relative_links(self):
        with tempfile.TemporaryDirectory() as root:
            source, dest = Path(root) / 'sources', Path(root) / 'out'
            repo = source / 'LinearAlgebra'
            (repo / 'docs').mkdir(parents=True)
            (repo / 'README.md').write_text('# Repository\n', encoding='utf-8')
            (repo / 'docs' / 'sample.md').write_text(
                '# Sample\n[README](../README.md)\n[external](https://example.org/)\n',
                encoding='utf-8')
            git(repo, 'init', '-q')
            git(repo, 'add', '.')
            git(repo, 'commit', '-qm', 'fixture')
            commit = git(repo, 'rev-parse', 'HEAD')
            (repo / 'docs' / 'sample.md').write_text('uncommitted edit', encoding='utf-8')
            collect(source, dest)
            stem = 'doc-' + hashlib.sha256(b'docs/sample.md').hexdigest()
            page = (dest / 'linearalgebra' / 'documentation' / 'pages' / (stem + '.md')).read_text()
            self.assertIn(f'github.com/OpenSymbolicRules/LinearAlgebra/blob/{commit}/README.md', page)
            self.assertIn('https://example.org/', page)
            self.assertNotIn('uncommitted edit', page)
            self.assertIn(commit, page)
            self.assertIn(f'pages/{stem}/', (dest / 'linearalgebra' / 'documentation' / '_index.md').read_text())

    def test_page_titles_come_from_headings_not_file_names(self):
        title = module.page_title
        self.assertEqual(title('README.md', '# Open Symbolic Rules\n'), 'Overview')
        self.assertEqual(title('docs/a.md', '# JSON Schema `Validation`\n'), 'JSON Schema Validation')
        self.assertEqual(title('docs/a.md', 'Intro\n\n## Not this\n# [Linked](x.md) *title* #\n'),
                         'Linked title')
        self.assertEqual(title('docs/a.md', '```\n# not a heading\n```\nSetext title\n=====\n'),
                         'Setext title')
        self.assertEqual(title('docs/schema-validation.md', 'No heading here.\n'), 'Schema validation')
        self.assertEqual(title('docs/osr_v1.md', ''), 'Osr v1')
        # The home page of a documentation site repeats the repository name.
        self.assertEqual(title('docs/index.md', '# OpenSymbolicRules — Calculus\n'), 'Documentation home')

    def test_index_and_menu_show_titles_in_order(self):
        with tempfile.TemporaryDirectory() as root:
            source, dest = Path(root) / 'sources', Path(root) / 'out'
            repo = source / 'Logic'
            (repo / 'docs').mkdir(parents=True)
            (repo / 'README.md').write_text('# OpenSymbolicRules Logic\n', encoding='utf-8')
            (repo / 'docs' / 'zeta.md').write_text('# Alpha rules\n', encoding='utf-8')
            (repo / 'docs' / 'beta.md').write_text('No heading.\n', encoding='utf-8')
            git(repo, 'init', '-q')
            git(repo, 'add', '.')
            git(repo, 'commit', '-qm', 'fixture')
            collect(source, dest)
            folder = dest / 'logic' / 'documentation'
            index = (folder / '_index.md').read_text()
            entries = [line for line in index.splitlines() if line.startswith('- [')]
            self.assertEqual([e[3:e.index(']')] for e in entries], ['Overview', 'Alpha rules', 'Beta'])
            self.assertNotIn('.md]', index)
            for page in (folder / 'pages').glob('*.md'):
                source_line = [l for l in page.read_text().splitlines() if l.startswith('Source: ')][0]
                self.assertNotIn('.md]', source_line)
            pages = sorted((folder / 'pages').glob('*.md'))
            fronts = {p.read_text().split('\n')[1] for p in pages}
            self.assertEqual(fronts, {'title: "Overview"', 'title: "Alpha rules"', 'title: "Beta"'})
            # The menu follows the same order through the page weights.
            weights = {p.read_text().split('\n')[1]: p.read_text().split('\n')[2] for p in pages}
            self.assertEqual(weights['title: "Overview"'], 'weight: 1')
            self.assertEqual(weights['title: "Alpha rules"'], 'weight: 2')
            self.assertEqual(weights['title: "Beta"'], 'weight: 3')

    def test_refuses_to_replace_non_generated_content(self):
        with tempfile.TemporaryDirectory() as root:
            source, dest = Path(root) / 'sources', Path(root) / 'out'
            source.mkdir()
            dest.mkdir()
            (dest / 'linearalgebra').mkdir()
            (dest / 'linearalgebra' / 'documentation').mkdir()
            (dest / 'linearalgebra' / 'documentation' / 'important.txt').write_text('keep', encoding='utf-8')
            with self.assertRaises(ValueError):
                collect(source, dest)
            self.assertEqual((dest / 'linearalgebra' / 'documentation' / 'important.txt').read_text(), 'keep')

    def test_preserves_existing_domain_pages(self):
        with tempfile.TemporaryDirectory() as root:
            source, dest = Path(root) / 'sources', Path(root) / 'out'
            source.mkdir()
            dest.mkdir()
            (dest / '_index.md').write_text('existing domain index', encoding='utf-8')
            (dest / 'algebra.md').write_text('existing domain', encoding='utf-8')
            collect(source, dest)
            self.assertEqual((dest / '_index.md').read_text(), 'existing domain index')
            self.assertEqual((dest / 'algebra.md').read_text(), 'existing domain')


if __name__ == '__main__':
    unittest.main()
