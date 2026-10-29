#!/usr/bin/env python3
"""Rebuild the three authored City Journey levels; no random generation or old-map edits."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def blank(name, w, h, spawn, goal, movement):
    return dict(version=1, name=name, theme="nyc", width=w, height=h, spawn=spawn,
                exit=goal, tiles=[["wall"] * w for _ in range(h)], objects=[],
                traffic=[], crossings=[], checkpoints=[], signs=[], draw_distance=25,
                city_journey=dict(movement=movement, ice=[], bridges=[], ramps=[], rails=[], buildings=[], parks=[], islands=[]),
                park_encounters=[])


def rect(d, bounds, tile="path"):
    x0, y0, x1, y1 = bounds
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            d["tiles"][y][x] = tile


def prop(d, kind, pos, rotation=0, solid=True):
    d["objects"].append(dict(id=f"prop-{len(d['objects'])}", type="city_prop", variant=kind,
                             pos=pos, rotation=rotation, solid=solid))


def tree(d, pos):
    d["objects"].append(dict(id=f"tree-{len(d['objects'])}", type="tree", pos=pos, rotation=0))


def roach(d, name, points, speed):
    d["objects"].append(dict(id=name, type="roach", pos=points[0], rotation=0,
                             solid=False, behavior="patrol", patrol_loop=True,
                             speed=speed, waypoints=points))


def skater(d, name, points, speed, variant=0, height=0):
    d["objects"].append(dict(id=name, type="skater", pos=points[0], rotation=0,
                             solid=False, speed=speed, variant=variant,
                             route=[dict(pos=p, height=height, trick="push" if i % 3 == 0 else "cruise")
                                    for i, p in enumerate(points)]))


def lane(d, row, columns, direction, speed, spacing, offset, vehicles, jam=None):
    rect(d, [columns[0], row, columns[1], row], "road")
    record = dict(row=row, columns=columns, direction=direction, speed=speed,
                  spacing=spacing, offset=offset, vehicles=vehicles)
    if jam:
        record["jam"] = jam
    d["traffic"].append(record)


def sign(d, pos, text):
    d["signs"].append(dict(pos=pos, text=text))


def blocks_and_park():
    d = blank("City Journey 01 · Blocks, Bridge & Central Park", 49, 59, [6, 55], [41, 55], "walk")
    d["district"] = "CENTRAL PARK • EASTSIDE RETURN"
    d["description"] = "Cross the jammed west streets, climb the skaters' overpass, weave through Central Park, then slide across the rink and take the wider eastside home. Clear this journey to unlock Skate Escape."
    # A connected U-route around physical city blocks. Local streets cannot link
    # the start directly to the eastside return and skip the park.
    for bounds in [[3,44,11,56], [5,42,22,46], [20,31,22,43], [18,29,23,32],
                   [7,28,21,30], [6,16,12,30], [6,10,43,17], [38,16,44,56]]:
        rect(d, bounds)
    # Park lawns, ponds and their alternating necks create different approaches.
    rect(d, [5,5,43,17], "floor")
    rect(d, [7,11,41,14])
    rect(d, [14,5,19,10], "water")
    rect(d, [14,14,20,17], "water")
    rect(d, [24,5,29,9], "water")
    rect(d, [24,13,29,17], "water")
    rect(d, [33,5,36,10], "water")
    rect(d, [33,14,36,17], "water")
    # The ambush alley narrows before the park; west and east columns below the
    # park remain disconnected except through the north-south elevated bridge.
    rect(d, [6,19,9,22], "wall")
    rect(d, [12,19,12,22], "wall")
    # Wider southern return gives room to line up before two slower lanes.
    rect(d, [37,40,45,48])
    d["city_journey"]["bridges"] = [dict(rect=[20,31,22,43], axis="z", ramp_cells=3, height=2.0)]
    d["city_journey"]["ice"] = [dict(rect=[38,25,44,34])]
    d["city_journey"]["parks"] = [dict(rect=[5,5,43,17])]
    d["city_journey"]["buildings"] = [
        dict(rect=[2,32,16,40], height=4.8), dict(rect=[13,48,32,56], height=5.8),
        dict(rect=[25,31,35,39], height=6.4), dict(rect=[25,41,34,46], height=4.2),
        dict(rect=[15,19,34,25], height=5.4), dict(rect=[2,2,11,3], height=3.8),
        dict(rect=[37,2,46,3], height=4.0)]
    lane(d, 50, [3,11], 1, 5.3, 8.3, 1.2, ["taxi","bus","sedan"], dict(stopped=3.1,moving=3.9,phase=0.0))
    lane(d, 49, [3,11], -1, 5.0, 8.1, 4.5, ["truck","sedan"], dict(stopped=2.8,moving=4.2,phase=1.7))
    # Cars continue under the overpass. Both ramps end away from those rows.
    lane(d, 37, [18,24], 1, 5.0, 8.0, 0.0, ["bus","taxi"])
    lane(d, 36, [18,24], -1, 5.8, 8.7, 3.0, ["sedan","truck"])
    lane(d, 44, [37,45], 1, 3.0, 15.0, 0.0, ["taxi","sedan"])
    lane(d, 45, [37,45], -1, 3.1, 16.0, 7.0, ["sedan"])
    d["crossings"] = [6,8,21,40,42]
    # The outward roaches force a shift of lane between the truck crossing and
    # bridge. They move in dry sidewalks, never through traffic vehicle paths.
    roach(d, "loading-lane-roaches-a", [[5,45],[9,45],[9,43],[5,43]], 2.2)
    roach(d, "loading-lane-roaches-b", [[13,43],[17,43],[17,45],[13,45]], 2.8)
    roach(d, "alley-roaches-a", [[7,27],[11,27],[11,25],[7,25]], 2.1)
    roach(d, "alley-roaches-b", [[7,24],[10,24],[10,23],[7,23]], 2.7)
    for side,seed in [(-1,41),(1,127)]:
        x = 19.6 if side<0 else 22.4
        skater(d,f"overpass-rail-hopper-{side}",[[x,40.2],[21,40.2],[21,34],[x,34]],4.3 if side<0 else 4.8,1 if side<0 else 2,2.0)
        d["objects"][-1]["bridge_stunts"] = dict(bridge=0,seed=seed,side=side)
    skater(d, "park-west-skater", [[7,12],[12,12],[12,16],[7,16]], 4.0, 0)
    skater(d, "park-center-skater", [[20.8,10.5],[23,10.5],[23,15.5],[20.8,15.5]], 4.8, 2)
    skater(d, "park-east-skater", [[30,11],[32,11],[32,16],[30,16]], 4.3, 1)
    # Fixed attack directions cross the intended walk route. Wind-ups are supplied
    # by the encounter implementation; none are invisible random hit rolls.
    d["park_encounters"] = [
        dict(id="bush-ambusher",kind="ambusher",pos=[10,21],direction=[1,0]),
        dict(id="pigeon-keeper",kind="pigeons",pos=[22,15],direction=[0,-1],phase=0.8),
        dict(id="purse-swinger",kind="purse",pos=[31,13],direction=[1,0],phase=0.3),
        dict(id="rink-duet",kind="ice_duet",pos=[41,29.5],radius=3.5,phase=0.5)]
    for p in [[6,7],[9,7],[11,9],[6,16],[13,16],[21,6],[22,8],[30,6],[31,8],[38,7],[41,6],[42,10],[37,16]]:
        tree(d,p)
    for p,r in [([6,10],90),([22,17],0),([42,13],90),([44,22],0),([38,36],90)]:
        prop(d,"bench",p,r)
    for p in [[3,53],[11,52],[22,46],[18,30],[7,29],[43,38],[44,51]]:
        prop(d,"trash_can",p)
    prop(d,"newsstand",[10,55],90)
    prop(d,"dumpster",[16,46],0)
    prop(d,"pizza_cart",[40,18],0)
    prop(d,"mailbox",[44,54],0)
    d["checkpoints"] = [[19,44],[19,30],[11,17],[38,18],[41,36]]
    sign(d,[6,55],"WESTSIDE → Go north through the jam. Read the red/green signals; stopped traffic leaves gaps, not a protected crossing.")
    sign(d,[8,46],"DELIVERY BLOCK → Turn right toward the overpass. Roaches patrol both sidewalk lanes.")
    sign(d,[19,44],"OVERPASS ↑ Climb the ramp. Cars stay below; rail hoppers jump onto your deck.")
    sign(d,[19,30],"PARK ENTRANCE ← Turn left, then north. Watch the quick bush lunge.")
    sign(d,[11,17],"CENTRAL PARK → Use the pond openings. Watch a swing or flock finish before crossing its path.")
    sign(d,[38,18],"EASTSIDE RETURN ↓ Wider sidewalks ahead. The camera looks into your travel direction.")
    sign(d,[41,24],"ICE RINK ↓ Momentum carries you. Release early or hold Shift to brake; give the skating duet room.")
    sign(d,[41,36],"HOME STRETCH ↓ Two slower streets. Reach the south gate to unlock Skate Escape.")
    d["journey_route"] = [[6,55],[6,52],[8,47],[19,44],[21,43],[21,31],[19,30],[10,29],
                          [11,23],[11,17],[12,12],[21,12],[23,11],[30,11],[32,12],[38,12],
                          [41,18],[41,24],[43,34],[41,36],[41,42],[41,48],[41,55]]
    return d


def frozen_blocks():
    d = blank("City Journey 02 · Frozen Blocks",49,61,[24,57],[24,3],"walk")
    d["description"] = "Four sealed ice gauntlets. Cross dense opposing skater lines and overlapping square circuits; roaches occupy braking and exit approaches."
    d["district"] = "FROZEN BLOCKS • CROSS THE CIRCUITS"
    rect(d,[1,1,47,59],"water")
    rect(d,[22,2,26,58],"floor")
    d["city_journey"]["ice"] = [dict(rect=[1,1,47,59])]
    for room,y in enumerate([41,30,19,8]):
        rect(d,[18,y,30,y+7],"floor")
        # Two interlocking square circuits cross the entire usable room.
        # The perimeter is water: there is no bank or outside promenade.
        for band,yy in enumerate([y+1,y+4]):
            loop=[[18,yy],[30,yy],[30,yy+2],[18,yy+2]]
            for rider in range(4):
                points=loop[rider:]+loop[:rider]
                if band: points=list(reversed(points))
                skater(d,f"ice-line-{room}-{band}-{rider}",points,4.8+((room+band+rider)%3)*.3,rider%3)
                d["objects"][-1]["ice_skater"]=True
        roach(d,f"edge-bug-{room}",[[19,y+3],[21,y+3],[21,y+4],[19,y+4]],2.6+room*.15)
        roach(d,f"exit-bug-{room}",[[23,y-1],[25,y-1],[25,y],[23,y]],2.6+room*.2)
    # Approach bugs punish parking on the obvious central launch line.
    for i,y in enumerate([50,39,28,17]):
        roach(d,f"approach-bug-{i}",[[22,y],[26,y],[26,y+1],[22,y+1]],2.8+(i%2)*.3)
    d["checkpoints"]=[[24,38],[24,16]]
    sign(d,[24,57],"FROZEN TRAFFIC: Four sealed circuits. Brake before each crossing. Both directions matter; the outside edges are water.")
    sign(d,[24,49],"FIRST CIRCUIT: Skaters loop in squares. Cross one line, settle your slide, then read the next. Roaches can steal your waiting space.")
    sign(d,[24,38],"CHECKPOINT: Two circuits ahead. Opposing squares overlap; rushing through both at once is dangerous.")
    sign(d,[24,16],"FINAL CIRCUIT: Watch the exit bugs as well as the skaters. No outside route around the traffic.")
    d["journey_route"]=[[24,57],[24,3]]
    d["difficulty_gates"]=[dict(row=y+1,left=18,right=30) for y in [41,30,19,8]]
    return d


def skate_escape():
    d = blank("City Journey 03 · Skate Escape",61,61,[10,56],[53,5],"skate")
    d["district"] = "SKATE ESCAPE • HIGHWAY RAIL RUN"
    d["description"] = "Three larger courts, cars and roach patrols. Hold G near a rail to latch; grind above four highway lanes or time the crossing below. Ramps launch over three walls."
    for r in [[3,46,22,58],[3,33,24,43],[20,33,40,36],[27,19,44,36],[27,13,43,23],[46,13,57,24],[46,3,57,8]]: rect(d,r,"floor")
    # The three complete barriers require actual ramp clearance.
    for r in [[9,47,11,57],[9,42,11,43],[39,17,43,19],[46,17,49,19],[52,12,54,22],[52,3,54,8]]: rect(d,r)
    d["city_journey"]["ramps"] = [
        {"from":[10,49],"to":[10,47],"rise":.8,"landing":[10,43]},
        {"from":[40,18],"to":[42,18],"rise":.8,"landing":[46,18]},
        {"from":[53,14],"to":[53,12],"rise":.8,"landing":[53,8]}]
    d["city_journey"]["rails"] = [
        {"from":[6,42],"to":[6,34],"height":.75},
        {"from":[34,32],"to":[34,24],"height":2.6,"entry":[34,36],"exit":[34,20]},
        {"from":[38,32],"to":[38,24],"height":2.6,"entry":[38,36],"exit":[38,20]},
        {"from":[49,22],"to":[49,15],"height":.75}]
    for row,direction,speed,spacing,offset in [(39,1,5.5,13.0,1.5),(38,-1,5.0,14.0,8.0)]:
        lane(d,row,[3,24],direction,speed,spacing,offset,["sedan","taxi","bus"],dict(stopped=2.0,moving=3.8,phase=1.0 if row==38 else 0))
    for row,direction,speed,offset in [(30,1,7.0,2.0),(29,-1,7.6,6.0),(27,1,6.7,9.0),(26,-1,7.8,3.0)]:
        lane(d,row,[27,44],direction,speed,14.5,offset,["bus","truck","sedan","taxi"])
    d["crossings"] = [10,16,34,38,41]
    rect(d,[17,49,20,53],"water")
    rect(d,[16,41,20,43],"water")
    rect(d,[28,15,32,18],"water")
    skater(d,"start-court-rider",[[5,52],[15,52],[15,55],[5,55]],4.5,0)
    skater(d,"jam-court-rider",[[12,34],[21,34],[21,36],[12,36]],5.0,1)
    skater(d,"highway-entry-rider",[[29,33],[32,33],[32,36],[29,36]],4.7,2)
    skater(d,"north-ramp-rider",[[35,15],[41,15],[41,21],[35,21]],4.4,0)
    skater(d,"east-court-rider",[[47,16],[51,16],[51,21],[47,21]],5.1,1)
    skater(d,"exit-rider",[[48,4],[56,4],[56,7],[48,7]],4.8,2)
    for i,points in enumerate([[[12,47],[15,47],[15,50],[12,50]],[[5,34],[10,34],[10,36],[5,36]],
        [[22,34],[26,34],[26,36],[22,36]],[[41,31],[43,31],[43,33],[41,33]],
        [[29,20],[32,20],[32,22],[29,22]],[[48,22],[55,22],[55,24],[48,24]]]):
        roach(d,f"skate-roaches-{i}",points,2.4+(i%3)*.3)
    for p,r in [([4,48],90),([21,55],0),([23,41],90),([28,23],0),([57,15],90),([47,8],90)]: prop(d,"bench",p,r)
    for p in [[4,57],[16,46],[23,33],[27,34],[43,22],[47,14],[56,8]]: prop(d,"traffic_cone",p)
    prop(d,"dumpster",[21,47]); prop(d,"newsstand",[3,41],90); prop(d,"pizza_cart",[4,54],90)
    d["checkpoints"] = [[10,43],[23,35],[34,21],[48,18],[53,8]]
    for p,text in [([10,56],"RIDE NORTH: Steer with WASD / arrows. Space jumps; press left or right in air for tricks. Shift brakes. Hold G / Grind near a rail to latch."),
        ([10,43],"JAM COURT: Cross the stopped traffic gaps. Roaches and riders occupy the sidewalk; the long left rail is optional."),
        ([23,35],"HIGHWAY RAILS: Blue entry ramps climb above traffic. Hold G at the gold rail to latch. Space jumps off, Shift releases. Ground crossings stay dangerous."),
        ([34,21],"NORTH COURT: Brake and turn east. Build speed up the gold ramp past the pond."),
        ([48,18],"EAST COURT: Reposition north for the last ramp. The side rail and roaches change your line."),
        ([53,8],"EXIT COURT: One last fast rider circuit before the north gate.")]: sign(d,p,text)
    d["journey_route"] = [[10,56],[10,43],[10,40.5],[10,36],[23,35],[34,36],[34,32],[34,24],[34,20],[39,21],[40,18],[46,18],[53,18],[53,8],[53,5]]
    return d


def write():
    maps = [("city_journey_01_blocks_park.json",blocks_and_park()),
            ("city_journey_02_skate_escape.json",skate_escape()),
            ("city_journey_03_frozen_blocks.json",frozen_blocks())]
    for filename,d in maps:
        target = ROOT / "game" / "levels" / filename
        target.write_text(json.dumps(d,indent=2)+"\n")
        open_cells = sum(t not in ("wall","water") for row in d["tiles"] for t in row)
        print(f"{filename}: {d['width']}×{d['height']}, {open_cells} open cells, {len(d['objects'])} objects")

if __name__ == "__main__":
    write()
