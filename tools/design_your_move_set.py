"""Five authored movement-linked challenges, deterministic maps and legal route witnesses.
This adds new maps only. Existing Tile Hop, custom maps and Bonus layouts are untouched.
"""
from pathlib import Path
import json
from collections import deque
from your_move_traffic import positions, safe
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'game/levels/your_move'
OUT.mkdir(exist_ok=True)

def base(name,w,h,theme='egypt',rule='free'):
    return dict(version=1,name=name,theme=theme,width=w,height=h,game_mode='tile',move_with_me=True,draw_distance=18,
                rules={'long_hop':rule,'charge_hops':10},tiles=[['wall']*w for _ in range(h)],
                spawn=[3,h-3],exit=[w-4,2],objects=[],checkpoints=[],signs=[])
def room(d,x1,y1,x2,y2,t='floor'):
    for y in range(y1,y2+1):
        for x in range(x1,x2+1): d['tiles'][y][x]=t
def obj(d,t,x,y,**kw):
    d['objects'].append(dict(id=f'your-move-{t}-{len(d["objects"])}',type=t,pos=[x,y],solid=t in ['pillar','tree','emitter'],**kw))
def car(d,x,y,direction=1,patrol=False,axis='east_west',length=1):
    obj(d,'patrol_car' if patrol else 'car',x,y,direction=direction,speed=1,length=length,axis=axis,waypoints=[],patrol_loop=True)
def rail(d,x,y,tx,ty,pause=2):
    obj(d,'spike_ball',x,y,behavior='slam_patrol',pause=pause,range=3,directions=[0,90,180,270],waypoints=[[tx,ty]],patrol_loop=True)
def sign(d,x,y,text): d['signs'].append(dict(pos=[x,y],text=text))
def route(d,goals,big_pairs=()):
    """Cell-only witness; survival is independently checked through real Godot physics."""
    blocked={tuple(o['pos']) for o in d['objects'] if o['solid']}
    pos=tuple(d['spawn']);actions=[];movers=positions(d)
    for goal in goals:
        goal=tuple(goal)
        if (pos,goal) in big_pairs:
            dx=(goal[0]-pos[0])//2;dy=(goal[1]-pos[1])//2
            assert abs(dx)+abs(dy)==1
            actions.append(dict(direction=[dx,dy],big=True,wait=0));pos=goal;continue
        origin=(pos,0);q=deque([origin]);prev={origin:None};found=None
        while q:
            entry=q.popleft();(x,y),extra=entry
            if (x,y)==goal:found=entry;break
            if extra>120:continue
            for dx,dy in [(0,-1),(1,0),(0,1),(-1,0)]:
                p=(x+dx,y+dy)
                node=(p,extra+1)
                if node in prev or p in blocked or not(0<=p[0]<d['width'] and 0<=p[1]<d['height']):continue
                if d['tiles'][p[1]][p[0]] in ['wall','cheese_wall']:continue
                if d['tiles'][p[1]][p[0]] == 'water' and not (p==goal and any(o['type']=='log' and o['pos'][1]==p[1] for o in d['objects'])):continue
                if not safe(movers,(x,y),p,len(actions)+extra,False):continue
                prev[node]=(entry,[dx,dy]);q.append(node)
        assert found is not None,(d['name'],pos,goal)
        p=found;steps=[]
        while p!=origin:
            old,di=prev[p];steps.append(dict(direction=di,big=False,wait=0));p=old
        actions.extend(reversed(steps));pos=goal
    return dict(actions=actions,goals=goals)
def save(key,d,goals,big_pairs=()):
    (OUT/(key+'.json')).write_text(json.dumps(d,indent=2)+'\n')
    witness=route(d,goals,big_pairs);witness['level']='res://levels/your_move/'+key+'.json'
    (ROOT/'game/tests/routes'/('your_move_'+key+'.json')).write_text(json.dumps(witness,indent=2)+'\n')
    checkpoint=d['checkpoints'][0]
    start=goals.index(checkpoint)+1
    retry=dict(d,spawn=checkpoint)
    retry_witness=route(retry,goals[start:],big_pairs)
    retry_witness['level']=witness['level']
    (ROOT/'game/tests/routes'/('your_move_retry_'+key+'.json')).write_text(json.dumps(retry_witness,indent=2)+'\n')
    print(key,len(d['objects']),'objects',len(witness['actions']),'hops')

