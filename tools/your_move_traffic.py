"""Deterministic traffic positions and swept-collision route witness planning.
Matches tile-mode one-cell traffic beats. Real Godot replay remains authoritative.
"""
from math import sin,pi
CELL=1.8

def positions(d,limit=1400):
    movers=[]
    for o in d['objects']:
        if o['type'] not in ['car','patrol_car']:continue
        p=tuple(o['pos']);di=o.get('direction',1);vertical=o['type']=='patrol_car' and o.get('axis')=='north_south'
        frames=[p]
        for _ in range(limit):
            step=(0,di) if vertical else (di,0)
            n=tuple(p[j]+step[j] for j in range(2))
            if not(0<=n[0]<d['width'] and 0<=n[1]<d['height']) or d['tiles'][n[1]][n[0]]!='road':
                di=-di;step=tuple(-s for s in step);n=tuple(p[j]+step[j] for j in range(2))
            if not(0<=n[0]<d['width'] and 0<=n[1]<d['height']) or d['tiles'][n[1]][n[0]]!='road':n=p
            frames.append(n);p=n
        movers.append((o,vertical,frames))
    return movers

def swept(a,b,half):
    lo,hi=0.,1.
    for j in range(2):
        delta=b[j]-a[j]
        if abs(delta)<1e-8:
            if abs(a[j])>half[j]:return False
        else:
            t1=(-half[j]-a[j])/delta;t2=(half[j]-a[j])/delta
            lo=max(lo,min(t1,t2));hi=min(hi,max(t1,t2))
            if lo>hi:return False
    return True

def safe(movers,start,end,beat,big):
    for o,vertical,frames in movers:
        a,b=frames[beat],frames[beat+1]
        half=(.81,o.get('length',1)*CELL/2+.28) if vertical else (o.get('length',1)*CELL/2+.28,.81)
        previous=[(start[j]-a[j])*CELL for j in range(2)]
        for i in range(1,22):
            t=min(1,i/20.4)
            current=[(start[j]+(end[j]-start[j])*t-a[j]-(b[j]-a[j])*t)*CELL for j in range(2)]
            if not(big and sin(pi*t)>.48) and swept(previous,current,half):return False
            previous=current
    return True
