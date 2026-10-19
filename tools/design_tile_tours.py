"""Five-stage Tile Hop tour. AI-authored layouts implementing the user's brief.
Keeps stage IDs and rules; applies the later authored pressure pass deterministically.
"""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]/'game/levels/tile_hop'
def base(name,w,h,rule='free',linked=False):
 return dict(version=1,name=name,theme='egypt',width=w,height=h,game_mode='tile',move_with_me=linked,draw_distance=18,rules={'long_hop':rule,'charge_hops':25 if rule=='charged' else 10},tiles=[['wall' if x in (0,w-1) or y in (0,h-1) else 'water' for x in range(w)] for y in range(h)],spawn=[w//2,h-3],exit=[w//2,2],objects=[],checkpoints=[],signs=[])
def room(d,x1,y1,x2,y2,t='floor'):
 for y in range(y1,y2+1):
  for x in range(x1,x2+1): d['tiles'][y][x]=t
def obj(d,t,x,y,**kw):d['objects'].append(dict(id=f'{t}-{len(d["objects"])}',type=t,pos=[x,y],solid=t in ['pillar','tree','emitter'],**kw))
def rail(d,x,y,tx,ty,pause=3):obj(d,'spike_ball',x,y,behavior='slam_patrol',pause=pause,range=3,directions=[0,90,180,270],waypoints=[[tx,ty]],patrol_loop=True)
def sign(d,x,y,text):d['signs'].append(dict(pos=[x,y],text=text))
def save(name,d):
 ROOT.mkdir(parents=True,exist_ok=True);(ROOT/(name+'.json')).write_text(json.dumps(d,indent=2)+'\n')

# 1. A route around a moat or a chain of hops across its central island.
a=base('Big Hop Boulevard',17,41);a['spawn']=[8,38]
for r in [(4,31,12,39),(2,19,14,32),(3,5,13,21),(7,1,9,5)]:room(a,*r)
room(a,4,34,12,34,'water');a['tiles'][34][4]='path'
room(a,2,30,14,30,'road');obj(a,'car',3,30,speed=.8,length=1,direction=1)
room(a,5,22,11,28,'water');room(a,6,23,10,27,'path')
rail(a,4,36,12,36,4);rail(a,6,25,10,25,3)
room(a,3,15,13,15,'water')
obj(a,'emitter',3,9,rotation=270,interval=4);a['tiles'][9][7]='cheese_wall'
rail(a,5,5,11,5,4)
for x,y in [(3,27),(13,23),(4,12),(12,7)]:obj(a,'pillar',x,y)
a['checkpoints']=[[8,13]]
sign(a,8,38,'BIG HOP BOULEVARD · Tap Long hop, then move.\nSpace arms it on keyboard. Read the copper tracks.')
sign(a,8,35,'Hop across the water, or walk around its west edge.')
sign(a,8,29,'Moat fork: circle the outer bank, or hop onto the island.\nThe short route crosses a moving rail.')
sign(a,8,21,'The two routes meet here.\nTurn to line up the next water crossing.')
sign(a,8,13,'Your only checkpoint.\nUse the side banks to read the dart lane and final rail.')
save('big_hop_boulevard',a)
# 2. Reviewed: retain all terrain/hazards and only the former second-to-last flag.
b=json.loads((Path(__file__).resolve().parent/'level_sources/your_move_crossing_v25.json').read_text());b['checkpoints']=[[10,21]]
# Remove obsolete flag instructions without changing geometry or hazard phase.
for entry in b['signs']:
 if entry['pos']==[10,21]:entry['text']='Your only checkpoint.\nChoose a sheltered detour or the shorter rail court. Blocked hops spend no beat.'
save('your_move_crossing',b)

# 3. Three gathering islands. The visible gate becomes reachable after gathering.
c=base('Shardwater Sanctuary',19,35,'fragments',True);c['spawn']=[9,32];c['exit']=[9,2];c['theme']='swamp'
for r in [(3,26,15,33),(3,16,15,24),(3,7,15,14),(5,1,13,5)]:room(c,*r)
room(c,8,19,10,22,'water')
for x,y in [(6,31),(12,31),(9,27),(5,23),(13,23),(9,17),(5,13),(13,13),(9,8)]:obj(c,'hop_fragment',x,y)
for lo,hi,start,direction in [(3,7,3,1),(11,15,15,-1)]:
 room(c,lo,20,hi,20,'road');obj(c,'car',start,20,speed=1,length=1,direction=direction)
rail(c,6,3,12,3,4)
# Trunks frame the collection arms without concealing pickups.
for x,y in [(4,29),(14,29),(9,12),(4,9),(14,9)]:obj(c,'tree',x,y)
c['checkpoints']=[[9,8]]
sign(c,9,32,'Three triangle fragments earn one long hop.\nLand on them; hopping over one does not collect it.')
sign(c,9,26,'Spend your reserve on the water gate.\nEach island has another three fragments.')
sign(c,9,24,'The pond splits the next gathering loop.\nCross the roads sideways when the next beat is clear.')
sign(c,9,8,'Only checkpoint: it remembers your fragments and reserve.\nOne more water gate; then circle the final copper track.')
save('shardwater_sanctuary',c)

# 4. A switchback seed route: each pickup enables a differently oriented gate.
d=base('The Seed Vault',21,35,'powerup',False);d['spawn']=[3,32];d['exit']=[17,2]
for r in [(1,26,7,33),(9,24,19,30),(12,16,19,22),(3,16,10,22),(2,7,9,14),(11,2,19,10)]:room(d,*r)
for x,y in [(3,29),(17,27),(15,20),(4,18),(6,12)]:obj(d,'hop_seed',x,y)
rail(d,11,26,17,26,4)
obj(d,'critter',17,18,behavior='patrol',speed=1.2,waypoints=[[14,18],[18,18]],patrol_loop=True)
obj(d,'emitter',3,19,rotation=270,interval=5);d['tiles'][19][8]='cheese_wall'
rail(d,3,10,8,10,4);rail(d,13,6,18,6,4)
d['checkpoints']=[[4,14]]
sign(d,3,32,'Diamond Hop seeds each grant one long hop.\nNo timer. Save it for the water gate.')
sign(d,10,28,'Turn north after finding the next seed.\nThe rail has a safe outer bank.')
sign(d,18,22,'Find the seed, then look west.\nThe next gate crosses sideways.')
sign(d,4,14,'Only checkpoint. A seed waits on this side.\nWalk around the rail to save your hop for the eastern gate.')
save('seed_vault',d)

# 5. Two winding recharge circuits. Forward progress refills the reserve; no grind
# is required. Walls isolate terraces so a diagonal camera view cannot hide skips.
e=base('Twenty-Five Terraces',21,43,'charged',True);e['spawn']=[10,40];e['exit']=[10,2]
e['tiles']=[['wall']*21 for _ in range(43)]
def lane(points,width=1):
 for (x,y),(tx,ty) in zip(points,points[1:]):
  assert x==tx or y==ty
  room(e,min(x,tx),min(y,ty),max(x,tx),max(y,ty),'path')
room(e,7,38,13,41)
lane([(10,36),(3,36),(3,30),(14,30),(14,27),(10,27),(10,24)])
room(e,9,24,11,26);room(e,9,21,11,22)
lane([(10,22),(17,22),(17,16),(4,16),(4,10),(10,10),(10,8)])
room(e,9,8,11,9);room(e,8,2,12,6)
for x,y in [(10,37),(10,23),(10,7)]:e['tiles'][y][x]='water'
# Wider lookout/turn pockets, and one extra route around each timed crossing.
for r in [(2,33,4,36),(3,29,6,31),(12,27,15,30),(15,20,18,22),(14,15,18,17),(3,10,5,13)]:room(e,*r)
room(e,8,29,8,32,'road');obj(e,'patrol_car',8,29,speed=1,length=1,direction=1,axis='north_south',waypoints=[])
room(e,10,14,10,17,'road');obj(e,'patrol_car',10,14,speed=1,length=1,direction=1,axis='north_south',waypoints=[])
# Short-hop side-step pockets change the beat without forcing danger contact.
room(e,5,29,5,29);room(e,11,15,11,15)
rail(e,9,4,11,4,4)
e['checkpoints']=[[10,22]]
sign(e,10,40,'Start charged. Spend one long hop on the first water gate.\nThen 25 completed short hops refill it; waiting does not.')
sign(e,10,36,'Follow the winding terrace.\nForward short hops refill the reserve without pacing in place.')
sign(e,4,31,'The road advances when you hop.\nUse the lookout pocket to line up its next position.')
sign(e,10,24,'Second water gate. Check the counter before you jump.\nThe dry bank leaves room to finish any missing short hops.')
sign(e,10,22,'Only checkpoint. Follow the next recharge circuit.\nCharged-rule retries refill your reserve.')
sign(e,10,8,'Last gate. Save your long hop for water.\nOn the far bank, circle the rail or hop when recharged.')
save('twenty_five_terraces',e)
# User-requested harder revision: keep the v25 blockout and apply authored pressure.
# Regeneration is idempotent: stage two always starts from its retained v25 source.
from harden_tile_tours import harden
for index,name in enumerate(['big_hop_boulevard','your_move_crossing','shardwater_sanctuary','seed_vault','twenty_five_terraces']):
 data=json.loads((ROOT/(name+'.json')).read_text())
 harden(data,index)
 save(name,data)
print('Wrote five harder Tile Hop stages; one checkpoint each.')
