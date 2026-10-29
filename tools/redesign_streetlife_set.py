#!/usr/bin/env python3
"""Apply the authored Streetlife hard pass without changing engine rules or other sets.
Repeated runs are idempotent. Existing city art and IDs are retained.
"""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def gate(d,y,openings):
    for x in range(1,d['width']-1):d['tiles'][y][x]='path' if x in openings else 'wall'
def wall(d,x,y):d['tiles'][y][x]='wall'
def obj(d,key):return next(o for o in d['objects'] if o['id']==key)
def put(d,o):
    d['objects']=[p for p in d['objects'] if p['id']!=o['id']]+[o]
def roach(d,key,points,speed):
    o=next((p for p in d['objects'] if p['id']==key),{'id':key,'type':'roach','solid':False,'rotation':0})
    o.update(pos=points[0],waypoints=points,behavior='patrol',speed=speed);put(d,o)
def skater(d,key,points,speed,variant):
    put(d,{'id':key,'type':'skater','solid':False,'rotation':0,'variant':variant,'pos':points[0], 'speed':speed,'route':[{'pos':p,'height':0,'trick':'push' if i%2==0 else 'cruise'} for i,p in enumerate(points)]})
def signs(d,entries):d['signs']=[{'pos':p,'text':t} for p,t in entries]

