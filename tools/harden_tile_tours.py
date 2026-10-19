"""Authored pressure pass. 60 hazards vs v25's 24 is a budget, not a human metric.
Each new dart shooter is aimed at actual cheese with a clear intervening beam.
"""
def room(d,x1,y1,x2,y2,t='floor'):
 for y in range(y1,y2+1):
  for x in range(x1,x2+1):d['tiles'][y][x]=t
def add(d,t,x,y,**kw):
 assert not any(o['pos']==[x,y] for o in d['objects']),('occupied',d['name'],x,y)
 d['objects'].append(dict(id=f'hard-{t}-{len(d["objects"])}',type=t,pos=[x,y],solid=t=='emitter',**kw))
def rail(d,x,y,tx,ty,pause=2):add(d,'spike_ball',x,y,behavior='slam_patrol',pause=pause,range=3,directions=[0,90,180,270],waypoints=[[tx,ty]],patrol_loop=True)
def bug(d,x,y,tx,ty):add(d,'critter',x,y,behavior='patrol',speed=1.2,waypoints=[[x,y],[tx,ty]],patrol_loop=True)
def dart(d,x,y,cx,cy,interval=2):
 assert x==cx or y==cy
 rotation=270 if cx>x else 90 if cx<x else 180 if cy>y else 0
 d['tiles'][cy][cx]='cheese_wall'
 add(d,'emitter',x,y,rotation=rotation,interval=3 if d['move_with_me'] and interval==2 else interval)
def move(d,old,new):
 for o in d['objects']:
  if o['pos']==list(old):o['pos']=list(new);return
 raise ValueError(old)
def harden(d,index):
 for o in d['objects']:
  if o['type']=='spike_ball':o['pause']=2
  if o['type']=='emitter':o['interval']=3 if d['move_with_me'] else 2
 if index==0:
  rail(d,12,33,5,33)
  room(d,2,32,14,32,'road');add(d,'car',12,32,speed=1,length=1.5,direction=-1)
  room(d,2,23,3,26,'wall');room(d,13,23,14,26,'wall');move(d,(13,23),(13,22))
  bug(d,4,27,4,23);bug(d,12,23,12,27)
  dart(d,2,21,7,21);dart(d,14,29,9,29)
  dart(d,13,17,9,17)
  rail(d,8,12,8,10)
  room(d,3,6,6,8,'water');room(d,10,6,13,8,'water');move(d,(12,7),(12,10))
  d['signs'][-1]['text']='One checkpoint. The next rail guards the center.\nDarts pass through cheese; align a landing beyond the firing line.'
 elif index==1:
  move(d,(1,37),(1,39));dart(d,1,37,5,37)
  dart(d,14,30,11,30)
  rail(d,17,22,17,26)
  dart(d,19,24,16,24)
  bug(d,4,20,9,20)
  dart(d,19,7,15,7)
  bug(d,18,9,18,5)
  for o in d['objects']:
   if o['type']=='spike_ball' and o.get('behavior')=='slam_patrol':o['pause']=1
  d['signs'][0]['text']='YOUR MOVE CROSSING · Every accepted hop advances danger.\nRead the dart lines and the locked copper target before stepping.'
 elif index==2:
  move(d,(4,29),(4,28))
  dart(d,3,29,9,29)
  bug(d,6,28,12,28)
  dart(d,3,18,9,18)
  rail(d,13,12,13,9)
  dart(d,15,10,11,10)
  d['signs'][2]['text']='Fragments now sit behind active crossings.\nSpend short hops on safe banks to change the road and dart phase.'
 elif index==3:
  # This was incorrectly facing north; the cheese lies east of the turret.
  for o in d['objects']:
   if o['type']=='emitter':o['rotation']=270
  rail(d,2,30,6,30)
  dart(d,1,29,5,29,3)
  room(d,18,24,18,29,'road');add(d,'patrol_car',18,25,speed=1,length=1,direction=1,axis='north_south',waypoints=[])
  dart(d,10,25,14,25)
  rail(d,13,21,17,21)
  dart(d,19,20,16,20,3)
  bug(d,6,17,9,17)
  dart(d,2,11,7,11)
  bug(d,19,8,19,3)
  d['signs'][0]['text']='Diamond seeds grant one hop. The first is on a firing line.\nWatch the rail, land on the seed, then save the hop for water.'
  d['signs'][-1]['text']='Only checkpoint. Keep the final seed for the eastern gate.\nShort-hop across the dart lane when its next beat is clear.'
 elif index==4:
  dart(d,4,33,2,33)
  dart(d,15,28,13,28)
  room(d,16,19,18,19);dart(d,18,19,16,19)
  dart(d,5,12,3,12)
  room(d,9,29,11,29);bug(d,10,30,13,30)
  room(d,4,15,7,15);bug(d,7,16,4,16)
  bug(d,10,5,12,5)
  d['signs'][1]['text']='The winding terrace recharges your reserve.\nYour first 25 short hops must also cross active dart and road beats.'
  d['signs'][-1]['text']='Last water gate: keep your reserve for it.\nOn the far bank, the rail and bug cover different landings.'
