"""Cross-platform checks for shared catalog compatibility; no package installation."""
import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CatalogTests(unittest.TestCase):
    def test_existing_unix_routes_are_preserved(self):
        for name in ('tools', 'apps', 'fonts'):
            previous = json.loads(subprocess.check_output(
                ['git', '-c', f'safe.directory={ROOT.as_posix()}', 'show', f'HEAD:catalog/{name}.json'], cwd=ROOT))
            current = {entry['id']: entry for entry in json.loads(
                (ROOT / 'catalog' / f'{name}.json').read_text(encoding='utf-8'))}
            for entry in previous:
                for platform in ('mac', 'linux', 'ubuntu'):
                    self.assertEqual(entry[platform], current[entry['id']][platform], (entry['id'], platform))

    def test_windows_destinations_have_explicit_supported_routes(self):
        count = 0
        for name in ('tools', 'apps', 'fonts'):
            for entry in json.loads((ROOT / 'catalog' / f'{name}.json').read_text(encoding='utf-8')):
                windows = entry.get('windows')
                if not windows:
                    continue
                count += 1
                self.assertTrue(windows['source'].startswith('https://'))
                if windows['location'] == 'custom':
                    self.assertTrue(windows['folder'])
                    if windows['method'] == 'choco':
                        self.assertTrue(windows.get('params') or windows.get('installArgs'))
                    if windows['method'] == 'winget':
                        self.assertNotEqual(windows.get('sourceName'), 'msstore')
        self.assertGreater(count, 0)


if __name__ == '__main__':
    unittest.main()
