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
