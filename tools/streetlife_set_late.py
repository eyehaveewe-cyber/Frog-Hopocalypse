"""Authored late levels for NYC Streetlife: combine taught systems in new spaces."""
import math
from streetlife_set_common import (base, rect, prop, roach, node, skater,
                                  rail_with_banks, banks, lane, audit, save)


def divider(level, row, openings):
    """A whole-width wall whose readable gates impose a deliberate crossing."""
    for x in range(1, level['width'] - 1):
        if x not in openings:
            level['tiles'][row][x] = 'wall'


def assert_rider_wall_clearance(level):
    """Conservative sampled circle-vs-wall audit for the narrow gate revision.

    Distance to a closed rectangle is 1-Lipschitz. Subtracting half a sampling
    interval from every segment minimum bounds the continuous path below.
    """
    walls = [(x,y) for y,row in enumerate(level['tiles'])
             for x,tile in enumerate(row) if tile == 'wall']
    lower_bound = float('inf')
    for actor in (o for o in level['objects'] if o['type'] == 'skater'):
        for i,a in enumerate(actor['route']):
            b = actor['route'][(i+1) % len(actor['route'])]
            length = math.dist(a['pos'],b['pos'])
            samples = max(1,math.ceil(length/.025))
            observed = float('inf')
            for step in range(samples+1):
                point = [a['pos'][axis]+(b['pos'][axis]-a['pos'][axis])*step/samples
                         for axis in (0,1)]
                for x,y in walls:
                    observed = min(observed, math.hypot(
                        max(0,abs(point[0]-x)-.5),
                        max(0,abs(point[1]-y)-.5)))
            lower_bound = min(lower_bound,(observed-length/samples*.5)*1.8)
    assert lower_bound > .42, ('Rider clips a wall',lower_bound)
    return lower_bound

def boulevard():
    level = base(4, 'Banked Boulevard', 25, 23, (12, 21), (12, 1))
    level['hint'] = 'Cross the traffic. Choose the roach-free west or busy east gate, then cross behind the board.'
    level['description'] = ('A taxi avenue opens into a banked court. The rider returns through both '
                            'side gates; watch a complete circuit, choose either gate, and clear the '
                            'central bank on its quiet side.')
    level['design_purpose'] = 'Choose the roach-free west gate or busy east gate, both timed against the bank return.'
    level['required_gates'] = [dict(name='taxi avenue', rect=[1,15,23,16]),
                               dict(name='bank-side gates', rect=[1,10,23,10])]
    level['crossings'] = [6,12,18]
    lane(level, 16, 1, 3.3, 13.0, 1.0, ['taxi','sedan'])
    lane(level, 15, -1, 3.5, 14.0, 6.0, ['bus','taxi'])
    divider(level, 10, [6,7,17,18])
    rect(level, 2, 4, 4, 8, 'water')
    rect(level, 20, 4, 22, 8, 'water')
    # One actual mound, with quiet sidelines rather than a cosmetic ramp island.
    bank = banks(level, (12,8), length=4.0, rise=.7, rotation=270)
    skater(level, 1, 3.2,
           [node(7,8,trick='push')] + bank + [node(17,8), node(18,11,trick='push'),
            node(14,12), node(10,12), node(5.6,11)])
    # The two sides differ: west is a wide roach-free walk; east is shorter but
    # its newspaper corner has a local slow patrol.
    prop(level, 'newsstand', 19, 12, rotation=90)
    prop(level, 'trash_can', 21, 12)
    roach(level, (20,11), [(20,11),(22,11),(22,13),(20,13)], 1.25)
    prop(level, 'bench', 4, 12)
    prop(level, 'mailbox', 4, 2)
    prop(level, 'pizza_cart', 19, 20, rotation=180)
    prop(level, 'bench', 6, 20)
    prop(level, 'traffic_cone', 3, 18)
    prop(level, 'traffic_cone', 21, 18)
    prop(level, 'manhole', 12, 18, solid=False)
    prop(level, 'manhole', 12, 4, solid=False)
    assert_rider_wall_clearance(level)
    return level


