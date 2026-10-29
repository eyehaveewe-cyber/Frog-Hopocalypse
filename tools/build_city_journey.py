#!/usr/bin/env python3
"""Rebuild the two authored City Journey levels; no random generation or old-map edits."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def blank(name, w, h, spawn, goal, movement):
    return dict(version=1, name=name, theme="nyc", width=w, height=h, spawn=spawn,
                exit=goal, tiles=[["wall"] * w for _ in range(h)], objects=[],
                traffic=[], crossings=[], checkpoints=[], signs=[], draw_distance=25,
                city_journey=dict(movement=movement, ice=[], bridges=[], ramps=[], rails=[], buildings=[], parks=[]),
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
    skater(d, "overpass-skater", [[20.7,34],[21.3,34],[21.3,40],[20.7,40]], 4.3, 1, 2.0)
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
    sign(d,[19,44],"OVERPASS ↑ Climb the ramp. Cars stay below; the skateboarder shares your deck.")
    sign(d,[19,30],"PARK ENTRANCE ← Turn left, then north. The rustling bush warns before a lunge.")
    sign(d,[11,17],"CENTRAL PARK → Use the pond openings. Watch a swing or flock finish before crossing its path.")
    sign(d,[38,18],"EASTSIDE RETURN ↓ Wider sidewalks ahead. The camera looks into your travel direction.")
    sign(d,[41,24],"ICE RINK ↓ Momentum carries you. Release early or hold Shift to brake; give the skating duet room.")
    sign(d,[41,36],"HOME STRETCH ↓ Two slower streets. Reach the south gate to unlock Skate Escape.")
    d["journey_route"] = [[6,55],[6,52],[8,47],[19,44],[21,43],[21,31],[19,30],[10,29],
                          [11,23],[11,17],[12,12],[21,12],[23,11],[30,11],[32,12],[38,12],
                          [41,18],[41,24],[43,34],[41,36],[41,42],[41,48],[41,55]]
    return d


def skate_escape():
    d = blank("City Journey 02 · Skate Escape",37,43,[9,38],[30,4],"skate")
    d["district"] = "SKATE ESCAPE • RIDE TO THE NORTH GATE"
    d["description"] = "Keep speed through three ramps to clear walls, use the rail lines, and read the other skaters before entering each court. Arrows/WASD steer, Space ollies, Shift brakes."
    for bounds in [[3,32,15,40],[3,22,16,30],[15,22,26,26],[28,16,33,27],
                   [26,11,33,17],[26,3,33,9]]:
        rect(d,bounds,"floor")
    # Each jump crosses a complete barrier; walking around the ramp does not
    # remove the wall. Water and perimeter walls close off off-route shortcuts.
    for bounds in [[8,33,10,39],[8,23,10,30],[15,23,26,25],[29,12,31,26],[29,3,31,9]]:
        rect(d,bounds)
    d["city_journey"]["ramps"] = [
        dict(from_=[9,35],to=[9,33],rise=.8,landing=[9,29]),
        dict(from_=[23,24],to=[25,24],rise=.8,landing=[29,24]),
        dict(from_=[30,14],to=[30,12],rise=.8,landing=[30,8])]
    for ramp in d["city_journey"]["ramps"]:
        ramp["from"] = ramp.pop("from_")
    d["city_journey"]["rails"] = [
        {"from":[5,28],"to":[5,24],"height":.65},
        {"from":[29,21],"to":[29,16],"height":.65}]
    # A pond separates the alternate practice line from the first ramp run-up.
    rect(d,[12,34,14,37],"water")
    # Routes cross the approaches but never place a rider on a landing center.
    skater(d,"practice-rider",[[4,37],[7,37],[7,39],[4,39]],3.2,0)
    skater(d,"first-court-rider",[[6,25],[13,25],[13,28],[6,28]],4.7,1)
    skater(d,"rail-court-rider",[[28.3,18],[32.3,18],[32.3,21],[28.3,21]],4.5,2)
    skater(d,"last-court-rider",[[27,5],[32,5],[32,8],[27,8]],4.0,0)
    roach(d,"skate-service-roach",[[12,23],[15,23],[15,25],[12,25]],2.0)
    for p,r in [([4,33],90),([14,29],0),([33,25],90),([33,4],0)]:
        prop(d,"bench",p,r)
    for p in [[4,40],[15,32],[16,22],[33,15],[26,4]]:
        prop(d,"traffic_cone",p)
    prop(d,"trash_can",[3,23])
    prop(d,"pizza_cart",[3,39])
    d["city_journey"]["buildings"] = [dict(rect=[18,31,33,39],height=4.5),dict(rect=[3,3,22,18],height=5.5)]
    d["checkpoints"] = [[9,29],[30,25],[30,8]]
    sign(d,[9,38],"RIDE NORTH: Arrows / WASD steer. Shift brakes. Space ollies. Build speed up the gold ramp to clear the wall.")
    sign(d,[9,29],"FIRST COURT → The left rail offers a straight grind. Turn right toward the next ramp; watch the crossing rider.")
    sign(d,[21,24],"RAMP → Keep rolling east. Brake after landing, then turn north.")
    sign(d,[30,25],"RAIL LINE ↑ Approach a rail end along its length to grind. Space leaves the rail; Shift brakes.")
    sign(d,[30,15],"FINAL RAMP ↑ Keep your speed. Wait for a clear landing before committing.")
    sign(d,[30,8],"NORTH GATE ↑ One final skater loop. Clear it to finish the ride.")
    d["journey_route"] = [[9,38],[9,35],[9,33],[9,29],[9,24],[21,24],[23,24],[25,24],
                          [30,24],[30,17],[30,14],[30,12],[30,8],[30,4]]
    return d


def write():
    maps = [("city_journey_01_blocks_park.json",blocks_and_park()),
            ("city_journey_02_skate_escape.json",skate_escape())]
    for filename,d in maps:
        target = ROOT / "game" / "levels" / filename
        target.write_text(json.dumps(d,indent=2)+"\n")
        open_cells = sum(t not in ("wall","water") for row in d["tiles"] for t in row)
        print(f"{filename}: {d['width']}×{d['height']}, {open_cells} open cells, {len(d['objects'])} objects")

if __name__ == "__main__":
    write()
