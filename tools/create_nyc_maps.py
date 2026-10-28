#!/usr/bin/env python3
"""Rebuild five authored NYC maps and audit their spatial/traffic contracts.

No randomness and no modification of the original campaign maps. The layout
recipes below remain the editable source; JSON is the runtime/editor format.
"""
from collections import deque
import json
from pathlib import Path

LEVELS = Path(__file__).resolve().parents[1] / "game" / "levels"
LENGTHS = {"taxi": 2.6, "sedan": 2.6, "bus": 4.4, "truck": 3.5}
WALKABLE = {"floor", "path", "road"}
CITY_PROPS = {"bench", "trash_can", "dumpster", "pizza_cart", "mailbox",
              "traffic_cone", "manhole", "newsstand"}


def make(number, title, width, height, spawn, goal, description):
    return dict(version=1, name=f"NYC {number:02d} · {title}", theme="nyc",
                width=width, height=height, spawn=spawn, exit=goal,
                description=description, district=title.upper(),
                crossings=[3, width // 2, width - 4],
                tiles=[["wall" if x in (0, width-1) or y in (0, height-1)
                        else "floor" for x in range(width)] for y in range(height)],
                objects=[], traffic=[])


def rect(level, x0, y0, x1, y1, tile):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            level["tiles"][y][x] = tile


def horizontal(level, row, start, end, openings=()):
    for x in range(start, end + 1):
        if x not in openings:
            level["tiles"][row][x] = "wall"


def prop(level, kind, x, y, rotation=0, **extra):
    assert level["tiles"][y][x] not in ("road", "water", "wall")
    level["objects"].append(dict(id=f"nyc-{kind}-{x}-{y}", type=kind,
                                pos=[x, y], rotation=rotation,
                                solid=kind in ("tree", "pillar", "emitter"), **extra))


def city_prop(level, variant, x, y, rotation=0):
    """One-cell street furniture footprint; keep the chosen route and hazards clear."""
    assert variant in CITY_PROPS
    point = [x, y]
    assert level["tiles"][y][x] in ("floor", "path")
    assert point not in (level["spawn"], level["exit"])
    assert all(o["pos"] != point for o in level["objects"])
    assert (x, y) not in route(level)
    for obj in level["objects"]:
        if obj["type"] in ("critter", "roach"):
            assert point not in [obj["pos"]] + obj.get("waypoints", [])
    level["objects"].append(dict(id=f"nyc-{variant}-{x}-{y}", type="city_prop",
                                 variant=variant, pos=point, rotation=rotation,
                                 solid=variant not in ("traffic_cone", "manhole")))


def streetlife(level, furniture):
    # Retain the original patrol IDs, paths and speeds: this is a model/species
    # expansion rather than an unmeasured difficulty increase on existing maps.
    original_route = route(level)
    for obj in level["objects"]:
        if obj["type"] == "critter":
            obj["type"] = "roach"
    for entry in furniture:
        city_prop(level, *entry)
    assert route(level) == original_route, "Street dressing must preserve the chosen route"
    return level


def lane(level, row, direction, speed, spacing, offset, vehicles):
    rect(level, 1, row, level["width"] - 2, row, "road")
    level["traffic"].append(dict(row=row, direction=direction, speed=speed,
                                 spacing=spacing, offset=offset, vehicles=vehicles))


def route(level, roads=True):
    """Grid reachability, not physical/controller or moving-hazard proof."""
    start, goal = tuple(level["spawn"]), tuple(level["exit"])
    blocked = {tuple(o["pos"]) for o in level["objects"] if o["solid"]}
    previous, queue = {start: None}, deque([start])
    while queue:
        x, y = queue.popleft()
        if (x, y) == goal:
            path = []
            while (x, y) != start:
                path.append((x, y))
                x, y = previous[(x, y)]
            return list(reversed(path))
        for p in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
            nx, ny = p
            if not (0 <= nx < level["width"] and 0 <= ny < level["height"]):
                continue
            tile = level["tiles"][ny][nx]
            if p in previous or p in blocked or tile not in WALKABLE or (tile == "road" and not roads):
                continue
            previous[p] = (x, y)
            queue.append(p)
    return []


def audit(level):
    w, h = level["width"], level["height"]
    assert 5 <= w <= 25 and 5 <= h <= 25
    assert len(level["tiles"]) == h and all(len(r) == w for r in level["tiles"])
    assert all(t in WALKABLE | {"wall", "water"} for r in level["tiles"] for t in r)
    assert all(level["tiles"][y][x] == "wall" for y in (0, h-1) for x in range(w))
    assert all(level["tiles"][y][x] == "wall" for x in (0, w-1) for y in range(h))
    assert len({o["id"] for o in level["objects"]}) == len(level["objects"])
    assert len(level["objects"]) <= 180
    for point in (level["spawn"], level["exit"]):
        assert level["tiles"][point[1]][point[0]] in ("floor", "path")
    for o in level["objects"]:
        assert level["tiles"][o["pos"][1]][o["pos"][0]] in ("floor", "path")
        if o["type"] in ("critter", "roach"):
            assert all(level["tiles"][p[1]][p[0]] in ("floor", "path") for p in o["waypoints"])
        if o["type"] == "city_prop":
            assert o["variant"] in CITY_PROPS
            assert o["pos"] not in (level["spawn"], level["exit"])
            assert all(abs(o["pos"][1] - lane["row"]) >= 1 for lane in level["traffic"])
    rows = {l["row"] for l in level["traffic"]}
    assert len(rows) == len(level["traffic"])
    for l in level["traffic"]:
        assert 1 < l["row"] < h-2 and l["direction"] in (-1, 1)
        assert 2 <= l["speed"] <= 8 and 7 <= l["spacing"] <= 16
        assert 0 <= l["offset"] < l["spacing"]
        assert l["vehicles"] and set(l["vehicles"]) <= LENGTHS.keys()
        assert all(t == "road" for t in level["tiles"][l["row"]][1:-1])
        # The worst single-vehicle gap exceeds the frog's full lane envelope.
        assert (l["spacing"] - max(LENGTHS[k] for k in l["vehicles"]) - 0.64) / l["speed"] > (1.1+0.64)/4.2
        assert not ({l["row"]+1, l["row"]+2} <= rows), "No three-lane unbroken crossing"
    assert route(level), "Exit must be reachable through walkable terrain"
    assert not route(level, roads=False), "Required traffic must not have a dry bypass"
    for row in rows:
        assert not route_with_row_blocked(level, row), "Each lane must be crossed"


def route_with_row_blocked(level, row):
    original = level["tiles"][row]
    level["tiles"][row] = ["wall"] * level["width"]
    result = route(level)
    level["tiles"][row] = original
    return result


def park():
    d = make(1, "Central Park", 21, 17, [10, 15], [10, 1],
             "Wind around the park pond, watch the taxis, then cross one lane into the north gardens.")
    rect(d, 8, 10, 12, 13, "water")
    rect(d, 3, 3, 7, 5, "water")
    rect(d, 1, 7, 19, 7, "path")
    rect(d, 1, 9, 19, 9, "path")
    rect(d, 9, 1, 11, 6, "path")
    lane(d, 8, 1, 2.6, 13.5, 2.0, ["taxi", "sedan", "taxi"])
    for x, y in [(3, 12), (17, 12), (5, 2), (16, 3), (17, 5), (5, 15), (15, 15)]:
        prop(d, "tree", x, y)
    for x, y in [(7, 11), (13, 11), (4, 6), (16, 6)]:
        prop(d, "decoration", x, y)
    prop(d, "critter", 15, 3, behavior="patrol", speed=1.1, waypoints=[[14, 3], [14, 5]])
    return streetlife(d, [
        ("bench", 3, 14, 90), ("bench", 17, 14, 270),
        ("pizza_cart", 2, 2), ("trash_can", 2, 3),
        ("mailbox", 18, 2), ("manhole", 15, 7),
        ("traffic_cone", 2, 9)])


def brownstones():
    d = make(2, "Brownstone Blocks", 21, 19, [3, 17], [17, 1],
             "Choose an alley around the stoops, cross opposing taxi lanes, and zigzag through the north block.")
    for x in (5, 13):
        rect(d, x, 14, x+2, 16, "wall")
    horizontal(d, 8, 1, 19, openings=[3, 4])
    horizontal(d, 5, 1, 19, openings=[16, 17])
    rect(d, 1, 10, 19, 10, "path")
    rect(d, 1, 13, 19, 13, "path")
    lane(d, 12, 1, 3.1, 12.5, 0.0, ["taxi", "sedan"])
    lane(d, 11, -1, 3.0, 13.5, 5.0, ["sedan", "taxi", "truck"])
    for x, y in [(2, 15), (11, 15), (18, 15), (6, 6), (13, 3)]:
        prop(d, "pillar", x, y)
    for x, y in [(8, 15), (12, 15), (2, 9), (18, 6), (3, 3)]:
        prop(d, "decoration", x, y)
    prop(d, "critter", 9, 7, behavior="patrol", speed=1.25, waypoints=[[6, 7], [14, 7]])
    return streetlife(d, [
        ("dumpster", 18, 17, 90), ("trash_can", 17, 17),
        ("newsstand", 2, 2), ("bench", 10, 2),
        ("mailbox", 15, 3), ("traffic_cone", 19, 10),
        ("manhole", 10, 13)])


def waterfront():
    d = make(3, "East River Piers", 23, 21, [3, 19], [19, 1],
             "Cross the service road, choose either bank of the river basin, and thread the crosstown bus lanes.")
    rect(d, 7, 10, 15, 13, "water")
    rect(d, 9, 10, 13, 10, "path")
    rect(d, 9, 13, 13, 13, "path")
    rect(d, 7, 18, 15, 19, "water")
    horizontal(d, 4, 1, 21, openings=[17, 18])
    for row in (6, 9, 14, 17):
        rect(d, 1, row, 21, row, "path")
    lane(d, 16, 1, 3.3, 12.5, 1.5, ["truck", "taxi"])
    lane(d, 15, -1, 3.6, 13.5, 6.0, ["sedan", "taxi"])
    lane(d, 8, 1, 3.2, 14.0, 0.0, ["bus", "taxi", "sedan"])
    lane(d, 7, -1, 3.8, 13.5, 7.0, ["taxi", "truck"])
    for x, y in [(2, 11), (20, 11), (7, 3), (4, 18), (18, 18)]:
        prop(d, "pillar", x, y)
    for x, y in [(5, 12), (17, 12), (8, 11), (14, 12), (5, 3), (18, 3)]:
        # Basin objects must stay on dry ground.
        if d["tiles"][y][x] != "water":
            prop(d, "decoration", x, y)
    prop(d, "critter", 17, 11, behavior="patrol", speed=1.3, waypoints=[[17, 10], [17, 13]])
    return streetlife(d, [
        ("bench", 3, 12, 90), ("bench", 19, 12, 270),
        ("pizza_cart", 2, 2), ("trash_can", 3, 2),
        ("dumpster", 21, 18), ("traffic_cone", 2, 14),
        ("mailbox", 20, 2), ("manhole", 11, 6)])


def broadway():
    d = make(4, "Broadway After Dark", 25, 23, [12, 21], [12, 1],
             "Read three different traffic rhythms from wide theater plazas, choosing where to cross each avenue.")
    for row in (4, 7, 10, 13, 16, 19):
        rect(d, 1, row, 23, row, "path")
    horizontal(d, 15, 5, 19, openings=[7, 17])
    horizontal(d, 9, 3, 21, openings=[11, 12, 13])
    rect(d, 5, 20, 9, 20, "water")
    rect(d, 15, 20, 19, 20, "water")
    lane(d, 18, 1, 3.7, 12.0, 0.5, ["taxi", "sedan", "truck"])
    lane(d, 17, -1, 3.3, 13.0, 6.5, ["bus", "taxi"])
    lane(d, 12, 1, 4.0, 11.5, 4.0, ["taxi", "taxi", "sedan"])
    lane(d, 11, -1, 3.8, 13.0, 0.5, ["truck", "bus", "sedan"])
    lane(d, 6, 1, 4.4, 11.5, 2.0, ["sedan", "taxi"])
    lane(d, 5, -1, 3.6, 13.0, 8.0, ["bus", "taxi", "truck"])
    for x, y in [(3, 20), (21, 20), (3, 14), (21, 14), (4, 8), (20, 8), (4, 2), (20, 2)]:
        prop(d, "pillar", x, y)
    for x, y in [(8, 14), (16, 14), (7, 3), (17, 3), (6, 8), (18, 8)]:
        prop(d, "mushroom", x, y)
    return streetlife(d, [
        ("newsstand", 2, 2), ("pizza_cart", 22, 2),
        ("bench", 2, 21), ("trash_can", 3, 21),
        ("mailbox", 22, 21), ("dumpster", 2, 14),
        ("traffic_cone", 22, 14), ("manhole", 18, 19)])


def midtown():
    d = make(5, "Midtown Rush Hour", 25, 25, [12, 23], [12, 1],
             "Four avenues roar with taxis, buses and delivery trucks. Pause on each median, change crossing lines, and reach the skyline gate.")
    for row in (6, 9, 10, 13, 14, 17, 18, 21):
        rect(d, 1, row, 23, row, "path")
    # Paired flank openings then a central opening prevent one straight sprint
    # from solving all four avenues. Two-cell median depth leaves turning room.
    horizontal(d, 17, 1, 23, openings=[4, 5, 18, 19])
    horizontal(d, 13, 1, 23, openings=[11, 12, 13])
    horizontal(d, 9, 1, 23, openings=[4, 5, 19, 20])
    rect(d, 5, 3, 9, 4, "water")
    rect(d, 15, 3, 19, 4, "water")
    lane(d, 20, 1, 3.8, 10.0, 1.0, ["taxi", "taxi", "sedan", "truck"])
    lane(d, 19, -1, 3.2, 11.5, 6.0, ["bus", "taxi", "bus", "truck"])
    lane(d, 16, 1, 4.4, 9.5, 3.5, ["sedan", "taxi", "truck"])
    lane(d, 15, -1, 3.7, 11.0, 0.0, ["bus", "truck", "taxi"])
    lane(d, 12, 1, 4.8, 9.5, 6.0, ["taxi", "sedan", "taxi"])
    lane(d, 11, -1, 4.2, 10.5, 2.0, ["truck", "taxi", "bus"])
    lane(d, 8, 1, 5.3, 9.5, 0.5, ["taxi", "sedan", "truck", "taxi"])
    lane(d, 7, -1, 4.0, 11.0, 7.0, ["bus", "taxi", "truck", "sedan"])
    for x, y in [(3, 22), (21, 22), (3, 18), (21, 14), (3, 10), (3, 5), (21, 5)]:
        prop(d, "pillar", x, y)
    for x, y in [(6, 22), (18, 22), (4, 14), (20, 10), (10, 3), (14, 3)]:
        prop(d, "decoration", x, y)
    return streetlife(d, [
        ("newsstand", 2, 22), ("pizza_cart", 22, 22),
        ("trash_can", 22, 23), ("bench", 10, 22),
        ("bench", 16, 22), ("mailbox", 2, 5),
        ("traffic_cone", 22, 6), ("dumpster", 22, 2),
        ("manhole", 11, 21)])


MAPS = [("nyc_01_central_park", park), ("nyc_02_brownstone_blocks", brownstones),
        ("nyc_03_east_river_piers", waterfront), ("nyc_04_broadway", broadway),
        ("nyc_05_midtown_rush_hour", midtown)]


def main():
    for filename, factory in MAPS:
        level = factory()
        audit(level)
        destination = LEVELS / f"{filename}.json"
        destination.write_text(json.dumps(level, ensure_ascii=False, indent=2) + "\n")
        print(f"PASS {level['name']}: {level['width']}x{level['height']}, "
              f"{len(level['traffic'])} required lanes, {len(route(level))} route steps")


if __name__ == "__main__":
    main()