def sanitation():
    level = base(5, 'Sanitation Courts', 25, 25, (12,23), (12,1))
    level['hint'] = 'Change alleys at each refuse court. Cross the grind line behind the returning board.'
    level['description'] = ('Three offset court gates make the frog weave from a refuse alley into a '
                            'delivery court and a north grind line. Slow roaches mark the direct routes; '
                            'benches and mailboxes identify wider waiting pockets.')
    level['design_purpose'] = 'Switch crossing lines through refuse courts, then time one rail return.'
    level['required_gates'] = [dict(name='south refuse gate', rect=[1,18,23,18]),
                               dict(name='delivery court gate', rect=[1,12,23,12]),
                               dict(name='north grind gate', rect=[1,6,23,6])]
    divider(level, 18, [5,6,7])
    divider(level, 12, [17,18,19])
    divider(level, 6, [6,7,8])
    # Separate service courts force different lateral journeys, with room to
    # stop and watch before each mandatory gate.
    rect(level, 10, 20, 14, 21, 'water')
    rect(level, 10, 14, 12, 15, 'water')
    rect(level, 18, 2, 21, 4, 'water')
    for x,y in [(4,20),(8,19),(15,16),(20,14)]:
        prop(level, 'dumpster', x,y)
    for x,y in [(4,19),(9,17),(21,13)]:
        prop(level,'trash_can',x,y)
    prop(level,'newsstand', 3,9, rotation=90)
    prop(level,'pizza_cart',21,9, rotation=270)
    prop(level,'bench',21,17,rotation=90)
    prop(level,'bench',14,4)
    prop(level,'mailbox',4,4)
    prop(level,'traffic_cone',15,19)
    prop(level,'manhole',14,16,solid=False)
    prop(level,'manhole',15,9,solid=False)
    roach(level,(6,20),[(6,20),(8,20),(8,22),(6,22)],1.15)
    roach(level,(13,16),[(13,16),(14,16),(14,17),(13,17)],1.35)
    roach(level,(18,10),[(18,10),(20,10),(20,11),(18,11)],1.20)
    roach(level,(8,4),[(8,4),(10,4),(10,5),(8,5)],1.30)
    line = rail_with_banks(level,(12,9),3.6,270)
    skater(level,2,3.5,[node(8,10,trick='push')] + line +
           [node(18,9),node(18,7,trick='push'),node(6,7),node(6,10),node(8,11)])
    return level


def block_party():
    level = base(6, 'Block Party', 25,25,(12,23),(12,1))
    level['hint'] = 'Cross the street, read the three skate loops, rest at the fountain, then cross home.'
    level['description'] = ('Traffic bookends a neighborhood block party. A narrow arrival gate puts '
                            'the first board crossing in view; a bank, two grind lines and a fountain '
                            'then offer distinct ways through before the final avenue.')
    level['design_purpose'] = 'Combine road timing, a mandatory rider arrival crossing and a route choice around a fountain.'
    level['required_gates'] = [dict(name='south avenue',rect=[1,19,23,20]),
                               dict(name='party arrival gate',rect=[1,18,23,18]),
                               dict(name='north avenue',rect=[1,5,23,6])]
    level['crossings'] = [6,12,18]
    lane(level,20,1,3.8,12.5,2.0,['taxi','sedan','truck'])
    lane(level,19,-1,3.2,14.0,7.0,['bus','taxi'])
    lane(level,6,1,4.4,12.0,4.0,['taxi','sedan'])
    lane(level,5,-1,3.6,14.0,1.0,['truck','bus','taxi'])
    divider(level,18,[12,13])
    divider(level,7,[11,12,13,14])
    # The center fountain makes a short east bank route and a longer west
    # grind-side route different spatial choices, with clear waiting pockets.
    rect(level,12,14,14,15,'water')
    rect(level,2,10,3,14,'water')
    rect(level,21,11,22,13,'water')
    west_line = rail_with_banks(level,(7,12),3.6,0)
    skater(level,0,3.3,[node(5,16,trick='push')] + west_line +
           [node(6,9),node(4,10),node(4,14),node(5,15)])
    center_bank = banks(level,(14,12),length=4.0,rise=.7,rotation=270)
    skater(level,1,3.2,[node(9,12,trick='push')] + center_bank +
           [node(18,12),node(18,16,trick='push'),node(10,16),node(9,14)])
    north_line = rail_with_banks(level,(13,9),3.6,270)
    skater(level,2,3.7,[node(8,9,trick='push')] + north_line +
           [node(20,10),node(20,15),node(17,17,trick='push'),node(12,17),
            node(10,15),node(9,11)])
    # All riders remain above the traffic, and the first mandatory board line
    # spans the arrival gate. Street stalls locate rest rather than hide hazards.
    prop(level,'pizza_cart',21,16,rotation=270)
    prop(level,'newsstand',3,8,rotation=90)
    prop(level,'dumpster',23,8)
    prop(level,'trash_can',22,9)
    prop(level,'bench',5,8)
    prop(level,'bench',15,3)
    prop(level,'mailbox',8,3)
    prop(level,'traffic_cone',10,22)
    prop(level,'traffic_cone',15,22)
    prop(level,'manhole',12,21,solid=False)
    prop(level,'manhole',17,13,solid=False)
    roach(level,(20,8),[(20,8),(22,8),(22,10),(20,10)],1.25)
    roach(level,(19,16),[(19,16),(20,16),(20,17),(19,17)],1.2)
    roach(level,(5,3),[(5,3),(7,3),(7,4),(5,4)],1.4)
    return level


def late_levels():
    return [(boulevard(),'streetlife_04_banked_boulevard'),
            (sanitation(),'streetlife_05_sanitation_courts'),
            (block_party(),'streetlife_06_block_party')]


if __name__ == '__main__':
    for level,slug in late_levels():
        planned = audit(level)
        save(level,slug)
        print(f"PASS {level['name']}: {len(planned)} static route steps")
