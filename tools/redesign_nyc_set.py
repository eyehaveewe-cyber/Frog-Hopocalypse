#!/usr/bin/env python3
"""Apply the authored NYC difficulty revision. Repeating this command is safe.

Only the six NYC JSON files are touched. Existing IDs and district art remain.
"""
import json, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def lane(row,direction,speed,spacing,offset,kinds):
    return dict(row=row,direction=direction,speed=speed,spacing=spacing,offset=offset,vehicles=kinds.split())
def row(d,y,kind,openings=()):
    for x in range(1,d['width']-1): d['tiles'][y][x]='path' if x in openings else kind

def roach(d,name,points,speed):
    d['objects'].append(dict(id='difficulty-'+name,type='roach',pos=points[0],rotation=0,solid=False,behavior='patrol',speed=speed,waypoints=points))

def finish(d,path):
    roads={l['row'] for l in d.get('traffic',[])}
    for y in roads: row(d,y,'road')
    # Terrain changes move the course through former scenery positions.
    # Remove just decorations whose previous ground is no longer usable.
    d['objects']=[o for o in d['objects'] if d['tiles'][int(o['pos'][1])][int(o['pos'][0])] not in ['wall','water'] and all(abs(o['pos'][1]-y)>=.85 for y in roads)]
    path.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')

for path in sorted((ROOT/'game/levels').glob('nyc_*.json')):
    d=json.loads(path.read_text()); d['objects']=[o for o in d['objects'] if not o['id'].startswith('difficulty-')]
    n=int(path.name[4:6])
    if n==1:
        d['traffic']=[lane(8,1,3.6,9.0,1,'taxi sedan'),lane(7,-1,3.4,10.2,5,'truck taxi'),lane(4,1,4.1,8.6,2,'taxi sedan'),lane(3,-1,3.6,10.6,6,'bus taxi')]
        row(d,6,'wall',range(9,12));row(d,5,'path');row(d,2,'path')
        d['crossings']=[4,10,16]
        d['description']='Two avenue pairs split the park. Go around the pond, read both traffic directions, then change crossing line through the middle garden gate. Cars do not stop at crosswalks.'
        roach(d,'park-garden',[[14,5],[18,5]],1.7)
    elif n==2:
        d['traffic']=[lane(12,1,3.8,8.8,0,'taxi sedan'),lane(11,-1,3.4,10.0,4,'truck taxi'),lane(5,1,4.2,8.6,1,'sedan taxi'),lane(4,-1,3.7,10.4,5,'bus taxi')]
        row(d,8,'wall',[3,4]);row(d,6,'path');row(d,3,'path')
        row(d,2,'wall',[16,17]); row(d,7,'floor')
        # The north garden approach is an exposed transverse patrol, with
        # two-cell shoulders for watching the loop before committing.
        d['objects']=[o for o in d['objects'] if o['type']!='roach']
        roach(d,'brownstone-crosswalk',[[6,7],[14,7]],2.0)
        d['description']='Cross the delivery avenue, take the west stoop opening, and read the roach patrol before crossing the northern traffic pair. The final gate lies on the opposite side of the block.'
    elif n==3:
        d['traffic']=[lane(16,1,4.0,8.8,1.5,'truck taxi'),lane(15,-1,3.8,9.2,5,'sedan taxi'),lane(8,1,3.6,10.4,0,'bus taxi'),lane(7,-1,4.4,8.6,5,'taxi truck'),lane(3,1,4.3,9.0,1,'sedan taxi'),lane(2,-1,3.7,10.3,6,'truck taxi')]
        row(d,5,'wall',[4,5]);row(d,4,'path')
        # Two narrower boardwalks around the basin. The north arcade forces
        # departure from the bank that looked aligned with the exit.
        for y in range(10,14):
            for x in range(1,22):
                if x not in [4,5,6,16,17,18]: d['tiles'][y][x]='water'
        d['objects']=[o for o in d['objects'] if o['type']!='roach']
        roach(d,'pier-west',[[5,10],[5,13]],1.8)
        roach(d,'pier-east',[[17,13],[17,10]],2.0)
        d['description']='Choose one of two patrolled boardwalks between the service roads. The western arcade leads to a third avenue pair; arrive on the final sidewalk before turning toward the gate.'
    elif n==4:
        d['traffic']=[lane(18,1,4.3,8.5,.5,'taxi sedan truck'),lane(17,-1,3.7,10.2,6,'bus taxi'),lane(12,1,4.7,8.3,4,'taxi sedan'),lane(11,-1,4.0,10.0,.5,'truck bus sedan'),lane(6,1,5.0,8.7,2,'sedan taxi'),lane(5,-1,4.0,10.2,7,'bus taxi truck')]
        row(d,15,'wall',[4,5,6]);row(d,9,'wall',[18,19,20]);row(d,2,'wall',[10,11,12])
        roach(d,'broadway-low',[[8,14],[18,14]],2.1)
        roach(d,'broadway-high',[[7,8],[16,8]],2.3)
        d['description']='The theater arcades alternate west, east and center openings. Choose a useful exit from each avenue pair, then watch the patrol crossing the next sidewalk.'
    elif n==5:
        d['traffic']=[lane(20,1,4.5,8.1,1,'taxi sedan truck'),lane(19,-1,3.8,9.6,5,'bus taxi bus truck'),lane(16,1,5.0,8.4,3.5,'sedan taxi truck'),lane(15,-1,4.1,9.7,0,'bus truck taxi'),lane(12,1,5.3,8.2,6,'taxi sedan taxi'),lane(11,-1,4.5,9.6,2,'truck taxi bus'),lane(8,1,5.6,8.6,.5,'taxi sedan truck taxi'),lane(7,-1,4.2,10.0,7,'bus taxi truck sedan')]
        row(d,17,'wall',[3,4,5]);row(d,13,'wall',[18,19,20]);row(d,9,'wall',[6,7,8]);row(d,5,'wall',[11,12,13])
        d['crossings']=[4,7,12,17,19]
        d['description']='Four mixed-traffic avenues with west, east, west and center arcade openings. Plan the next crossing line from the safe median; the north fountains finish the return toward the center.'
    else:
        # Close the outer promenade at the central waist. These barriers lie
        # outside all authored rider segments, leaving supported tricks intact.
        for x in [3,4,19,20,21]: d['tiles'][12][x]='wall'
        for x in [4,20]: d['tiles'][11][x]='wall';d['tiles'][13][x]='wall'
        for o in d['objects']:
            if o['type']=='skater': o['speed']=[4.2,3.9,4.5][int(o['variant'])]
        roach(d,'skate-north-approach',[[8,4],[16,4]],1.8)
        d['description']='The central waist closes the outer promenade. Enter the rider circuits, choose the west pocket or east rail crossing, then read the northern return loop before the gate.'
    finish(d,path)
    print('Revised',path.name)
