#!/usr/bin/env python3
"""Author the 18-tile-diameter Brooklyn skate circle and audit its geometry.

This content command rewrites only nyc_06_brooklyn_skate_circle.json. The
25-cell canvas includes water margin and north/south pedestrian staging pads;
all rider routes remain inside the radius-nine skating area.
"""
from collections import deque
import json
import math
from pathlib import Path

DESTINATION = Path(__file__).resolve().parents[1] / "game/levels/nyc_06_brooklyn_skate_circle.json"
CELL = 1.8
CENTER = (12, 12)
RADIUS = 9
# Ground footprint X/Z in model coordinates. Ramps and rails use authored lengths.
PROP_SIZE = {
    "bench": (1.45, 0.65), "trash_can": (0.7, 0.7),
    "dumpster": (1.35, 1.15), "pizza_cart": (1.25, 1.1),
    "mailbox": (0.7, 0.7), "traffic_cone": (0.48, 0.48),
    "manhole": (0.85, 0.85), "newsstand": (1.4, 1.2),
    "skate_rail": (0.2, 4.0), "skate_ramp": (1.4, 4.0),
}


def node(x, y, height=0, trick="cruise"):
    return dict(pos=[round(x, 6), round(y, 6)], height=height, trick=trick)


def prop(level, kind, x, y, rotation=0, solid=True, **extra):
    level["objects"].append(dict(id=f"plaza-{kind}-{len(level['objects'])}",
                                 type="city_prop", variant=kind,
                                 pos=[round(x, 6), round(y, 6)], rotation=rotation,
                                 solid=solid, **extra))


def skater(level, variant, speed, route):
    level["objects"].append(dict(id=f"plaza-skater-{variant}", type="skater",
                                 pos=route[0]["pos"], variant=variant,
                                 rotation=0, solid=False, speed=speed, route=route))


def rail_with_banks(level, center, length, rotation):
    """A physical rail with short .605-rise entry/exit wedges, not a fake jump."""
    x, y = center
    # Local forward -Z: Godot positive Y rotation turns it toward negative X.
    radians = math.radians(rotation)
    direction = (-math.sin(radians), -math.cos(radians))
    half = length / CELL / 2
    approach = 1.0  # one grid cell, 1.8 world units
    entry = [x - direction[0] * half, y - direction[1] * half]
    exit_point = [x + direction[0] * half, y + direction[1] * half]
    low_entry = [entry[0] - direction[0] * approach, entry[1] - direction[1] * approach]
    low_exit = [exit_point[0] + direction[0] * approach, exit_point[1] + direction[1] * approach]
    prop(level, "skate_rail", x, y, rotation, length=length)
    prop(level, "skate_ramp", (low_entry[0] + entry[0]) / 2,
         (low_entry[1] + entry[1]) / 2, rotation, rise=0.605, length=CELL)
    prop(level, "skate_ramp", (low_exit[0] + exit_point[0]) / 2,
         (low_exit[1] + exit_point[1]) / 2, (rotation + 180) % 360,
         rise=0.605, length=CELL)
    return [node(*low_entry, trick="ramp"), node(*entry, 0.605, "grind"),
            node(*exit_point, 0.605, "ramp"), node(*low_exit)]


