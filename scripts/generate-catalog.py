#!/usr/bin/env python3
"""Generate startup catalog, Linux manifests and compatibility matrix. --check is read-only."""
import argparse
import json
from pathlib import Path
import shlex
import re

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
entries = []
for name in ('tools', 'apps', 'fonts'):
    entries.extend(json.loads((root / 'catalog' / f'{name}.json').read_text(encoding='utf-8')))
rows = []
ids = set()
for entry in entries:
    if entry['id'] in ids:
        raise ValueError(f"Duplicate catalog id: {entry['id']}")
    ids.add(entry['id'])
    windows = entry.get('windows')
    if windows:
        if windows['method'] not in ('choco', 'winget', 'zip', 'module', 'native', 'native-exe', 'manual'):
            raise ValueError(f"Invalid Windows method: {entry['id']}")
        if windows['location'] not in ('custom', 'system') or not 0 <= windows['group'] <= 6:
            raise ValueError(f"Invalid Windows location/group: {entry['id']}")
        if windows['location'] == 'custom':
            folder = windows['folder']
            if not folder or folder in ('.', '..') or re.search(r'[\\/:"<>|*?]', folder):
                raise ValueError(f"Unsafe Windows destination folder: {entry['id']}")
            if windows['method'] == 'choco' and not (windows.get('params') or windows.get('installArgs')):
                raise ValueError(f"Custom Chocolatey route needs installer arguments: {entry['id']}")
        if windows['method'] in ('native', 'native-exe') and not windows.get('url', '').startswith('https://'):
            raise ValueError(f"Windows native route needs HTTPS: {entry['id']}")
        if windows['method'] == 'zip':
            re.compile(windows['asset'])
            if not re.fullmatch(r'[\w.-]+/[\w.-]+', windows['package']):
                raise ValueError(f"Invalid release repository: {entry['id']}")
        if windows['method'] == 'choco' and not re.fullmatch(r'[\w.-]+', windows['package']):
            raise ValueError(f"Invalid Chocolatey ID: {entry['id']}")
        re.compile(windows.get('detect', ''))
        re.compile(windows.get('font', ''))
        if not isinstance(windows['default'], bool) or not windows.get('source', '').startswith('https://'):
            raise ValueError(f"Windows entry needs default and source: {entry['id']}")
    fields = [entry[k] for k in ('id', 'label', 'description_es', 'description_en')]
    fields += ['1' if entry['default'] else '0']
    fields += [entry[k] for k in ('kind', 'command', 'mac', 'linux', 'app', 'font_family', 'ubuntu', 'flatpak_id', 'url')]
    if any('|' in field or '\n' in field for field in fields):
        raise ValueError('Catalog fields cannot contain pipes or newlines')
    rows.append('|'.join(fields))
outputs = {'catalog/options.sh': '# Generated from catalog/*.json. Regenerate with scripts/generate-catalog.py.\nCATALOG=' + shlex.quote('\n'.join(rows)) + '\n'}
for filename, platform, method in [('pacman.txt', 'linux', 'pacman'), ('aur.txt', 'linux', 'aur'), ('apt.txt', 'ubuntu', 'apt')]:
    lines = ['# Generated reference only; the wizard installs selected items individually.']
    for entry in entries:
        route = entry[platform]
        if route.startswith(method + ':'):
            lines.append(f"{route.split(':', 1)[1]} # {entry['description_en']}")
    outputs[f'packages/{filename}'] = '\n'.join(lines) + '\n'
lines = ['# Linux compatibility / Compatibilidad Linux', '',
         'Generated from the catalog. Automatic installs target x86_64. Zorin 18 uses the Ubuntu 24.04 (noble) base.', '',
         '`manual:` prints upstream instructions and remains pending; it does not install or mark the app as installed.',
         '`repo:` adds a signed vendor APT repository; `.deb` maintainers may also register update repositories.',
         '`flatpak:` uses a user Flathub installation. Package names alone do not prove GUI or daemon operation.', '',
         '| App / Tool | Arch / EndeavourOS | Zorin 18 |', '|---|---|---|']
for entry in entries:
    if not entry['linux'] and not entry['ubuntu']:
        continue
    def cell(route):
        if not route:
            return '—'
        if route.startswith('manual:'):
            return f"[Manual]({route.split(':', 1)[1]})"
        return f'`{route}`'
    lines.append(f"| {entry['label']} | {cell(entry['linux'])} | {cell(entry['ubuntu'])} |")
outputs['docs/linux-compatibility.md'] = '\n'.join(lines) + '\n'
lines = ['# Windows compatibility / Compatibilidad Windows', '',
         'Generated from catalog/*.json. Windows 10/11 x64; PowerShell 5.1 or 7.', '',
         'Choose a drive and edit Software, Development and Data roots in the wizard.',
         'Custom destinations use verified installer switches or official portable releases; settings/shared components may remain on C:.',
         'System routes have no verified custom switch. Manual entries remain pending. Existing applications/data are never migrated.',
         'Package availability and live installer behavior are separate checks; see windows.md and validation.md.', '',
         '| Option | Method | Destination | Source |', '|---|---|---|---|']
for entry in entries:
    windows = entry.get('windows')
    if not windows:
        continue
    destination = ('SoftwareRoot/' + windows['folder']) if windows['location'] == 'custom' else 'System/user default'
    if windows['method'] == 'manual':
        destination = 'Manual'
    if windows.get('dataVariable'):
        destination += '; new data: DataRoot/' + windows['dataFolder']
    method = windows['method'] + ':' + windows['package']
    lines.append(f"| {entry['label']} | `{method}` | {destination} | [Source]({windows['source']}) |")
outputs['docs/windows-compatibility.md'] = '\n'.join(lines) + '\n'
for method in ('choco', 'winget'):
    lines = ['# Generated reference only; bootstrap.ps1 installs selected items individually.']
    lines += [f"{entry['windows']['package']} # {entry['label']}" for entry in entries
              if entry.get('windows') and entry['windows']['method'] == method]
    outputs[f'packages/{method}.windows.txt'] = '\n'.join(lines) + '\n'
for filename, content in outputs.items():
    path = root / filename
    if args.check:
        if not path.exists() or path.read_text(encoding='utf-8') != content:
            raise SystemExit(f'Outdated generated file: {filename}')
    else:
        with path.open('w', encoding='utf-8', newline='\n') as output_file:
            output_file.write(content)
