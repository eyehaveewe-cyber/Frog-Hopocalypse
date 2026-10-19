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
def room(d,x1,y1,x2,y2,t='floor'):
 for y in range(y1,y2+1):
  for x in range(x1,x2+1):d['tiles'][y][x]=t
def wall_start(d):
 d['tiles']=[['wall']*d['width'] for _ in range(d['height'])]
def rail(d,x,y,tx,ty,pause=2):
 obj(d,'spike_ball',x,y,behavior='slam_patrol',pause=pause,range=3,directions=[0,90,180,270],waypoints=[[tx,ty]],patrol_loop=True)
def shift(d,x,y,directions=(0,90,180,270),distance=2,pause=2):
 obj(d,'spike_ball',x,y,behavior='free_shift',pause=pause,range=distance,directions=list(directions),waypoints=[],patrol_loop=True)

a=base('Big Hop Boulevard',17,49,'tile',False);wall_start(a)
# Four encounter courts linked by bends; no straight centerline bypass.
for rect in [(5,38,11,47),(3,29,13,38),(10,23,14,29),(3,21,14,24),(3,17,7,23),(2,7,14,17),(5,3,11,7),(7,1,9,3)]:room(a,*rect)
# Approach gates give two visible entry positions, then an unavoidable double road.
room(a,3,36,13,36,'wall')
for x in [5,11]:a['tiles'][36][x]='path'
for y in [33,34]:
 for x in range(3,14):a['tiles'][y][x]='road'
obj(a,'car',4,34,speed=0.8,length=1,direction=1)
obj(a,'car',12,33,speed=0.8,length=1,direction=-1)
for x in range(3,14):a['tiles'][30][x]='water'
# First isolated rail, then a second rail at a turn and a free-shift court.
rail(a,6,42,10,42,pause=3)
rail(a,10,25,14,25)
shift(a,4,20,distance=2,pause=3)
room(a,3,18,7,18,"water")
room(a,3,22,7,22,"water")
room(a,8,19,8,21,"wall")
for x in range(2,15):a['tiles'][16][x]='wall'
a['tiles'][16][5]='path'
for x in range(2,15):a['tiles'][14][x]='water'
# A dart lane, a bug crossing and traffic are separated by safe rows.
obj(a,'emitter',3,11,interval=3);a['objects'][-1]['rotation']=270
obj(a,'critter',5,10,behavior='patrol',speed=1.2,waypoints=[[5,10],[11,10]],patrol_loop=True)
a['tiles'][11][7]='cheese_wall'
obj(a,'pillar',8,9)
for x in range(2,15):a['tiles'][8][x]='road'
obj(a,'car',12,8,speed=0.8,length=1,direction=-1)
rail(a,6,5,10,5)
for x,y in [(6,45),(10,39),(3,37),(13,31),(14,28),(13,23),(10,22),(7,17),(2,13),(14,12)]:obj(a,'tree',x,y)
# Four refuge checkpoints sit outside every danger track.
a['checkpoints']=[[8,38],[12,28],[5,17],[8,7]]
sign(a,8,46,'CLOCKWORK BOULEVARD · Time keeps moving.\nCopper tracks announce the next spike slam.')
sign(a,8,43,'Watch one slam from the lower bank.\nThen cross, or long-hop the moving rail.')
sign(a,8,37,'Two streets, two approaches.\nChoose your landing; a long hop does not clear both lanes.')
sign(a,12,28,'Rest at the flag, then turn left above the rail.\nThe next ball can shift in four directions.')
sign(a,5,17,'A quiet landing before the final court.\nDarts pass through cheese; your frog cannot.')
sign(a,8,7,'Last copper rail. Read its next destination\nbefore committing to the gate.')
save(Path('tile_hop/big_hop_boulevard.json'),a)

b=base('Your Move Crossing',21,41,'tile',True);wall_start(b);b['spawn']=[3,38];b['exit']=[17,2]
for rect in [(1,32,7,39),(6,29,14,33),(14,27,19,30),(11,19,19,28),(2,12,12,21),(10,3,19,12),(16,1,18,3)]:room(b,*rect)
room(b,1,32,14,33,'wall')
room(b,1,33,5,33)
room(b,6,32,6,33,'path')
rail(b,2,35,6,35)
# Sideways long-hop bridge: a one-cell gap spanning the three-cell crossing.
for y in range(29,32):b['tiles'][y][9]='water'
room(b,11,27,19,27,'wall');b['tiles'][27][18]='path'
# Vertical road patrols force a genuinely sideways crossing choice.
for y in range(19,27):
 for x in [14,15]:b['tiles'][y][x]='road'
obj(b,'patrol_car',14,21,speed=1,length=1,direction=1,axis='north_south',waypoints=[])
obj(b,'patrol_car',15,26,speed=1,length=1,direction=-1,axis='north_south',waypoints=[])
shift(b,18,23,directions=(0,180),distance=2,pause=2)
# Two mouths into the next court: lower shelter or shorter, exposed upper line.
room(b,11,19,11,26,'wall')
b['tiles'][21][11]='path';b['tiles'][25][11]='path'
room(b,9,21,11,25)
rail(b,4,17,9,17)
obj(b,'pillar',4,16)
obj(b,'emitter',3,14,interval=3);b['objects'][-1]['rotation']=270
b['tiles'][14][7]='cheese_wall'
obj(b,'pillar',9,15)
# Final vault: walls shape an outer loop; water offers a shorter inside hop.
room(b,10,10,19,10,'wall')
for x in [11,17]:b['tiles'][10][x]='water'
room(b,10,4,19,4,'water')
for y in [9,10,11]:b['tiles'][y][14]='water'
obj(b,'pillar',13,8);obj(b,'pillar',16,6)
shift(b,15,8,distance=2,pause=2)
obj(b,'critter',11,5,behavior='patrol',speed=1.2,waypoints=[[11,5],[18,5]],patrol_loop=True)
for x,y in [(1,37),(7,34),(6,31),(13,29),(19,28),(12,23),(2,20),(2,13),(11,15),(19,3)]:obj(b,'tree',x,y)
b['checkpoints']=[[6,33],[12,30],[10,21],[12,11]]
sign(b,3,38,'YOUR MOVE CROSSING · Every hop changes the clock.\nWhile you rest, the marked spike target stays fixed.')
sign(b,6,33,'Turn onto the bridge.\nLong hops work sideways, too.')
sign(b,12,30,'Vertical patrol cars stay on their roads.\nCross sideways where the next beat leaves room.')
sign(b,17,25,'This spike shifts north or south.\nUse the outer loop to change the timing before crossing.')
sign(b,10,21,'Choose a sheltered detour or the shorter rail court.\nA blocked hop never spends a beat.')
sign(b,10,13,'Cheese blocks your frog, but darts pass through.\nLong-hop into either vault gate; a sideways gap shortens the approach.')
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

# Current tour revision supersedes the original two-stage blockouts above.
import runpy
runpy.run_path(str(Path(__file__).with_name("design_tile_tours.py")))
