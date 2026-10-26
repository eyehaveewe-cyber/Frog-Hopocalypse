"""Rebuild authored choice screens over the original set. Run original generator first.
Witness paths are reserved clearance, not a claim about a player's solution quality.
"""
import json
import runpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
runpy.run_path(str(ROOT/'tools/design_your_move_set.py'))
PLANS={
 'one_step_ahead':([18,14,5], 'One Step Ahead: choose the beat', 'Stop to study the traffic. Every accepted hop advances it once. A shorter route can arrive on a different beat.'),
 'needle_clock':([22,15,6], 'Needle Clock: read both lanes', 'Darts and rails advance together. Plan a crossing and a place to recover before taking the first step.'),
 'shard_switchyard':([27,19,14,5], 'Shard Switchyard: route your reserve', 'Collecting a piece changes the whole yard. Compare collection routes before spending your one leap.'),
 'stillwater_circuit':([28,22,17,8,6], 'Stillwater Circuit: carry the plan', 'A log landing and a seed route share the same clock. Look beyond the next safe tile.'),
 'rush_hourglass':([30,28,23,18,13,9,6], 'Rush Hourglass: commit to a crossing', 'Choose a landing and an escape together. A move beside one lane changes every other lane too.')}
report=[]
for key,(rows,title,lesson) in PLANS.items():
 p=ROOT/'game/levels/your_move'/f'{key}.json';d=json.loads(p.read_text())
 reserved={tuple(d['spawn']),tuple(d['exit']),*map(tuple,d['checkpoints'])}
 # Preserve both separately validated checkpoint and fresh-run clearance.
 for prefix,start in [('your_move_',d['spawn']),('your_move_retry_',d['checkpoints'][0])]:
  fixture=json.loads((ROOT/'game/tests/routes'/f'{prefix}{key}.json').read_text());x,y=start;reserved.add((x,y))
  for a in fixture['actions']:
   for _ in range(2 if a['big'] else 1):x+=a['direction'][0];y+=a['direction'][1];reserved.add((x,y))
 for o in d['objects']:
  x,y=o['pos']
  for dy in range(-1,2):
   for dx in range(-1,2):reserved.add((x+dx,y+dy))
 changed=[]
 for index,y in enumerate(rows):
  eligible=[x for x in range(2,d['width']-2) if d['tiles'][y][x]=='floor']
  if len(eligible)<5:continue
  # Two legible mouths at opposite sides. Each has a small approach pocket.
  mouths=[eligible[1],eligible[-2]]
  for x in eligible:
   if any(abs(x-mouth)<=0 for mouth in mouths) or (x,y) in reserved:continue
   # Keep firing lines unobstructed; difficulty must not depend on hidden shots.
   if any(o['type']=='emitter' and (o['pos'][1]==y or o['pos'][0]==x) for o in d['objects']):continue
   d['tiles'][y][x]='wall';changed.append([x,y])
 # Signs explain the system; they no longer identify a turn or pickup route.
 for i,s in enumerate(d['signs']):
  s['text']=(title.upper()+'\n'+lesson) if i==0 else ('CHECKPOINT\nThe route is yours to choose. Recheck moving hazards after a retry.' if s['pos']==d['checkpoints'][0] else 'Stop to inspect. Waiting does not advance this world.\nCompare the landing with the hazards\' next positions.')
 d['design_revision']='choice-screens-20261026'
 p.write_text(json.dumps(d,indent=2)+'\n')
 report.append(dict(level=key,lesson=lesson,screen_rows=rows,changed_cells=changed,limits='Reserved accepted route and checkpoint clearance. Difficulty needs fresh-player observation.'))
(ROOT/'docs/your-move-redesign.json').write_text(json.dumps(report,indent=2)+'\n')
print([(r['level'],len(r['changed_cells'])) for r in report])
