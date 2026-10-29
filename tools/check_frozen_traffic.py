"""Check mandatory traffic gates rather than finding an empty perimeter route."""
import json,collections
from pathlib import Path
m=json.loads(Path('game/levels/city_journey_03_frozen_blocks.json').read_text())
open_cells={(x,y) for y,row in enumerate(m['tiles']) for x,t in enumerate(row) if t not in ['water','wall','cheese_wall']}
def reachable(blocked):
 start=tuple(m['spawn']);q=collections.deque([start]);seen={start}
 while q:
  p=q.popleft()
  if p==tuple(m['exit']):return True
  for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
   n=p[0]+dx,p[1]+dy
   if n in open_cells and n not in seen and n not in blocked:seen.add(n);q.append(n)
 return False
assert reachable(set())
assert len([o for o in m['objects'] if o.get('ice_skater')])==32
assert len([o for o in m['objects'] if o['type']=='roach'])==12
for gate in m['difficulty_gates']:
 row=gate['row']; cut={(x,row) for x in range(m['width'])}
 assert not reachable(cut),f'Bypass around gate {row}'
 spans=[o for o in m['objects'] if o.get('ice_skater') and any(n['pos']==[18,row] for n in o['route']) and any(n['pos']==[30,row] for n in o['route'])]
 assert len(spans)==4,f'Missing traffic line {row}'
print('PASS: Four unavoidable full-width traffic gates, 32 square-loop ice skaters, 12 approach/exit roaches; no perimeter bypass')
# Read-only route sampling: a moving frog can cross each individual traffic line.
# This is a local timing-window check, not a full-level controller playthrough.
import math
riders=[o for o in m['objects'] if o.get('ice_skater')]
def at(o,t):
 pts=[n['pos'] for n in o['route']];lens=[math.dist(pts[i],pts[(i+1)%len(pts)])*1.8 for i in range(len(pts))];dist=(o['speed']*t)%sum(lens)
 for i,length in enumerate(lens):
  if dist<=length:
   a,b=pts[i],pts[(i+1)%len(pts)];f=dist/length;return ((a[0]+(b[0]-a[0])*f)*1.8,(a[1]+(b[1]-a[1])*f)*1.8)
  dist-=length
rows=sorted({n['pos'][1] for o in riders for n in o['route']})
for row in rows:
 found=None
 for phase in range(160):
  start=phase*.1;clear=True
  for step in range(43):
   t=step/60;frog=(24*1.8,(row+.8)*1.8-4.2*t)
   if any(math.dist(frog,at(o,start+t))<.87 for o in riders):clear=False;break
  if clear:found=start;break
 assert found is not None, f'No sampled crossing window at {row}'
 print(f'PASS: row {row} has a sampled moving-line crossing window at t={found:.1f}s (roaches/full-route not included)')
