#!/usr/bin/env python3
"""Rebuild the dependency-free Bash catalog from the descriptive JSON catalogs."""
import json,shlex
from pathlib import Path
root=Path(__file__).resolve().parent.parent
rows=[]
for name in ['tools','apps','fonts']:
 for x in json.loads((root/'catalog'/f'{name}.json').read_text()):
  fields=[x[k] for k in ['id','label','description_es','description_en']]+['1' if x['default'] else '0']+[x[k] for k in ['kind','command','mac','linux','app','font_family']]
  if any('|' in f or '\n' in f for f in fields): raise ValueError('Catalog fields cannot contain pipes or newlines')
  rows.append('|'.join(fields))
(root/'catalog/options.sh').write_text('# Generated from catalog/*.json. Regenerate with scripts/generate-catalog.py.\nCATALOG='+shlex.quote('\n'.join(rows))+'\n')
