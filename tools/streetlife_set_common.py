"""Shared authored content and geometry audits for the six-map NYC Streetlife set."""
from collections import deque
import json
import math
import re
from pathlib import Path

CELL = 1.8
LEVELS = Path(__file__).resolve().parents[1] / 'game/levels'
PROP_SIZE = {'bench': (1.45,.65), 'trash_can':(.7,.7), 'dumpster':(1.35,1.15),
             'pizza_cart':(1.25,1.1), 'mailbox':(.7,.7), 'traffic_cone':(.48,.48),
             'manhole':(.85,.85), 'newsstand':(1.4,1.2),
             'skate_rail':(.2,4), 'skate_ramp':(1.4,4)}
WALKABLE = {'floor','path','road'}

def base(index,title,w,h,spawn,exit):
    return dict(version=1,name=f'STREETLIFE {index:02d} · {title}',theme='nyc',
                width=w,height=h,spawn=list(spawn),exit=list(exit),
                district=title.upper(),level_set='nyc_streetlife',set_index=index,
                tiles=[['wall' if x in (0,w-1) or y in (0,h-1) else 'floor' for x in range(w)] for y in range(h)],
                objects=[],traffic=[],crossings=[])

def rect(level,x0,y0,x1,y1,tile):
    for y in range(y0,y1+1):
        for x in range(x0,x1+1):level['tiles'][y][x]=tile

def prop(level,kind,x,y,rotation=0,solid=True,**extra):
    obj=dict(id=f"set{level['set_index']}-{kind}-{len(level['objects'])}",type='city_prop',variant=kind,
             pos=[round(x,6),round(y,6)],rotation=rotation,solid=solid,**extra)
    level['objects'].append(obj)
    return obj

def roach(level,pos,waypoints,speed=1.2):
    obj=dict(id=f"set{level['set_index']}-roach-{len(level['objects'])}",type='roach',pos=list(pos),
             rotation=0,solid=False,behavior='patrol',speed=speed,waypoints=[list(p) for p in waypoints])
    level['objects'].append(obj)
    return obj

def node(x,y,height=0,trick='cruise'):
    return dict(pos=[round(x,6),round(y,6)],height=height,trick=trick)

def skater(level,variant,speed,route):
    obj=dict(id=f"set{level['set_index']}-skater-{len(level['objects'])}",type='skater',variant=variant,
             pos=route[0]['pos'].copy(),rotation=0,solid=False,speed=speed,route=route)
    level['objects'].append(obj)
    return obj

def rail_with_banks(level,center,length,rotation):
    x,y=center;theta=math.radians(rotation);d=(-math.sin(theta),-math.cos(theta));half=length/CELL/2
    entry=(x-d[0]*half,y-d[1]*half);exit=(x+d[0]*half,y+d[1]*half)
    lowentry=(entry[0]-d[0],entry[1]-d[1]);lowexit=(exit[0]+d[0],exit[1]+d[1])
    prop(level,'skate_rail',x,y,rotation,length=length)
    prop(level,'skate_ramp',(lowentry[0]+entry[0])/2,(lowentry[1]+entry[1])/2,rotation,rise=.605,length=CELL)
    prop(level,'skate_ramp',(lowexit[0]+exit[0])/2,(lowexit[1]+exit[1])/2,(rotation+180)%360,rise=.605,length=CELL)
    return [node(*lowentry,trick='ramp'),node(*entry,.605,'grind'),node(*exit,.605,'ramp'),node(*lowexit)]

def banks(level,center,length=4,rise=.7,rotation=270):
    x,y=center;theta=math.radians(rotation);d=(-math.sin(theta),-math.cos(theta));half=length/CELL
    prop(level,'skate_ramp',x-d[0]*half/2,y-d[1]*half/2,rotation,rise=rise,length=length)
    prop(level,'skate_ramp',x+d[0]*half/2,y+d[1]*half/2,(rotation+180)%360,rise=rise,length=length)
    return [node(x-d[0]*half,y-d[1]*half,0,'ramp'),node(x,y,rise,'ramp'),node(x+d[0]*half,y+d[1]*half)]

def lane(level,row,direction,speed,spacing,offset,vehicles):
    rect(level,1,row,level['width']-2,row,'road')
    level['traffic'].append(dict(row=row,direction=direction,speed=speed,spacing=spacing,offset=offset,vehicles=vehicles))

def local_point(obj,p):
    angle=math.radians(obj.get('rotation',0));dx=(p[0]-obj['pos'][0])*CELL;dy=(p[1]-obj['pos'][1])*CELL
    return (dx*math.cos(angle)-dy*math.sin(angle),dx*math.sin(angle)+dy*math.cos(angle))

def dimensions(obj):
    if obj['type']=='city_prop':
        w,h=PROP_SIZE[obj['variant']];return w,obj.get('length',h)
    if obj['type']=='tree':return .55,.55
    return .85,.85

def segment_rect_clear(a,b,obj,margin):
    a=local_point(obj,a);b=local_point(obj,b);dims=dimensions(obj);half=(dims[0]/2+margin,dims[1]/2+margin)
    lo,hi=0.,1.
    for axis in (0,1):
        delta=b[axis]-a[axis]
        if abs(delta)<1e-9:
            if abs(a[axis])>half[axis]:return True
        else:
            first=(-half[axis]-a[axis])/delta;last=(half[axis]-a[axis])/delta
            lo=max(lo,min(first,last));hi=min(hi,max(first,last))
            if lo>hi:return True
    return False