for file in sorted((ROOT/'game/levels').glob('streetlife_*.json')):
    d=json.loads(file.read_text());i=d['set_index']
    d['difficulty_target']='Hard: timing and route planning. Human attempt count not calibrated.'
    if i==1:
        gate(d,13,[8,9]);gate(d,10,[4]);gate(d,7,[11,12]);gate(d,5,[12]);gate(d,3,[6,7])
        # The bin stays beside the first alley rather than inside a divider.
        obj(d,'set1-bench-5')['pos']=[7,8]
        obj(d,'set1-trash_can-7')['pos']=[14,9]
        obj(d,'set1-traffic_cone-9')['pos']=[10,2]
        roach(d,'set1-roach-0',[[3,11],[6,11]],1.65)
        roach(d,'set1-roach-1',[[13,6],[10,6]],1.8)
        roach(d,'hard1-approach',[[7,14],[10,14]],1.9)
        roach(d,'hard1-center',[[9,8],[13,8]],2.0)
        roach(d,'hard1-exit',[[5,4],[9,4]],1.75)
        d['hint']='Watch the alley mouths. Each landing changes the next crossing line.'
        d['description']='Offset stoop passages lead through five readable roach crossings. Broad landings let you observe the next patrol before committing to a narrow alley.'
        signs(d,[([3,15],'Watch each patrol turn before entering its alley.'),([7,9],'The next opening is across the court. Stop on the landing to read both patrols.')])
    elif i==2:
        gate(d,15,[9,10]);gate(d,3,[10,11]);gate(d,9,[5,6,13,14,15,16,17])
        # Close the long safe outer-wall bypass. Two different ring routes remain.
        for y in range(4,15):
            for x in [1,2,3,18,19]:wall(d,x,y)
        obj(d,'set2-bench-6')['pos']=[4,10]
        obj(d,'set2-traffic_cone-7')['pos']=[16,9]
        obj(d,'set2-trash_can-9')['pos']=[16,5]
        roach(d,'set2-roach-12',[[4,7],[6,7],[6,8],[4,8]],1.85)
        skater(d,'hard2-west-return',[[5,12],[6,12],[6,5],[5,5]],3.6,2)
        obj(d,'set2-skater-0')['speed']=3.5
        obj(d,'set2-skater-1')['speed']=3.8
        d['hint']='Choose a side of the newsstands. The shorter west alley has a returning rider; the wider east path has crossed loops.'
        d['description']='A closed newsstand island splits two skate routes. The west alley is shorter and narrow; the east route gives more room but crosses a second circuit. Entry and exit require reading the outer rider.'
        signs(d,[([10,17],'Watch the outer circuit before entering.'),([10,14],'West is narrow. East has another circuit. Choose a route before the board returns.')])
    elif i==3:
        gate(d,16,[14,15]);gate(d,14,[18,19]);gate(d,5,[10,11]);gate(d,3,[18,19])
        obj(d,'set3-mailbox-8')['pos']=[18,17]
        obj(d,'set3-trash_can-6')['pos']=[5,17]
        obj(d,'set3-dumpster-7')['pos']=[3,17]
        roach(d,'set3-roach-12',[[13,15],[16,15]],1.8)
        roach(d,'set3-roach-13',[[17,13],[19,13]],2.0)
        skater(d,'hard3-pier-return',[[14,12],[19,12],[19,8],[14,8]],3.7,0)
        roach(d,'hard3-gangway',[[9,6],[12,6]],1.9)
        d['hint']='Change sides on the forecourt, then watch both pier circuits. The rail ends leave room to pass.'
        d['description']='The ferry approach folds through two loading gates before a pier shared by a grind rider and a returning board. The north forecourt requires another change of line before the departure gate.'
        signs(d,[([3,18],'The loading gates change sides. Read the patrol before crossing.'),([19,14],'Two boards share the pier. Wait below the water edge until a gap opens.'),([17,7],'The gate is west, then east. Watch the last patrol.')])
    elif i==4:
        gate(d,18,[5,6]);gate(d,14,[5,6]);gate(d,4,[11,12]);gate(d,2,[18,19])
        obj(d,'set4-mailbox-7')['pos']=[4,3]
        obj(d,'set4-traffic_cone-10')['pos']=[3,19]
        obj(d,'set4-traffic_cone-11')['pos']=[21,19]
        obj(d,'set4-manhole-12')['pos']=[12,19]
        roach(d,'set4-roach-5',[[17,11],[19,11]],1.85)
        roach(d,'hard4-west-gate',[[5.5,11],[8,11]],2.0)
        roach(d,'hard4-north',[[10,5],[13,5]],2.1)
        d['traffic'][0].update(speed=4.2,spacing=8.6,offset=1.4)
        d['traffic'][1].update(speed=3.8,spacing=10.2,offset=5.2)
        d['hint']='Read both lanes from the curb. At the bank, choose a gate and watch for the returning rider.'
        d['description']='A fixed crossing feeds a choice of two bank gates. Both are patrolled, and the rider loops behind the landing. A second north-side change of line prevents a straight sprint to the exit.'
        signs(d,[([6,19],'Wait at the curb for a gap through both lanes.'),([6,13],'Choose a bank gate. A roach guards each landing; the board returns behind them.')])
    elif i==5:
        gate(d,18,[6]);gate(d,12,[18]);gate(d,6,[7,8]);gate(d,3,[12,13])
        roach(d,'set5-roach-15',[[5,19],[7,19]],1.85)
        roach(d,'set5-roach-16',[[16,13],[19,13]],2.0)
        roach(d,'set5-roach-17',[[17,11],[19,11]],1.7)
        roach(d,'set5-roach-18',[[6,5],[9,5]],2.0)
        roach(d,'hard5-exit',[[11,4],[14,4]],1.9)
        obj(d,'set5-bench-10')['pos']=[15,4]
        # A counterflow board uses the court, while the original rail ride remains.
        skater(d,'hard5-court-return',[[5,8],[17,8],[17,10],[5,10]],3.8,0)
        d['hint']='Each court changes the next alley. Watch the narrow gates and both riders in the grind court.'
        d['description']='Three offset refuse gates now require deliberate patrol crossings. A second board cuts across the rail court, followed by a final guarded opening. Court interiors remain safe places to inspect the next crossing.'
        signs(d,[([12,23],'Read each refuse alley before crossing. The next gate changes sides.'),([18,14],'Do not stop in the narrow opening. The next landing is guarded too.'),([18,11],'Two boards cross the grind court. Choose when to enter, then keep moving.')])
    elif i==6:
        gate(d,22,[17,18]);gate(d,17,[12,13,14]);gate(d,13,[4,6,7,8,9,10,17,18,19,20]);gate(d,10,[4,5,6,7,8,9,18,19,20]);gate(d,3,[6,7])
        obj(d,'set6-traffic_cone-18')['pos']=[10,21]
        obj(d,'set6-traffic_cone-19')['pos']=[20,21]
        obj(d,'set6-bench-16')['pos']=[15,2]
        obj(d,'set6-mailbox-17')['pos']=[8,2]
        # Keep the supported rail, but bring its ground return across the south entry.
        rider=obj(d,'set6-skater-10')
        for n in rider['route']:
            if n['pos']==[17,17]:n['pos']=[17,16]
            elif n['pos']==[12,17]:n['pos']=[12,16]
        for key,speed in [('set6-skater-3',3.6),('set6-skater-6',3.5),('set6-skater-10',4.0)]:
            obj(d,key)['speed']=speed
            obj(d,key).pop('hard_pass',None)
        roach(d,'set6-roach-22',[[19,8],[21,8]],1.9)
        roach(d,'set6-roach-23',[[17,14],[19,14]],1.8)
        roach(d,'set6-roach-24',[[5,4],[8,4]],2.0)
        for lane in d['traffic']:
            if lane['row']==20:lane.update(speed=4.4,spacing=9.0,offset=2.0)
            elif lane['row']==19:lane.update(speed=3.8,spacing=10.5,offset=6.0)
            elif lane['row']==6:lane.update(speed=4.8,spacing=8.8,offset=3.0)
            else:lane.update(speed=4.0,spacing=10.4,offset=1.0)
        d['hint']='Choose a way around the banks. Watch the three circuits, then line up the final traffic gap from the north landing.'
        d['description']='The block party combines a fixed traffic approach, a tight entry crossed by a returning board, and a choice around the central banks. The west rail and east riders meet again before the final avenue and guarded exit alley.'
        signs(d,[([17,23],'Line up with the crossing before entering both traffic lanes.'),([13,18],'A board returns across the entry. Choose a side of the banks before it comes back.'),([12,8],'Reach the north curb, watch both lanes, then cross in one move.')])
    file.write_text(json.dumps(d,indent=2)+'\n')
