# NYC street dressing and roaches

The five established NYC maps now include 39 additional street props. The new
skate plaza is authored separately and does not share this generator's files.

| Prop | Placements | Placement purpose |
| --- | ---: | --- |
| Bench | 8 | Park paths, waterfront overlooks and broad arrival sidewalks |
| Pizza cart | 4 | Park entrance, pier entrance, Broadway and Midtown arrivals |
| Trash can | 5 | Beside vending or arrival areas |
| Mailbox | 5 | A recognizable curbside detail in each district |
| Manhole | 5 | Flush, nonblocking sidewalk service covers |
| Traffic cone | 5 | Nonblocking pavement markers beside avenues |
| Dumpster | 4 | Brownstone, waterfront, theater and Midtown service corners |
| Newsstand | 3 | Brownstone storefront, Broadway and Midtown street corners |

Furniture occupies dry sidewalk cells and avoids the frog start, exit, existing
objects and the original shortest grid route. Benches, carts, bins, mailboxes,
dumpsters and newsstands use their modeled collision footprints. Cones and flush
manholes are authored as nonblocking dressing. None is placed on a traffic lane.

The three existing patrol critters in Central Park, Brownstone Blocks and East
River Piers become roaches. Their original IDs, positions, patrol points and
speeds remain unchanged. Broadway and Midtown keep their existing enemy counts;
the new dressing does not add another moving threat to their traffic encounters.
The skate plaza supplies its own separate roach population.

`python3 tools/create_nyc_maps.py` regenerates these five maps. Its audit checks
supported variants, dry placement, unique IDs, object count, roach waypoints,
traffic clearances, individual mandatory lanes and route connectivity. The
street-dressing helper also requires that the original selected grid route
remain exactly unchanged after all new solid objects are placed.

Static checks passed for all five maps. Their chosen routes remain 20, 30, 34,
30 and 46 grid steps. Repeating generation produced identical five JSON hashes,
and the original three non-NYC map hashes stayed unchanged. These checks do not
replace runtime collision, live enemy playthroughs or visual inspection; those
belong to the combined integration and asset-review passes.
