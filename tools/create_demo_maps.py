"""Handcrafted demo layouts. Runtime and editor use exactly the same JSON schema."""
import json
from pathlib import Path

LEVELS = Path(__file__).resolve().parents[1] / "game" / "levels"


def make(name, theme, rows, objects):
    assert len(rows) == 13 and all(len(row) == 17 for row in rows)
    tiles = {"#": "wall", ".": "floor", "~": "water", "+": "path"}
    return dict(version=1, name=name, theme=theme, width=17, height=13,
                tiles=[[tiles[c] for c in row] for row in rows],
                spawn=[1, 11], exit=[15, 1], objects=objects)


def obj(id, kind, x, y, **props):
    return dict(id=id, type=kind, pos=[x, y], rotation=0,
                solid=kind in ["tree", "pillar", "emitter"], **props)


def critter(id, x, y, route=None, speed=1.5):
    return obj(id, "critter", x, y, behavior="patrol" if route else "wander",
               speed=speed, waypoints=route or [])


egypt = make("Pharaoh's Courtyard", "egypt", [
    "#################",
    "#.....#.........#",
    "#.###.#.###.###.#",
    "#...#...#...#...#",
    "###.#####.#.#.#.#",
    "#...#.....#...#.#",
    "#.#.#.###.###.#.#",
    "#.#...#...#...#.#",
    "#.#####.#.#.###.#",
    "#.......#.......#",
    "#.###.#####.###.#",
    "#+++++++++++++++#",
    "#################",
], [
    critter("scarab-1", 5, 9, speed=1.4),
    critter("scarab-2", 3, 5, speed=1.5),
    critter("scarab-3", 11, 5, speed=1.8),
    critter("scarab-4", 13, 9, speed=1.6),
    critter("snake-1", 9, 1, [[7, 1], [11, 1], [15, 1], [11, 1]], 1.7),
    critter("snake-2", 15, 5, [[15, 3], [15, 9]], 1.5),
    obj("trap-1", "emitter", 7, 9, interval=2.75),
    obj("column-1", "pillar", 5, 1),
    obj("column-2", "pillar", 9, 5),
    obj("urn-1", "decoration", 3, 1),
    obj("urn-2", "decoration", 11, 3),
])
egypt["objects"][6]["rotation"] = 90

swamp = make("Violet Mire", "swamp", [
    "#################",
    "#...~~~....+++++#",
    "#.#.~~~.###.###.#",
    "#.#.....#...#...#",
    "#.###.#.#.~.#.#.#",
    "#.....#...~...#.#",
    "#.~~~.###.~~~.#.#",
    "#..~~...#.....#.#",
    "##.####.#.###.#.#",
    "#.......#...#...#",
    "#.###.#####.###.#",
    "#+++++++++++++++#",
    "#################",
], [
    critter("mire-1", 5, 5, speed=1.2),
    critter("mire-2", 3, 9, speed=1.6),
    critter("mire-3", 11, 7, speed=1.5),
    critter("mire-4", 15, 7, speed=1.5),
    critter("mire-patrol", 7, 3, [[3, 3], [7, 3]], 1.4),
    critter("mire-patrol-2", 13, 1, [[10, 1], [15, 1]], 1.8),
    obj("tree-1", "tree", 1, 1),
    obj("tree-2", "tree", 5, 7),
    obj("tree-3", "tree", 11, 9),
    obj("glow-1", "mushroom", 2, 7),
    obj("glow-2", "mushroom", 9, 1),
    obj("glow-3", "mushroom", 13, 5),
    obj("glow-4", "mushroom", 1, 5),
])

# A third, reference-led courtyard: continuous grassy paths through canals,
# palms on small islands, and a centered foreground start for the 3D camera.
oasis_rows = [["#" if x in [0, 16] or y in [0, 12] else "~" for x in range(17)] for y in range(13)]


def carve(points):
    for a, b in zip(points, points[1:]):
        x, y = a
        dx = (b[0] > x) - (b[0] < x)
        dy = (b[1] > y) - (b[1] < y)
        assert dx == 0 or dy == 0
        oasis_rows[y][x] = "."
        while (x, y) != tuple(b):
            x, y = x + dx, y + dy
            oasis_rows[y][x] = "."


carve([(1, 1), (15, 1), (15, 11), (1, 11), (1, 1)])
carve([(8, 11), (8, 9), (5, 9), (5, 7), (3, 7), (3, 5), (6, 5), (6, 3), (8, 3), (8, 1)])
carve([(8, 9), (11, 9), (11, 7), (13, 7), (13, 5), (10, 5), (10, 3), (8, 3)])
carve([(1, 5), (3, 5)])
carve([(13, 5), (15, 5)])
carve([(5, 7), (11, 7)])
for x, y in [(3, 3), (13, 3), (7, 5), (9, 5)]:
    oasis_rows[y][x] = "."
oasis = make("Moonlit Oasis", "egypt", ["".join(row) for row in oasis_rows], [
    obj("oasis-palm-1", "tree", 3, 3),
    obj("oasis-palm-2", "tree", 13, 3),
    obj("oasis-palm-3", "tree", 7, 5),
    obj("oasis-palm-4", "tree", 9, 5),
    obj("oasis-pillar-1", "pillar", 7, 1),
    obj("oasis-pillar-2", "pillar", 9, 1),
    critter("oasis-scarab-1", 3, 5, speed=1.25),
    critter("oasis-scarab-2", 11, 7, speed=1.35),
    critter("oasis-patrol", 8, 3, [[6, 3], [10, 3]], 1.2),
    critter("oasis-scarab-3", 1, 8, speed=1.1),
])
oasis["spawn"] = [8, 11]
oasis["exit"] = [8, 1]

if __name__ == "__main__":
    LEVELS.mkdir(parents=True, exist_ok=True)
    for filename, level in [("pharaohs_courtyard", egypt), ("violet_mire", swamp), ("moonlit_oasis", oasis)]:
        (LEVELS / (filename + ".json")).write_text(json.dumps(level, indent=2) + "\n")
