#!/usr/bin/env python3
"""Rebuild and audit the six authored NYC Streetlife maps; preserve all older maps."""
from streetlife_set_common import (base, rect, prop, roach, node, skater,
                                   rail_with_banks, banks, lane, audit, save)


def stoop_patrol():
    level=base(1,'Stoop Patrol',17,17,(3,15),(13,1))
    level.update(description='Two refuse-lined stoop gates introduce roach patrols. Observe from each open landing, cross behind the insect, and move laterally toward the opposite alley.',
                 hint='Watch the roach cross each alley. Follow behind it to the next landing.',
                 design_intent='Read a slow lateral patrol before committing to an offset alley gate.',
                 required_gates=[{'name':'south stoop alley','rect':[3,10,5,10]}, {'name':'north refuse alley','rect':[11,5,13,5]}])
    rect(level,1,10,15,10,'wall');rect(level,3,10,5,10,'path')
    rect(level,1,5,15,5,'wall');rect(level,11,5,13,5,'path')
    rect(level,3,11,5,14,'path');rect(level,5,7,12,8,'path');rect(level,11,2,13,6,'path')
    roach(level,(3,11),[(3,11),(5,11)],1.1)
    roach(level,(13,6),[(13,6),(11,6)],1.2)
    # Paired pieces frame the gates without reducing their three-cell width.
    prop(level,'dumpster',2,12);prop(level,'trash_can',6,12)
    prop(level,'mailbox',2,14);prop(level,'bench',8,8)
    prop(level,'newsstand',9,6);prop(level,'trash_can',14,7)
    prop(level,'pizza_cart',5,2);prop(level,'traffic_cone',10,3)
    prop(level,'manhole',9,12,solid=False)
    return level


def newsstand_weave():
    level=base(2,'Newsstand Weave',21,19,(10,17),(10,1))
    level.update(description='Enter the riding circuit around a newsstand island, choose the longer west walk or the shorter east line, then cross the outer board again to leave. The east line adds a second counter-flow rider.',
                 hint='Enter behind the outer rider. Go west for room, or east past the second loop.',
                 design_intent='A central island creates a real route choice inside one mandatory moving perimeter.',
                 required_gates=[{'name':'south circuit entry','rect':[8,15,12,15]}, {'name':'north circuit exit','rect':[8,3,12,3]}])
    rect(level,1,15,19,15,'wall');rect(level,8,15,12,15,'path')
    rect(level,1,3,19,3,'wall');rect(level,8,3,12,3,'path')
    rect(level,7,7,12,11,'wall')
    rect(level,8,13,12,14,'path');rect(level,5,5,6,12,'path')
    rect(level,13,5,14,13,'path');rect(level,8,4,12,5,'path')
    skater(level,0,2.5,[node(5,14,trick='push'),node(15,14),node(15,4,trick='push'),node(5,4)])
    skater(level,1,2.8,[node(17,6,trick='push'),node(17,12),node(13,12,trick='push'),node(13,6)])
    # The newsstand faces mark the island's two ends. The second rider occupies
    # the shorter east bypass; the wider west route is the deliberate low-risk choice.
    prop(level,'newsstand',10,6);prop(level,'newsstand',10,12,rotation=180)
    prop(level,'mailbox',7,16);prop(level,'pizza_cart',15,16)
    prop(level,'bench',3,9,rotation=90);prop(level,'traffic_cone',18,9)
    prop(level,'trash_can',8,16);prop(level,'trash_can',18,5)
    prop(level,'manhole',6,9,solid=False);prop(level,'manhole',14,9,solid=False)
    roach(level,(2,7),[(2,7),(3,7),(3,11),(2,11)],1.2)
    return level


def ferry_railwalk():
    level=base(3,'Ferry Railwalk',23,21,(3,18),(19,2))
    level.update(description='A river divides the ferry forecourt from the departure gate. The broad east pier carries a supported rail line. Walk around the bank ends, then time the returning rider rather than trying to climb its fixtures.',
                 hint='Use the east pier. Walk around bank ends and cross after the rail rider passes.',
                 design_intent='A water-separated pier turns matching rail supports into a route obstacle and a timing landmark.',
                 required_gates=[{'name':'east ferry pier','rect':[14,10,19,10]}])
    rect(level,1,8,21,12,'water');rect(level,14,7,19,13,'path')
    # A ferry terminal forecourt has one clear way across the water; rail and
    # ramps occupy its middle so the frog chooses an end instead of climbing.
    rail=rail_with_banks(level,(16.5,10),3.6,270)
    skater(level,2,3.0,rail+[node(19,7,trick='push'),node(14,7),node(14,13,trick='push'),node(14.5,13)])
    prop(level,'bench',7,17);prop(level,'pizza_cart',9,17)
    prop(level,'trash_can',5,15);prop(level,'dumpster',3,14)
    prop(level,'mailbox',18,16);prop(level,'newsstand',20,4,rotation=270)
    prop(level,'traffic_cone',13,6);prop(level,'manhole',17,6,solid=False)
    roach(level,(6,16),[(6,16),(6,14),(8,14),(8,16)],1.25)
    roach(level,(20,16),[(20,16),(20,18),(18,18),(18,16)],1.2)
    return level


def early_levels():
    return [(stoop_patrol(),'streetlife_01_stoop_patrol'),
            (newsstand_weave(),'streetlife_02_newsstand_weave'),
            (ferry_railwalk(),'streetlife_03_ferry_railwalk')]


def main():
    from streetlife_set_late import late_levels
    levels=early_levels()+late_levels()
    assert len(levels)==6 and [level['set_index'] for level,_ in levels]==list(range(1,7))
    for level,slug in levels:
        planned=audit(level)
        save(level,slug)
        print(f"PASS {level['name']}: {level['width']}x{level['height']}, {len(planned)} clearance route steps, "
              f"{sum(o['type']=='roach' for o in level['objects'])} roaches, {sum(o['type']=='skater' for o in level['objects'])} riders, {len(level['traffic'])} traffic lanes")

if __name__=='__main__':main()