def make():
    tiles = []
    for y in range(25):
        row = []
        for x in range(25):
            radius = math.hypot(x - CENTER[0], y - CENTER[1])
            if x in (0, 24) or y in (0, 24):
                tile = "wall"
            elif radius <= RADIUS:
                tile = "path" if radius >= 7.8 else "floor"
            else:
                tile = "water"
            row.append(tile)
        tiles.append(row)
    # Wide, quiet staging pads flank the playable disk; no rider enters them.
    for y in (2, 3, 21, 22):
        for x in range(11, 14):
            tiles[y][x] = "path"
    level = dict(version=1, name="NYC 06 · Brooklyn Skate Circle", theme="nyc",
                 width=25, height=25, spawn=[12, 22], exit=[12, 2], tiles=tiles,
                 district="BROOKLYN SKATE CIRCLE", objects=[], traffic=[],
                 crossings=[], skate_area={"center": list(CENTER), "diameter": 18},
                 description="Three riders loop through an eighteen-tile skate plaza. Read the rails and ramps, avoid the roaches near the bins, and slip through the moving gaps.")

    # Perimeter rider: approach the rail on the east, grind north, then carve
    # the broad back arc. The first ground node gives a readable first crossing.
    east_rail = rail_with_banks(level, (18, 12), 4.0, 0)
    skater(level, 0, 3.4, [node(12, 19, trick="push"), node(16.5, 17)] + east_rail +
           [node(16.5, 7, trick="push"), node(12, 5), node(7.5, 7),
            node(5.5, 12, trick="push"), node(7.5, 17)])

    # Central bank rider: two full-size wedges meet at a .70-high apex.
    # Rising eastward is a 270-degree model rotation; descending east is 90.
    half_bank = 4.0 / CELL
    prop(level, "skate_ramp", 12 - half_bank / 2, 12, 270, rise=0.7, length=4.0)
    prop(level, "skate_ramp", 12 + half_bank / 2, 12, 90, rise=0.7, length=4.0)
    skater(level, 1, 3.0, [node(6, 12, trick="push"),
           node(12 - half_bank, 12, trick="ramp"), node(12, 12, 0.7, "ramp"),
           node(12 + half_bank, 12), node(17, 12, trick="push"),
           node(17, 15), node(15, 16), node(12, 16, trick="push"),
           node(9, 16), node(7, 15)])

    # Inner counter-flow rider climbs a shorter crosswise rail, then returns
    # south through the line used by the player after the central banks.
    cross_rail = rail_with_banks(level, (10.5, 8), 3.6, 270)
    skater(level, 2, 3.7, [node(7, 9, trick="push")] + cross_rail +
           [node(16, 9), node(17, 13, trick="push"), node(14, 15),
            node(10, 15), node(8, 13, trick="push")])

    # Street-life gallery occupies useful rest pockets, rather than the track.
    prop(level, "bench", 6, 8, rotation=90)
    prop(level, "trash_can", 8, 18)
    prop(level, "dumpster", 5, 15)
    prop(level, "pizza_cart", 17, 18)
    prop(level, "mailbox", 9, 5)
    prop(level, "traffic_cone", 15, 5)
    prop(level, "manhole", 14, 10, solid=False)
    prop(level, "newsstand", 18, 17, rotation=270)
    # Roaches use slow, local circuits near the refuse pocket. They do not
    # spawn on the frog or create invisible long-range pursuit.
    for index, (position, waypoints, speed) in enumerate([
        ([5, 14], [[5, 14], [6, 14], [6, 16], [5, 16]], 1.15),
        ([7, 18], [[7, 18], [9, 18], [9, 19]], 1.35),
        ([16, 18], [[16, 18], [16, 19], [18, 18]], 1.1),
        ([8, 6], [[8, 6], [10, 6], [10, 7]], 1.25),
    ]):
        level["objects"].append(dict(id=f"plaza-roach-{index}", type="roach",
                                     pos=position, rotation=0, solid=False,
                                     behavior="patrol", speed=speed,
                                     waypoints=waypoints))
    return level


def footprint(obj):
    width, length = PROP_SIZE[obj["variant"]]
    length = obj.get("length", length)
    rotation = round(obj.get("rotation", 0)) % 180
    return (length, width) if rotation == 90 else (width, length)


def segment_rect_clear(a, b, center, half):
    """Liang-Barsky segment/AABB test; False means the footprint is touched."""
    lower, upper = 0.0, 1.0
    for axis in range(2):
        origin, delta = a[axis] - center[axis], b[axis] - a[axis]
        if abs(delta) < 1e-9:
            if abs(origin) > half[axis]:
                return True
        else:
            first = (-half[axis] - origin) / delta
            last = (half[axis] - origin) / delta
            lower, upper = max(lower, min(first, last)), min(upper, max(first, last))
            if lower > upper:
                return True
    return False


