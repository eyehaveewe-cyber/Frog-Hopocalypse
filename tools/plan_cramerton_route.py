"""Static resource-aware route witness; runtime physics replay is separate."""
from collections import deque
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
level = json.loads((ROOT / 'game/levels/bonus/Cramerton.json').read_text())
pickups = {tuple(o['pos']): i for i, o in enumerate(o for o in level['objects'] if o['type'] == 'hop_fragment')}
blocked = {tuple(o['pos']) for o in level['objects'] if o.get('solid', False) or o['type'] in ['tree', 'pillar', 'emitter'] or (o['type'] == 'spike_ball' and not o.get('waypoints'))}


def solve(start, goal):
    queue = deque([start])
    previous = {start: None}
    while queue:
        state = queue.popleft()
        x, y, count, reserve, bits = state
        if (x, y) == tuple(goal):
            steps = []
            while previous[state]:
                old, action = previous[state]
                steps.append(action)
                state = old
            return state, list(reversed(steps)), (x, y, count, reserve, bits)
        for dx, dy in [(0, -1), (1, 0), (0, 1), (-1, 0)]:
            for distance in [1, 2]:
                if distance == 2 and not reserve:
                    continue
                nx, ny = x + dx * distance, y + dy * distance
                if not (0 <= nx < 33 and 0 <= ny < 49) or (nx, ny) in blocked:
                    continue
                if level['tiles'][ny][nx] in ['wall', 'cheese_wall', 'water']:
                    continue
                if distance == 2 and level['tiles'][y + dy][x + dx] in ['wall', 'cheese_wall']:
                    continue
                if distance == 2 and level['tiles'][y + dy][x + dx] != 'water' and not (goal == [23,5] and level['tiles'][y + dy][x + dx] == 'road'):
                    continue  # The witness reserves hops for the authored crossing beats.
                c, ready, mask = count, reserve and distance != 2, bits
                index = pickups.get((nx, ny))
                if not ready and index is not None and not (mask & (1 << index)):
                    mask |= 1 << index
                    c += 1
                    if c == 3:
                        c, ready = 0, True
                new = (nx, ny, c, ready, mask)
                if new in previous:
                    continue
                previous[new] = (state, dict(direction=[dx, dy], big=distance == 2, wait=0))
                queue.append(new)
    raise RuntimeError(f'Unreachable goal {goal} from {start}')


goals = [[5,46],[5,44],[2,40],[7,44],[10,44],[12,42],[10,37],[13,38],[14,37],
         [17,37],[19,40],[22,40],[25,37],[27,32],[24,32],[21,32],[20,29],[17,27],
         [13,27],[12,25],[11,22],[6,20],[6,18],[8,16],[12,16],[16,16],[17,12],
         [18,11],[19,9],[20,7],[23,7],[23,5],[28,4],[28,1],[31,1]]
state = (*level['spawn'], 0, False, 0)
actions = []
for goal in goals:
    _, steps, state = solve(state, goal)
    actions.extend(steps)
# Safe-bank pauses verified against actual moving hazards, not disabled collisions.
for index, seconds in {37: 2.8, 50: 1.72, 99: 1.0}.items():
    actions[index]['wait'] = seconds
fixture = dict(level='res://levels/bonus/Cramerton.json', actions=actions,
               waypoints=goals, scope='Static legal cells and consumable fragment budget; hazards require real physics acceptance')
path = ROOT / 'game/tests/routes/cramerton.json'
path.write_text(json.dumps(fixture, indent=2) + '\n')
print('Static witness:', len(actions), 'hops,', sum(a['big'] for a in actions), 'long hops')