def route(level,extra_blocked=()):
    start=tuple(level['spawn']);goal=tuple(level['exit']);seen={start:None};queue=deque([start]);extra=set(extra_blocked)
    solids=[o for o in level['objects'] if o.get('solid',False) or o['type'] in ('pillar','tree','emitter')]
    while queue:
        p=queue.popleft()
        if p==goal:
            result=[]
            while p!=start:result.append(p);p=seen[p]
            return list(reversed(result))
        for q in ((p[0]-1,p[1]),(p[0]+1,p[1]),(p[0],p[1]-1),(p[0],p[1]+1)):
            if q in seen or q in extra or not(0<=q[0]<level['width'] and 0<=q[1]<level['height']):continue
            if level['tiles'][q[1]][q[0]] not in WALKABLE:continue
            if any(not segment_rect_clear(p,q,o,.34) for o in solids):continue
            seen[q]=p;queue.append(q)
    return []

def audit_support(level, point, height):
    """Elevated route samples must match an actual ramp surface or rail truck support."""
    if height <= .015:return
    for feature in level['objects']:
        if feature['type']!='city_prop' or feature['variant'] not in ('skate_ramp','skate_rail'):continue
        x,z=local_point(feature,point);length=feature.get('length',4.)
        if abs(z)>length/2+.015:continue
        if feature['variant']=='skate_rail':
            if abs(x)<=.10 and abs(height-.605)<.015:return
        else:
            surface=feature.get('rise',.7)*(.5-z/length)
            if abs(x)<=.7+.015 and abs(height-surface)<.015:return
    raise AssertionError(f"Elevated rider has no matching support at {point}, height={height}")

def audit(level):
    # Fail when runtime envelopes change instead of silently authoring stale clearances.
    source=(Path(__file__).resolve().parents[1]/'game/scripts/streetlife_specs.gd').read_text()
    runtime={kind:(float(x),float(z)) for kind,x,z in re.findall(r'"([^"]+)": Vector2\(([\d.]+),\s*([\d.]+)\)',source)}
    assert runtime==PROP_SIZE, 'Update the generator footprint contract from streetlife_specs.gd'
    w,h=level['width'],level['height'];assert 5<=w<=25 and 5<=h<=25
    assert len(level['tiles'])==h and all(len(r)==w for r in level['tiles'])
    assert len({o['id'] for o in level['objects']})==len(level['objects']) and len(level['objects'])<=180
    for p in (level['spawn'],level['exit']):assert level['tiles'][p[1]][p[0]] in ('floor','path')
    furniture=[o for o in level['objects'] if (o.get('solid',False) or o['type'] in ('pillar','tree','emitter')) and not(o['type']=='city_prop' and o['variant'] in ('skate_ramp','skate_rail'))]
    for o in level['objects']:
        x,y=o['pos'];assert level['tiles'][int(y)][int(x)] in WALKABLE, (o['id'],o['pos'])
        if o['type']=='roach':
            for p in o.get('waypoints',[]):assert level['tiles'][int(p[1])][int(p[0])] in WALKABLE
        if o['type']!='skater':continue
        assert o['pos']==o['route'][0]['pos'] and 4<=len(o['route'])<=32 and 2<=o['speed']<=5.5
        for i,a in enumerate(o['route']):
            b=o['route'][(i+1)%len(o['route'])];assert math.dist(a['pos'],b['pos'])>.1
            assert a['trick'] in ('cruise','push','grind','ramp') and 0<=a['height']<=1.2
            for sample in range(101):
                p=[a['pos'][axis]+(b['pos'][axis]-a['pos'][axis])*sample/100 for axis in (0,1)]
                assert level['tiles'][round(p[1])][round(p[0])] in WALKABLE, (o['id'],p)
                audit_support(level,p,a['height']+(b['height']-a['height'])*sample/100)
                if 'skate_area' in level:assert math.dist(p,level['skate_area']['center'])<=level['skate_area']['diameter']/2+1e-6
            for obstacle in furniture:assert segment_rect_clear(a['pos'],b['pos'],obstacle,.42),(o['id'],obstacle['id'])
    for lane_spec in level['traffic']:
        y=lane_spec['row'];assert all(level['tiles'][y][x]=='road' for x in range(1,w-1))
        assert not any(abs(o['pos'][1]-y)<.85 for o in level['objects'])
        assert 2<=lane_spec['speed']<=8 and 7<=lane_spec['spacing']<=20
    for gate in level.get('required_gates',[]):
        blocked=[(x,y) for y in range(gate['rect'][1],gate['rect'][3]+1) for x in range(gate['rect'][0],gate['rect'][2]+1)]
        assert not route(level,blocked),f"Gate can be bypassed: {gate['name']}"
    result=route(level);assert result,f"No clearance route: {level['name']}"
    return result

def save(level,slug):
    LEVELS.mkdir(exist_ok=True)
    (LEVELS/f'{slug}.json').write_text(json.dumps(level,ensure_ascii=False,indent=2)+'\n')