def route(level):
    start, goal = tuple(level["spawn"]), tuple(level["exit"])
    solids = [obj for obj in level["objects"] if obj.get("solid", False)]
    previous, pending = {start: None}, deque([start])
    while pending:
        p = pending.popleft()
        if p == goal:
            result = []
            while p != start:
                result.append(p)
                p = previous[p]
            return list(reversed(result))
        for q in ((p[0]-1, p[1]), (p[0]+1, p[1]), (p[0], p[1]-1), (p[0], p[1]+1)):
            if q in previous or not (0 <= q[0] < 25 and 0 <= q[1] < 25):
                continue
            if level["tiles"][q[1]][q[0]] not in ("floor", "path"):
                continue
            blocked = False
            for obj in solids:
                w, length = footprint(obj)
                half = ((w / 2 + 0.34) / CELL, (length / 2 + 0.34) / CELL)
                if not segment_rect_clear(p, q, obj["pos"], half):
                    blocked = True
                    break
            if not blocked:
                previous[q] = p
                pending.append(q)
    return []


def audit(level):
    assert level["skate_area"] == {"center": [12, 12], "diameter": 18}
    assert level["width"] == level["height"] == 25
    assert len(level["tiles"]) == 25 and all(len(row) == 25 for row in level["tiles"])
    assert len({obj["id"] for obj in level["objects"]}) == len(level["objects"])
    riders = [obj for obj in level["objects"] if obj["type"] == "skater"]
    assert len(riders) == 3 and {obj["variant"] for obj in riders} == {0, 1, 2}
    assert len([obj for obj in level["objects"] if obj["type"] == "roach"]) == 4
    assert set(PROP_SIZE) <= {obj.get("variant") for obj in level["objects"] if obj["type"] == "city_prop"}
    all_tricks = set()
    for obj in level["objects"]:
        x, y = obj["pos"]
        assert level["tiles"][int(y)][int(x)] not in ("water", "wall")
        if obj["type"] != "skater":
            continue
        assert obj["pos"] == obj["route"][0]["pos"]
        assert 2 <= obj["speed"] <= 5.5 and len(obj["route"]) >= 4
        for index, a in enumerate(obj["route"]):
            b = obj["route"][(index + 1) % len(obj["route"])]
            all_tricks.add(a["trick"])
            assert math.dist(a["pos"], b["pos"]) > 0.1
            assert 0 <= a["height"] <= 1.2
            assert math.dist(a["pos"], CENTER) <= RADIUS
            for sample in range(101):
                t = sample / 100
                p = [a["pos"][axis] + (b["pos"][axis] - a["pos"][axis]) * t for axis in range(2)]
                assert math.dist(p, CENTER) <= RADIUS + 1e-6
                # A continuous route needs dry support, not only valid endpoints.
                assert level["tiles"][round(p[1])][round(p[0])] not in ("water", "wall")
    assert all_tricks == {"cruise", "push", "grind", "ramp"}
    planned = route(level)
    assert planned, "Frog needs a continuous, clearance-audited route through the plaza"
    # Every skater segment must avoid the fixed street furniture. Skate features
    # are allowed: they are the deliberately authored physical supports.
    furniture = [obj for obj in level["objects"] if obj["type"] == "city_prop" and obj["variant"] not in ("skate_rail", "skate_ramp", "manhole")]
    for rider in riders:
        for index, a in enumerate(rider["route"]):
            b = rider["route"][(index + 1) % len(rider["route"])]
            for prop_obj in furniture:
                width, length = footprint(prop_obj)
                half = ((width / 2 + 0.42) / CELL, (length / 2 + 0.42) / CELL)
                assert segment_rect_clear(a["pos"], b["pos"], prop_obj["pos"], half), f"Skater route clips {prop_obj['id']}"
    return planned


def main():
    level = make()
    path = audit(level)
    DESTINATION.write_text(json.dumps(level, ensure_ascii=False, indent=2) + "\n")
    print(f"PASS {level['name']}: 18-tile diameter, 3 riders, 4 roaches, "
          f"10 prop variants, {len(path)} clearance-audited route steps")
    print("Frog route:", path)


if __name__ == "__main__":
    main()
