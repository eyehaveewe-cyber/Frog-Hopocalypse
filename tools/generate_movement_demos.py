import json
from pathlib import Path
root=Path(__file__).resolve().parents[1] / 'game' / 'levels'
def base(name,w,h,mode,linked):
 return dict(version=1,name=name,theme='egypt',width=w,height=h,game_mode=mode,move_with_me=linked,draw_distance=18,tiles=[['wall' if x in (0,w-1) or y in (0,h-1) else 'floor' for x in range(w)] for y in range(h)],spawn=[w//2,h-3],exit=[w//2,2],objects=[],checkpoints=[],signs=[])
def obj(d,t,x,y,**kw):
 d['objects'].append(dict(id=f"{t}-{len(d['objects'])}",type=t,pos=[x,y],rotation=0,solid=t in ['tree','pillar','emitter'],**kw))
def band(d,y,t):
 for x in range(1,d['width']-1):d['tiles'][y][x]=t

def sign(d,x,y,text):d['signs'].append(dict(pos=[x,y],text=text))
def save(path,d):
 p=root/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(d,indent=2)+'\n')
a=base('Big Hop Boulevard',17,49,'tile',False)
for y in range(1,48):a['tiles'][y][8]='path'
# Safe first obstacle and a full-width one-cell ditch teach the long-hop verb.
obj(a,'tree',8,43)
band(a,37,'water')
for y in [31,32,22,9]:band(a,y,'road')
for x,y,direction in [(2,31,1),(13,32,-1),(3,22,1),(12,9,-1)]:obj(a,'car',x,y,speed=0.8,length=1.0,direction=direction)
band(a,25,'water');obj(a,'log',6,25,speed=0.8,length=4.6,direction=1);obj(a,'log',13,25,speed=0.8,length=3.0,direction=-1)
obj(a,'critter',4,19,behavior='patrol',speed=1.2,waypoints=[[4,19],[11,19]],patrol_loop=True)
obj(a,'emitter',3,15,interval=2.5);a['objects'][-1]['rotation']=270
obj(a,'pillar',8,12)
a['checkpoints']=[[8,35],[8,27],[8,18],[8,6]]
for y in [40,34,29,20,13,5]:
 for x in [2,14]:obj(a,'tree',x,y)
sign(a,8,46,'TILE HOP\nArrows / WASD: one tile')
sign(a,8,44,'SHIFT + direction / Long hop\nTwo tiles. Clear the middle obstacle.')
sign(a,8,39,'A long hop clears one water tile.\nLand on safe ground or a log.')
sign(a,8,34,'Cars move tile by tile.\nWait for a gap; land clear.')
sign(a,8,17,'Long hops clear bugs and darts in midair.\nTakeoff and landing are vulnerable.')
save(Path('tile_hop/big_hop_boulevard.json'),a)
b=base('Your Move Crossing',21,41,'tile',True);b['spawn']=[3,38];b['exit']=[17,2]
for y in range(1,40):b['tiles'][y][3 if y>20 else 17]='path'
for x in range(3,18):b['tiles'][20][x]='path'
for y in [34,24,7]:band(b,y,'road')
for x,y,direction in [(13,34,-1),(3,24,1),(12,7,-1)]:obj(b,'car',x,y,speed=1,length=1,direction=direction)
band(b,29,'water');band(b,12,'water')
obj(b,'critter',7,26,behavior='patrol',speed=1.2,waypoints=[[7,26],[13,26]],patrol_loop=True)
obj(b,'critter',17,16,behavior='patrol',speed=1.2,waypoints=[[17,16],[12,16]],patrol_loop=True)
obj(b,'pillar',3,36)
obj(b,'emitter',12,18,interval=1.8);b['objects'][-1]['rotation']=270
for x in range(1,16):b['tiles'][21][x]='wall'
for x in range(6,20):b['tiles'][10][x]='wall'
b['tiles'][10][17]='path'
b['checkpoints']=[[3,32],[17,20],[17,14],[17,5]]
sign(b,3,38,'MOVE WITH ME\nStop hopping: hazards freeze.')
sign(b,3,31,'One valid hop = one hazard beat.\nBlocked hops do not advance time.')
sign(b,15,22,'Walls block short AND long hops.\nGo around this barrier.')
sign(b,17,17,'Watch the dart, then commit.\nIt advances one tile per hop.')
save(Path('tile_hop/your_move_crossing.json'),b)
c=base('Your Move Garden',17,33,'hopan',True)
for y in range(1,32):c['tiles'][y][8]='path'
for y in [25,19,8]:band(c,y,'road')
for x,y,direction in [(2,25,1),(14,19,-1),(13,8,1)]:obj(c,'car',x,y,speed=0.85,length=1.5,direction=direction)
band(c,14,'water');obj(c,'log',5,14,speed=0.7,length=5.5,direction=1);obj(c,'log',13,14,speed=0.7,length=5.5,direction=-1)
obj(c,'critter',3,11,behavior='patrol',speed=1.0,waypoints=[[3,11],[6,11]],patrol_loop=True)
obj(c,'emitter',3,5,interval=2.5);c['objects'][-1]['rotation']=270
c['checkpoints']=[[8,22],[8,16],[8,11]]
sign(c,8,30,'REGULAR HOPÁN + MOVE WITH ME\nWalk to advance hazards. Stop to plan.')
sign(c,8,16,'Logs also freeze while you rest.\nLine up before walking onto one.')
save(Path('bonus/your_move_hopan.json'),c)
