"""Complete the user's Test1 opening; do not regenerate or replace that opening."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'level-source/cramerton/Test1.json'
SOURCE_SHA = 'ec86e69e8cac53f09ef602cf28ed212d9f111556282a99ec2036dae967e4b521'


def main():
    raw = SOURCE.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == SOURCE_SHA
    source = json.loads(raw)
    level = copy.deepcopy(source)
    level.pop('editor_autosave_id', None)  # Bundled derivative gets no user's save-slot identity.
    level.update(name='Cramerton', draw_distance=20, checkpoints=[[8, 16]], signs=[])
    level['tiles'] = [['wall'] * 33 for _ in range(49)]
    for y in range(35, 48):
        for x in range(1, 14):
            level['tiles'][y][x] = source['tiles'][y][x]

    def room(x1, y1, x2, y2, terrain='floor'):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                assert not (1 <= x <= 13 and 35 <= y <= 47), (x, y)
                level['tiles'][y][x] = terrain

    def obj(kind, x, y, **fields):
        assert not any(o['pos'] == [x, y] for o in level['objects']), (kind, x, y)
        item = dict(id=f'cramerton-{kind}-{len(level["objects"])}', type=kind,
                    pos=[x, y], rotation=0, solid=kind in ['tree', 'pillar', 'emitter'])
        item.update(fields)
        level['objects'].append(item)

    def fragments(points):
        for x, y in points:
            obj('hop_fragment', x, y)

    def sign(x, y, text):
        level['signs'].append(dict(pos=[x, y], text=text))

    # A single outlet makes the preserved opening a real first district.
    room(14, 37, 14, 37, 'path')
    # Customs Yard: fragment delivery crosses a north/south patrol road, then
    # spends the earned hop on a vertical canal. Safe corners permit observation.
    room(15, 35, 28, 43)
    room(24, 35, 24, 43, 'water')
    room(20, 36, 20, 42, 'road')
    obj('patrol_car', 20, 39, speed=0.8, length=1, direction=1,
        axis='north_south', waypoints=[], patrol_loop=True)
    fragments([(17, 37), (19, 40), (22, 40)])
    # Switcher Canal folds the route west instead of continuing straight north.
    room(26, 32, 28, 34)
    room(17, 26, 29, 33)
    room(17, 30, 29, 30, 'water')
    fragments([(27, 32), (24, 32), (21, 32)])
    obj('spike_ball', 23, 28, behavior='slam_patrol', pause=2.6,
        range=3, directions=[0, 90, 180, 270], waypoints=[[27, 28]], patrol_loop=True)
    room(16, 27, 16, 28, 'path')
    # Needle Arcade: the divider protects its western side from the frog and
    # enemies, but the west-facing shooter visibly fires through its cheese.
    room(5, 20, 15, 29)
    room(16, 20, 16, 28)
    room(10, 22, 10, 28, 'wall')
    room(10, 24, 10, 24, 'cheese_wall')
    room(10, 26, 10, 26, 'cheese_wall')
    obj('emitter', 14, 24, rotation=90, interval=3.5)
    fragments([(13, 27), (12, 25), (11, 22)])
    room(5, 19, 9, 19, 'water')
    # One late checkpoint precedes a plaza gate and the final traffic choice.
    room(3, 9, 20, 18)
    room(3, 13, 20, 13, 'wall')
    room(16, 13, 19, 13, 'water')
    room(8, 10, 14, 12, 'water')
    fragments([(8, 16), (12, 16), (16, 16)])
    obj('spike_ball', 17, 10, behavior='slam_patrol', pause=2.8,
        range=3, directions=[0, 90, 180, 270], waypoints=[[19, 10]], patrol_loop=True)
    # Governor's Walk: a dogleg street, a safe upper bank and a final square.
    room(17, 6, 19, 9)
    room(18, 7, 24, 8)
    room(22, 4, 24, 7)
    room(22, 3, 29, 5)
    room(27, 1, 29, 4)
    room(28, 1, 31, 2)
    room(19, 6, 24, 6, 'road')
    obj('car', 20, 6, speed=0.8, length=1, direction=1)
    fragments([(18, 11), (19, 9), (20, 7)])
    # Landmarks and furniture mark district corners, not random route clutter.
    for x, y in [(16, 42), (23, 42), (27, 36), (28, 27), (6, 28), (15, 21),
                 (4, 17), (19, 17), (4, 10), (28, 3)]:
        obj('tree', x, y)
    for x, y in [(18, 35), (28, 40), (6, 22), (23, 4)]:
        obj('pillar', x, y)
    for x, y in [(16, 35), (28, 43), (5, 21), (31, 2)]:
        obj('decoration', x, y)
    obj('landmark', 0, 16, landmark_kind='osiris', landmark_scale=0.6, solid=False)
    obj('landmark', 32, 27, landmark_kind='pyramid', landmark_scale=0.7, solid=False)
    sign(1, 46, 'CRAMERTON\nYour canal opening leads into the city. Three fragments earn one long hop.')
    sign(17, 36, 'CUSTOMS YARD\nCross the patrol road to finish a set of three. Save the hop for the canal.')
    sign(27, 33, 'SWITCHER CANAL\nGather on this bank. Cross the water, then turn west past the copper rail.')
    sign(15, 28, 'NEEDLE ARCADE\nThe shooter faces the cheese. Wait below its firing line, then cross.')
    sign(8, 16, 'CRAMERTON SQUARE\nOnly checkpoint. Your fragments and ready hop return with you on retry.')
    sign(20, 7, 'GOVERNOR\u2019S WALK\nSpend your last hop above the car, or wait on the bank for a clear crossing.')

    # Exact authorship contract: every original object and nonempty terrain
    # feature, all opening tiles, start, exit and rules survive unchanged.
    assert level['objects'][:len(source['objects'])] == source['objects']
    for y, row in enumerate(source['tiles']):
        for x, tile in enumerate(row):
            if tile != 'floor' or (1 <= x <= 13 and 35 <= y <= 47):
                assert level['tiles'][y][x] == tile, (x, y, tile)
    assert level['spawn'] == source['spawn'] and level['exit'] == source['exit']
    assert level['rules'] == source['rules'] and len(level['objects']) <= 180
    path = ROOT / 'game/levels/bonus/Cramerton.json'
    path.write_text(json.dumps(level, indent=2) + '\n')
    proof = dict(source_sha256=SOURCE_SHA, source_bytes=len(raw), source_library_file_id='libfile_ed562615b7b88191b86fd284456583e8',
                 original_objects_preserved=len(source['objects']), original_opening_tiles_preserved=13*13,
                 all_original_non_floor_tiles_preserved=True, original_spawn_exit_rules_preserved=True,
                 original_file_untouched=True, objects=len(level['objects']), checkpoints=level['checkpoints'],
                 districts=['Authored canal opening', 'Customs Yard', 'Switcher Canal', 'Needle Arcade', 'Cramerton Square', "Governor's Walk"],
                 derivative_removed_fields=['editor_autosave_id'],
                 rationale='Bundled map must not reuse the author\u2019s local editor autosave identity')
    (ROOT / 'level-source/cramerton/preservation.json').write_text(json.dumps(proof, indent=2) + '\n')
    print('Built Cramerton:', len(level['objects']), 'objects; preserved all 11 original objects and 169 opening tiles')


if __name__ == '__main__':
    main()
