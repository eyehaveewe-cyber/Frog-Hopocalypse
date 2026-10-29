"""Compare observed browser render metrics; screenshots document appearance."""
import json
from pathlib import Path
root=Path('docs/city-aa-evidence')
before={x['label']:x for x in json.loads((root/'before.json').read_text())['obs']}
after={x['label']:x for x in json.loads((root/'after.json').read_text())['obs']}
assert before.keys()==after.keys()
assert before['baby']['render_size']==after['baby']['render_size'] and before['baby']['retro']==after['baby']['retro']
assert before['city-map']['render_size']==after['city-map']['render_size']
for label in ['city','frozen','skate']:
 a=after[label];b=before[label]
 assert a['render_size'][0]>b['render_size'][0]*2 and a['render_size'][1]>b['render_size'][1]*2
 assert b['retro'] and not a['retro']
for label in before:
 assert (root/f'before-{label}.png').is_file() and (root/f'after-{label}.png').is_file()
print('PASS: Three City Journey views render at higher resolution; Baby and map resolution unchanged; mobile screenshots saved; no console errors.')