# 1. Two offset crossings around a courtyard, with sheltered sidestep pockets.
a=base('One Step Ahead',17,25)
room(a,2,17,7,23);room(a,2,12,14,18);room(a,9,6,14,13);room(a,3,2,14,7)
room(a,2,16,14,16,'road');car(a,10,16,-1)
room(a,10,6,10,12,'road');car(a,10,9,1,True,'north_south')
room(a,5,4,12,4,'road');car(a,7,4,1)
for p in [(6,19),(3,13),(13,9),(4,6)]:obj(a,'pillar',*p)
a['checkpoints']=[[12,7]]
sign(a,3,22,'ONE STEP AHEAD\nNo move, no traffic. Sidestep on the bank to change the next crossing.')
sign(a,6,17,'The car takes one tile when you hop.\nWaiting here changes nothing. Watch its next tile.')
sign(a,12,7,'Only checkpoint. Turn west, then north.\nA long hop also spends exactly one traffic beat.')
save('one_step_ahead',a,[[6,17],[6,15],[12,14],[12,11],[11,10],[9,10],[9,7],[12,7],[11,6],[9,6],[8,6],[8,5],[8,3],[13,2]],{((11,6),(9,6)),((8,5),(8,3))})

# 2. Two firing directions and a copper rail; cheese shelters movement, not darts.
b=base('Needle Clock',19,29,'swamp')
room(b,2,21,8,27);room(b,5,14,16,22);room(b,2,6,12,15);room(b,8,1,16,7)
room(b,8,17,8,21,'wall');b['tiles'][19][8]='cheese_wall'
obj(b,'emitter',15,19,rotation=90,interval=4)
room(b,5,7,5,13,'wall');b['tiles'][10][5]='cheese_wall'
obj(b,'emitter',3,7,rotation=180,interval=3)
rail(b,8,12,12,12,3)
for p in [(7,24),(14,21),(11,15),(9,5)]:obj(b,'tree',*p)
b['checkpoints']=[[9,8]]
sign(b,3,26,'NEEDLE CLOCK\nEvery hop advances the darts. Stop to read the next step.')
sign(b,7,21,'Cheese blocks frogs, not darts.\nUse the lower pocket, then cross the firing row.')
sign(b,9,8,'Only checkpoint. The north dart lane\nturns the last corner into a counting problem.')
save('needle_clock',b,[[6,22],[6,20],[6,18],[10,17],[10,14],[7,14],[7,11],[7,8],[9,8],[12,6],[15,2]])

# 3. Three fragments earn a canal crossing. Gathering changes the patrol phase.
c=base('Shard Switchyard',21,31,'mexico','fragments')
room(c,2,22,17,28);room(c,2,21,17,21,'water');room(c,3,13,18,20)
room(c,6,12,18,12,'water');room(c,6,2,18,11)
room(c,9,23,9,27,'road');car(c,9,25,1,True,'north_south')
room(c,4,17,17,17,'road');car(c,13,17,-1);car(c,6,17,1)
for p in [(4,26),(13,26),(6,23),(15,19),(7,19),(11,14)]:obj(c,'hop_fragment',*p)
rail(c,8,7,15,7,3)
for p in [(3,24),(16,24),(5,15),(17,10),(7,4)]:obj(c,'pillar',*p)
c['checkpoints']=[[15,10]]
sign(c,3,28,'SHARD SWITCHYARD\nCollecting the three pieces also moves the patrol.\nChoose where to cross it.')
sign(c,6,22,'One set, one leap. No spare reserve.\nThe next court has a fresh trio.')
sign(c,15,10,'Only checkpoint. Your fragments stay with you.\nWork around the copper rail to the northern exit.')
save('shard_switchyard',c,[[4,26],[8,26],[8,27],[8,26],[13,26],[6,23],[6,22],[6,20],[15,19],[7,19],[11,14],[15,13],[15,11],[15,10],[16,8],[16,5],[17,2]],{((6,22),(6,20)),((15,13),(15,11))})

# 4. A connected jungle waterway and log landing, then a seed-funded side gate.
d=base('Stillwater Circuit',21,33,'honduras','powerup')
room(d,2,25,8,30);room(d,2,24,17,24,'water');room(d,3,16,17,23)
room(d,18,16,18,22,'water');room(d,19,16,19,22)
room(d,12,7,19,15);room(d,4,2,19,8);room(d,3,15,18,15,'water')
# A broad log moves one tile per hop; its next position is the landing target.
obj(d,'log',15,24,speed=1,direction=-1,length=2)
obj(d,'hop_seed',14,19);obj(d,'hop_seed',12,9)
rail(d,9,20,13,20,2)
room(d,6,5,14,5,'road');car(d,8,5,-1)
for p in [(3,27),(16,22),(14,12),(5,7)]:obj(d,'tree',*p)
d['checkpoints']=[[17,13]]
sign(d,3,30,'STILLWATER CIRCUIT\nThe log freezes with you. Land where it goes next,\nthen hop off on the next move.')
sign(d,7,23,'Turn east for a Hop seed.\nCarry it to the side channel; count the rail first.')
sign(d,17,13,'Only checkpoint. Take the western garden\nto reach the final reversing road.')
save('stillwater_circuit',d,[[6,25],[6,24],[6,23],[14,19],[17,19],[19,19],[19,15],[17,13],[15,10],[12,9],[12,8],[8,7],[8,6],[8,4],[17,2]],{((17,19),(19,19)),((8,6),(8,4))})

# 5. Hard traffic: paired lanes, median islands and a north/south road grid.
e=base('Rush Hourglass',25,35,'egypt','charged')
e['rules']['charge_hops']=10;e['spawn']=[4,32];e['exit']=[20,2]
room(e,2,27,22,33);room(e,2,25,22,26,'road');room(e,2,22,22,24)
room(e,2,20,22,21,'road');room(e,2,17,22,19)
room(e,3,8,21,16);room(e,3,2,21,7)
for y,x,di in [(26,5,1),(26,16,-1),(25,10,-1),(25,20,1),(21,4,1),(21,15,-1),(20,9,-1),(20,21,1)]:car(e,x,y,di,length=1.25)
for x,start,di in [(8,10,1),(12,14,-1),(16,11,1)]:
 room(e,x,8,x,16,'road');car(e,x,start,di,True,'north_south',1)
room(e,4,5,20,5,'road');room(e,4,4,20,4,'road');car(e,6,5,1,length=1.3);car(e,16,5,-1,length=1.3);car(e,11,4,-1,length=1.3)
# Blocked median furniture makes route selection matter without hiding cars.
for p in [(5,23),(6,23),(14,23),(15,23),(7,18),(18,18),(5,10),(18,14),(19,7)]:obj(e,'pillar',*p)
e['checkpoints']=[[19,8]]
sign(e,4,32,'RUSH HOURGLASS\nHard traffic. Each hop moves every lane once.\nLong hops refill after ten short hops.')
sign(e,10,28,'Paired lanes: jumping the first car can land\nyou in the second. Choose your landing before moving.')
sign(e,10,23,'Median islands are safe planning ground.\nSideways hops change all lanes, including the next road.')
sign(e,19,8,'Only checkpoint. The final double road\nchecks the same rule in a tighter space.')
save('rush_hourglass',e,[[10,28],[10,24],[20,23],[20,19],[19,17],[19,13],[17,12],[15,12],[13,10],[11,10],[9,13],[7,13],[7,8],[19,8],[18,6],[18,3],[20,2]])
